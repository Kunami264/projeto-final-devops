import os

from fastapi import Depends, FastAPI, HTTPException
from pydantic import BaseModel
from opentelemetry import trace
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from prometheus_fastapi_instrumentator import Instrumentator

from app.logging_setup import configure_logging
from app.security import TokenClaims, require_scope

SERVICE_NAME = "service-users"
OTLP_ENDPOINT = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "jaeger:4317")
ENABLE_TRACING = os.getenv("ENABLE_TRACING", "false").lower() == "true"

logger = configure_logging(SERVICE_NAME)

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
    title="service-users",
    description="Microsserviço de gestão de utilizadores",
    version="1.2.0",
)
FastAPIInstrumentor.instrument_app(app)


Instrumentator().instrument(app).expose(app, endpoint="/metrics", include_in_schema=False)


class User(BaseModel):
    id: int
    name: str
    email: str


USERS_DB: dict[int, User] = {
    1: User(id=1, name="Daniel Silva", email="daniel.silva@example.com"),
    2: User(id=2, name="Ana Costa", email="ana.costa@example.com"),
    3: User(id=3, name="Miguel Santos", email="miguel.santos@example.com"),
}


@app.get("/health", tags=["infra"])
def health() -> dict:
    """Usado pelos smoke tests em PRD e pelos healthchecks do Docker/K8s."""
    return {"status": "ok", "service": SERVICE_NAME}


@app.get("/users", response_model=list[User], tags=["users"])
def list_users(claims: TokenClaims = Depends(require_scope("users:read"))) -> list[User]:
    logger.info("Listagem de utilizadores pedida por '%s'", claims.subject)
    return list(USERS_DB.values())


@app.get("/users/{user_id}", response_model=User, tags=["users"])
def get_user(
    user_id: int, claims: TokenClaims = Depends(require_scope("users:read"))
) -> User:
    user = USERS_DB.get(user_id)
    if not user:
        logger.info("Utilizador %d não encontrado (pedido por '%s')", user_id, claims.subject)
        raise HTTPException(status_code=404, detail="Utilizador não encontrado")
    return user


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8002)
