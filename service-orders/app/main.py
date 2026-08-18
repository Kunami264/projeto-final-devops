import os
import time

import httpx
from fastapi import Depends, FastAPI, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from opentelemetry import trace
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.httpx import HTTPXClientInstrumentor
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

resource = Resource.create({"service.name": SERVICE_NAME})
provider = TracerProvider(resource=resource)

if ENABLE_TRACING:
    try:
        otlp_exporter = OTLPSpanExporter(endpoint=OTLP_ENDPOINT, insecure=True)
        provider.add_span_processor(BatchSpanProcessor(otlp_exporter))
    except Exception as exc:
        logger.warning("Não foi possível configurar o exporter OTLP: %s", exc)

trace.set_tracer_provider(provider)

app = FastAPI(
    title="service-orders",
    description="Microsserviço de gestão de encomendas",
    version="1.3.0",
)
FastAPIInstrumentor.instrument_app(app)
HTTPXClientInstrumentor().instrument()


Instrumentator().instrument(app).expose(app, endpoint="/metrics", include_in_schema=False)


Base.metadata.create_all(bind=engine)


class OrderCreate(BaseModel):
    user_id: int
    item: str
    quantity: int = Field(gt=0, description="Tem de ser um inteiro positivo")


def _fetch_user_with_retry(user_id: int) -> dict:
    last_error: httpx.RequestError | None = None
    if _token_provider is not None:
        try:
            headers = {"Authorization": f"Bearer {_token_provider.get_token()}"}
        except (httpx.HTTPStatusError, httpx.RequestError):


            raise HTTPException(status_code=503, detail="Authorization Server (Keycloak) indisponível")
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


@app.post("/orders", tags=["orders"])
def create_order(
    order: OrderCreate,
    db: Session = Depends(get_db),
    claims: TokenClaims = Depends(require_scope("orders:write")),
) -> dict:
    try:
        user_data = _fetch_user_with_retry(order.user_id)
    except httpx.HTTPStatusError as exc:
        if exc.response is not None and exc.response.status_code == 401:
            logger.error("service-users rejeitou o token M2M (401) — verificar client secret / client scopes no Keycloak")
            raise HTTPException(status_code=502, detail="Falha de autenticação interna com service-users")
        raise HTTPException(status_code=404, detail="Utilizador não encontrado em service-users")
    except httpx.RequestError as exc:
        logger.error("service-users indisponível após novas tentativas: %s", exc)
        raise HTTPException(status_code=503, detail="service-users indisponível")

    new_order = OrderModel(item=order.item, quantity=order.quantity, user=user_data)
    db.add(new_order)
    db.commit()
    db.refresh(new_order)
    logger.info("Encomenda %d criada por '%s' para o utilizador %d", new_order.id, claims.subject, order.user_id)
    return new_order.to_dict()


@app.get("/orders/{order_id}", tags=["orders"])
def get_order(
    order_id: int,
    db: Session = Depends(get_db),
    claims: TokenClaims = Depends(require_scope("orders:read")),
) -> dict:
    order = db.get(OrderModel, order_id)
    if not order:
        raise HTTPException(status_code=404, detail="Encomenda não encontrada")
    return order.to_dict()


@app.get("/orders", tags=["orders"])
def list_orders(
    db: Session = Depends(get_db),
    claims: TokenClaims = Depends(require_scope("orders:read")),
) -> list:
    return [o.to_dict() for o in db.query(OrderModel).order_by(OrderModel.id).all()]


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8001)
