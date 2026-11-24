import os
import time

os.environ.setdefault("DATABASE_URL", "sqlite:///./test_orders_unit.db")
os.environ.setdefault("ENABLE_TRACING", "false")
os.environ.setdefault("AUTH_JWT_SECRET", "segredo-de-testes-unitarios-com-32-ou-mais-caracteres")
os.environ.setdefault("AUTH_ADMIN_PASSWORD", "password-de-testes")


import jwt
import pytest

SECRET = os.environ["AUTH_JWT_SECRET"]


def _make_token(scope: str, subject: str = "test-suite", expires_in: int = 300,
                secret: str = SECRET, issuer: str = "projeto-final") -> str:
    payload = {
        "sub": subject,
        "scope": scope,
        "iss": issuer,
        "iat": int(time.time()),
        "exp": int(time.time()) + expires_in,
    }
    return jwt.encode(payload, secret, algorithm="HS256")


@pytest.fixture
def make_token():
    return _make_token


@pytest.fixture
def read_headers():
    return {"Authorization": f"Bearer {_make_token('orders:read')}"}


@pytest.fixture
def write_headers():
    return {"Authorization": f"Bearer {_make_token('orders:write')}"}


@pytest.fixture
def wrong_scope_headers():
    return {"Authorization": f"Bearer {_make_token('users:read')}"}


@pytest.fixture(autouse=True)
def reset_database():
    from app.db import Base, engine

    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
