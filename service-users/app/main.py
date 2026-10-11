import os

from fastapi import Depends, FastAPI, HTTPException, Response
from pydantic import BaseModel, Field
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from sqlalchemy.orm import Session
from opentelemetry import trace
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from prometheus_fastapi_instrumentator import Instrumentator

from app.db import Base, SessionLocal, engine, get_db
from app.logging_setup import configure_logging
from app.models import UserModel
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
    version="1.3.0",
)
FastAPIInstrumentor.instrument_app(app)


Instrumentator().instrument(app).expose(app, endpoint="/metrics", include_in_schema=False)


class User(BaseModel):
    id: int
    name: str
    email: str


class UserCreate(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    email: str = Field(pattern=r"^[^@\s]+@[^@\s]+\.[^@\s]+$", max_length=254)


SEED_USERS = [
    {"name": "Daniel Silva", "email": "daniel.silva@example.com"},
    {"name": "Ana Costa", "email": "ana.costa@example.com"},
    {"name": "Miguel Santos", "email": "miguel.santos@example.com"},
]


def seed_users() -> None:
    """Carrega os utilizadores de demonstração se a tabela estiver vazia."""
    with SessionLocal() as db:
        if db.query(UserModel).first() is not None:
            return
        db.add_all(UserModel(**u) for u in SEED_USERS)
        db.commit()


# Com várias réplicas a arrancar em simultâneo, só uma consegue criar a tabela /
# inserir os dados iniciais — as restantes encontram-nos já feitos.
try:
    Base.metadata.create_all(bind=engine)
    seed_users()
except SQLAlchemyError as exc:
    logger.warning("Inicialização da base de dados já feita por outra réplica: %s", exc)


@app.get("/health", tags=["infra"])
def health() -> dict:
    """Usado pelos healthchecks do Docker/K8s."""
    return {"status": "ok", "service": SERVICE_NAME}


@app.get("/users", response_model=list[User], tags=["users"])
def list_users(
    db: Session = Depends(get_db),
    claims: TokenClaims = Depends(require_scope("users:read")),
) -> list[dict]:
    logger.info("Listagem de utilizadores pedida por '%s'", claims.subject)
    return [u.to_dict() for u in db.query(UserModel).order_by(UserModel.id).all()]


@app.post("/users", response_model=User, status_code=201, tags=["users"])
def create_user(
    user: UserCreate,
    db: Session = Depends(get_db),
    claims: TokenClaims = Depends(require_scope("users:write")),
) -> dict:
    new_user = UserModel(name=user.name, email=user.email)
    db.add(new_user)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="Já existe um utilizador com este email")
    db.refresh(new_user)
    logger.info("Utilizador %d criado por '%s'", new_user.id, claims.subject)
    return new_user.to_dict()


@app.get("/users/{user_id}", response_model=User, tags=["users"])
def get_user(
    user_id: int,
    db: Session = Depends(get_db),
    claims: TokenClaims = Depends(require_scope("users:read")),
) -> dict:
    user = db.get(UserModel, user_id)
    if not user:
        logger.info("Utilizador %d não encontrado (pedido por '%s')", user_id, claims.subject)
        raise HTTPException(status_code=404, detail="Utilizador não encontrado")
    return user.to_dict()


@app.put("/users/{user_id}", response_model=User, tags=["users"])
def update_user(
    user_id: int,
    data: UserCreate,
    db: Session = Depends(get_db),
    claims: TokenClaims = Depends(require_scope("users:write")),
) -> dict:
    user = db.get(UserModel, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Utilizador não encontrado")
    user.name = data.name
    user.email = data.email
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="Já existe um utilizador com este email")
    db.refresh(user)
    logger.info("Utilizador %d editado por '%s'", user_id, claims.subject)
    return user.to_dict()


@app.delete("/users/{user_id}", status_code=204, tags=["users"])
def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    claims: TokenClaims = Depends(require_scope("users:write")),
) -> Response:
    user = db.get(UserModel, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Utilizador não encontrado")
    db.delete(user)
    db.commit()
    logger.info("Utilizador %d apagado por '%s'", user_id, claims.subject)
    return Response(status_code=204)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8002)
