import os

from fastapi import Depends, FastAPI, HTTPException, Response
from pydantic import BaseModel, Field
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from sqlalchemy.orm import Session
from prometheus_fastapi_instrumentator import Instrumentator

from app.db import Base, SessionLocal, engine, get_db
from app.logging_setup import configure_logging
from app.models import UserModel
from app.security import TokenClaims, require_scope

SERVICE_NAME = "service-users"
OTLP_ENDPOINT = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "jaeger:4317")
ENABLE_TRACING = os.getenv("ENABLE_TRACING", "false").lower() == "true"

logger = configure_logging(SERVICE_NAME)

# OpenTelemetry só em DEV (ENABLE_TRACING=true). As bibliotecas estão em requirements-tracing.txt,
# que não entra na imagem de STG/PRD — por isso só são importadas aqui.
if ENABLE_TRACING:
    from opentelemetry import trace
    from opentelemetry.sdk.resources import Resource
    from opentelemetry.sdk.trace import TracerProvider
    from opentelemetry.sdk.trace.export import BatchSpanProcessor
    from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
    from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

    provider = TracerProvider(resource=Resource.create({"service.name": SERVICE_NAME}))
    try:
        provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter(endpoint=OTLP_ENDPOINT, insecure=True)))
    except Exception as exc:
        logger.warning("Não foi possível configurar o exporter OTLP: %s", exc)
    trace.set_tracer_provider(provider)

app = FastAPI(
    title="service-users",
    description="Microsserviço de gestão de utilizadores",
    version="1.3.0",
)
if ENABLE_TRACING:
    FastAPIInstrumentor.instrument_app(app)


Instrumentator().instrument(app).expose(app, endpoint="/metrics", include_in_schema=False)


class User(BaseModel):
    id: int
    name: str
    email: str


class UserCreate(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    email: str = Field(pattern=r"^[^@\s]+@[^@\s]+\.[^@\s]+$", max_length=254)


SCOPE_READ = "users:read"
SCOPE_WRITE = "users:write"
USER_NOT_FOUND = "Utilizador não encontrado"
EMAIL_CONFLICT = "Já existe um utilizador com este email"

# Respostas de erro documentadas na especificação OpenAPI (/docs)
RESPONSES_NOT_FOUND = {404: {"description": USER_NOT_FOUND}}
RESPONSES_CONFLICT = {409: {"description": EMAIL_CONFLICT}}
RESPONSES_UPDATE = {404: {"description": USER_NOT_FOUND}, 409: {"description": EMAIL_CONFLICT}}

SEED_USERS = [
    {"name": "Daniel Silva", "email": "daniel.silva@example.com"},
    {"name": "Ana Costa", "email": "ana.costa@example.com"},
    {"name": "Miguel Santos", "email": "miguel.santos@example.com"},
]


def seed_users() -> None:
    with SessionLocal() as db:
        if db.query(UserModel).first() is not None:
            return
        db.add_all(UserModel(**u) for u in SEED_USERS)
        db.commit()



try:
    Base.metadata.create_all(bind=engine)
    seed_users()
except SQLAlchemyError as exc:
    logger.warning("Inicialização da base de dados já feita por outra réplica: %s", exc)


@app.get("/health", tags=["infra"])
def health() -> dict:
    return {"status": "ok", "service": SERVICE_NAME}


@app.get("/users", response_model=list[User], tags=["users"])
def list_users(
    db: Session = Depends(get_db),
    claims: TokenClaims = Depends(require_scope(SCOPE_READ)),
) -> list[dict]:
    logger.info("Listagem de utilizadores pedida por '%s'", claims.subject)
    return [u.to_dict() for u in db.query(UserModel).order_by(UserModel.id).all()]


@app.post("/users", response_model=User, status_code=201, tags=["users"], responses=RESPONSES_CONFLICT)
def create_user(
    user: UserCreate,
    db: Session = Depends(get_db),
    claims: TokenClaims = Depends(require_scope(SCOPE_WRITE)),
) -> dict:
    new_user = UserModel(name=user.name, email=user.email)
    db.add(new_user)
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=409, detail=EMAIL_CONFLICT) from exc
    db.refresh(new_user)
    logger.info("Utilizador %d criado por '%s'", new_user.id, claims.subject)
    return new_user.to_dict()


@app.get("/users/{user_id}", response_model=User, tags=["users"], responses=RESPONSES_NOT_FOUND)
def get_user(
    user_id: int,
    db: Session = Depends(get_db),
    claims: TokenClaims = Depends(require_scope(SCOPE_READ)),
) -> dict:
    user = db.get(UserModel, user_id)
    if not user:
        logger.info("Utilizador %d não encontrado (pedido por '%s')", user_id, claims.subject)
        raise HTTPException(status_code=404, detail=USER_NOT_FOUND)
    return user.to_dict()


@app.put("/users/{user_id}", response_model=User, tags=["users"], responses=RESPONSES_UPDATE)
def update_user(
    user_id: int,
    data: UserCreate,
    db: Session = Depends(get_db),
    claims: TokenClaims = Depends(require_scope(SCOPE_WRITE)),
) -> dict:
    user = db.get(UserModel, user_id)
    if not user:
        raise HTTPException(status_code=404, detail=USER_NOT_FOUND)
    user.name = data.name
    user.email = data.email
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=409, detail=EMAIL_CONFLICT) from exc
    db.refresh(user)
    logger.info("Utilizador %d editado por '%s'", user_id, claims.subject)
    return user.to_dict()


@app.delete("/users/{user_id}", status_code=204, tags=["users"], responses=RESPONSES_NOT_FOUND)
def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    claims: TokenClaims = Depends(require_scope(SCOPE_WRITE)),
) -> Response:
    user = db.get(UserModel, user_id)
    if not user:
        raise HTTPException(status_code=404, detail=USER_NOT_FOUND)
    db.delete(user)
    db.commit()
    logger.info("Utilizador %d apagado por '%s'", user_id, claims.subject)
    return Response(status_code=204)

