import os
import time

os.environ.setdefault("DATABASE_URL", "sqlite:///./test_users_unit.db")
os.environ.setdefault("AUTH_JWT_SECRET", "segredo-de-testes-unitarios-com-32-ou-mais-caracteres")
os.environ.setdefault("AUTH_ADMIN_PASSWORD", "password-de-testes")
os.environ.setdefault("ENABLE_TRACING", "false")

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
def auth_headers():
    return {"Authorization": f"Bearer {_make_token('users:read')}"}


@pytest.fixture
def write_headers():
    return {"Authorization": f"Bearer {_make_token('users:write')}"}


@pytest.fixture
def wrong_scope_headers():
    return {"Authorization": f"Bearer {_make_token('orders:read')}"}


@pytest.fixture
def expired_token_headers():
    return {"Authorization": f"Bearer {_make_token('users:read', expires_in=-10)}"}


@pytest.fixture(autouse=True)
def reset_database():
    from app.db import Base, engine
    from app.main import seed_users

    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    seed_users()
