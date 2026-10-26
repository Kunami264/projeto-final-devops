import os
import time

import httpx
from fastapi import Depends, FastAPI, HTTPException, Response
from pydantic import BaseModel, Field
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session
from prometheus_fastapi_instrumentator import Instrumentator

from app.db import Base, engine, get_db
from app.logging_setup import configure_logging
from app.models import OrderModel
from app.oidc_client import ClientCredentialsTokenProvider
from app.security import TokenClaims, require_scope

SERVICE_NAME = "service-orders"
OTLP_ENDPOINT = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "jaeger:4317")
ENABLE_TRACING = os.getenv("ENABLE_TRACING", "false").lower() == "true"
USERS_SERVICE_URL = os.getenv("USERS_SERVICE_URL", "http://service-users:8002")
HTTP_CLIENT_TIMEOUT = float(os.getenv("USERS_SERVICE_TIMEOUT", "5.0"))
HTTP_CLIENT_RETRIES = int(os.getenv("USERS_SERVICE_RETRIES", "2"))
HTTP_CLIENT_BACKOFF_SECONDS = float(os.getenv("USERS_SERVICE_RETRY_BACKOFF", "0.3"))


OIDC_ISSUER = os.getenv("OIDC_ISSUER")
OIDC_TOKEN_URL = os.getenv("OIDC_TOKEN_URL") or (
    f"{OIDC_ISSUER.rstrip('/')}/protocol/openid-connect/token" if OIDC_ISSUER else None
)
OIDC_CLIENT_ID = os.getenv("OIDC_CLIENT_ID", "service-orders-local")
OIDC_CLIENT_SECRET = os.getenv("OIDC_CLIENT_SECRET", "")

logger = configure_logging(SERVICE_NAME)

if not OIDC_TOKEN_URL or not OIDC_CLIENT_SECRET:
    logger.warning(
        "OIDC_TOKEN_URL/OIDC_CLIENT_SECRET incompletos — as chamadas a service-users "
        "vão falhar (sem token M2M). Ver o client 'service-orders' em k8s/auth/realm-export.json."
    )
    _token_provider: ClientCredentialsTokenProvider | None = None
else:
    _token_provider = ClientCredentialsTokenProvider(
        token_url=OIDC_TOKEN_URL,
        client_id=OIDC_CLIENT_ID,
        client_secret=OIDC_CLIENT_SECRET,
    )

# OpenTelemetry só em DEV (ENABLE_TRACING=true). As bibliotecas estão em requirements-tracing.txt,
# que não entra na imagem de STG/PRD — por isso só são importadas aqui.
if ENABLE_TRACING:
    from opentelemetry import trace
    from opentelemetry.sdk.resources import Resource
    from opentelemetry.sdk.trace import TracerProvider
    from opentelemetry.sdk.trace.export import BatchSpanProcessor
    from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
    from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
    from opentelemetry.instrumentation.httpx import HTTPXClientInstrumentor

    provider = TracerProvider(resource=Resource.create({"service.name": SERVICE_NAME}))
    try:
        provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter(endpoint=OTLP_ENDPOINT, insecure=True)))
    except Exception as exc:
        logger.warning("Não foi possível configurar o exporter OTLP: %s", exc)
    trace.set_tracer_provider(provider)

app = FastAPI(
    title="service-orders",
    description="Microsserviço de gestão de encomendas",
    version="1.4.0",
)
if ENABLE_TRACING:
    FastAPIInstrumentor.instrument_app(app)
    HTTPXClientInstrumentor().instrument()


Instrumentator().instrument(app).expose(app, endpoint="/metrics", include_in_schema=False)


try:
    Base.metadata.create_all(bind=engine)
except SQLAlchemyError as exc:
    logger.warning("Inicialização da base de dados já feita por outra réplica: %s", exc)


class OrderCreate(BaseModel):
    user_id: int
    item: str = Field(min_length=1, max_length=200)
    quantity: int = Field(gt=0, description="Tem de ser um inteiro positivo")


class OrderUpdate(BaseModel):
    item: str = Field(min_length=1, max_length=200)
    quantity: int = Field(gt=0, description="Tem de ser um inteiro positivo")


SCOPE_READ = "orders:read"
SCOPE_WRITE = "orders:write"
ORDER_NOT_FOUND = "Encomenda não encontrada"

# Respostas de erro documentadas na especificação OpenAPI (/docs)
RESPONSES_NOT_FOUND = {404: {"description": ORDER_NOT_FOUND}}
RESPONSES_CREATE = {
    404: {"description": "Utilizador não encontrado em service-users"},
    502: {"description": "Falha de autenticação interna com service-users"},
    503: {"description": "service-users ou Authorization Server (Keycloak) indisponível"},
}


class AuthServerUnavailable(Exception):
    """O Keycloak não emitiu o token M2M para chamar o service-users."""


def _fetch_user_with_retry(user_id: int) -> dict:
    last_error: httpx.RequestError | None = None
    if _token_provider is not None:
        try:
            headers = {"Authorization": f"Bearer {_token_provider.get_token()}"}
        except (httpx.HTTPStatusError, httpx.RequestError) as exc:
            raise AuthServerUnavailable() from exc
    else:
        headers = {}

    for attempt in range(HTTP_CLIENT_RETRIES + 1):
        try:
            with httpx.Client(timeout=HTTP_CLIENT_TIMEOUT) as client:
                resp = client.get(f"{USERS_SERVICE_URL}/users/{user_id}", headers=headers)
                resp.raise_for_status()
                return resp.json()
        except httpx.HTTPStatusError:
            raise
        except httpx.RequestError as exc:
            last_error = exc
            if attempt < HTTP_CLIENT_RETRIES:
                wait = HTTP_CLIENT_BACKOFF_SECONDS * (2**attempt)
                logger.warning(
                    "Falha de rede a contactar service-users (tentativa %d/%d): %s — nova tentativa em %.1fs",
                    attempt + 1,
                    HTTP_CLIENT_RETRIES + 1,
                    exc,
                    wait,
                )
                time.sleep(wait)

    raise last_error


@app.get("/health", tags=["infra"])
def health() -> dict:
    return {"status": "ok", "service": SERVICE_NAME}


@app.post("/orders", tags=["orders"], responses=RESPONSES_CREATE)
def create_order(
    order: OrderCreate,
    db: Session = Depends(get_db),
    claims: TokenClaims = Depends(require_scope(SCOPE_WRITE)),
) -> dict:
    try:
        user_data = _fetch_user_with_retry(order.user_id)
    except AuthServerUnavailable as exc:
        raise HTTPException(status_code=503, detail="Authorization Server (Keycloak) indisponível") from exc
    except httpx.HTTPStatusError as exc:
        if exc.response is not None and exc.response.status_code == 401:
            logger.error("service-users rejeitou o token M2M (401) — verificar client secret / client scopes no Keycloak")
            raise HTTPException(status_code=502, detail="Falha de autenticação interna com service-users") from exc
        raise HTTPException(status_code=404, detail="Utilizador não encontrado em service-users") from exc
    except httpx.RequestError as exc:
        logger.exception("service-users indisponível após novas tentativas")
        raise HTTPException(status_code=503, detail="service-users indisponível") from exc

    new_order = OrderModel(item=order.item, quantity=order.quantity, user=user_data)
    db.add(new_order)
    db.commit()
    db.refresh(new_order)
    logger.info("Encomenda %d criada por '%s' para o utilizador %d", new_order.id, claims.subject, order.user_id)
    return new_order.to_dict()


@app.get("/orders/{order_id}", tags=["orders"], responses=RESPONSES_NOT_FOUND)
def get_order(
    order_id: int,
    db: Session = Depends(get_db),
    claims: TokenClaims = Depends(require_scope(SCOPE_READ)),
) -> dict:
    order = db.get(OrderModel, order_id)
    if not order:
        raise HTTPException(status_code=404, detail=ORDER_NOT_FOUND)
    return order.to_dict()


@app.put("/orders/{order_id}", tags=["orders"], responses=RESPONSES_NOT_FOUND)
def update_order(
    order_id: int,
    data: OrderUpdate,
    db: Session = Depends(get_db),
    claims: TokenClaims = Depends(require_scope(SCOPE_WRITE)),
) -> dict:
    order = db.get(OrderModel, order_id)
    if not order:
        raise HTTPException(status_code=404, detail=ORDER_NOT_FOUND)
    order.item = data.item
    order.quantity = data.quantity
    db.commit()
    db.refresh(order)
    logger.info("Encomenda %d editada por '%s'", order_id, claims.subject)
    return order.to_dict()


@app.delete("/orders/{order_id}", status_code=204, tags=["orders"], responses=RESPONSES_NOT_FOUND)
def delete_order(
    order_id: int,
    db: Session = Depends(get_db),
    claims: TokenClaims = Depends(require_scope(SCOPE_WRITE)),
) -> Response:
    order = db.get(OrderModel, order_id)
    if not order:
        raise HTTPException(status_code=404, detail=ORDER_NOT_FOUND)
    db.delete(order)
    db.commit()
    logger.info("Encomenda %d apagada por '%s'", order_id, claims.subject)
    return Response(status_code=204)


@app.get("/orders", tags=["orders"])
def list_orders(
    db: Session = Depends(get_db),
    claims: TokenClaims = Depends(require_scope(SCOPE_READ)),
) -> list:
    return [o.to_dict() for o in db.query(OrderModel).order_by(OrderModel.id).all()]

