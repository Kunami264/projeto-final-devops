import os
import time

os.environ.setdefault("OIDC_ISSUER", "http://keycloak-test/realms/test")
os.environ.setdefault("ENABLE_TRACING", "false")

import jwt
import pytest
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import serialization

OIDC_ISSUER = os.environ["OIDC_ISSUER"]


_private_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
_public_key = _private_key.public_key()

_private_pem = _private_key.private_bytes(
    encoding=serialization.Encoding.PEM,
    format=serialization.PrivateFormat.PKCS8,
    encryption_algorithm=serialization.NoEncryption(),
)
_public_pem = _public_key.public_bytes(
    encoding=serialization.Encoding.PEM,
    format=serialization.PublicFormat.SubjectPublicKeyInfo,
)


def _make_token(scope: str, subject: str = "test-suite", expires_in: int = 300, azp: str = "api-cli") -> str:
    payload = {
        "sub": subject,
        "scope": scope,
        "iss": OIDC_ISSUER,
        "azp": azp,
        "iat": int(time.time()),
        "exp": int(time.time()) + expires_in,
    }
    return jwt.encode(payload, _private_pem, algorithm="RS256")


@pytest.fixture(autouse=True)
def _bypass_jwks(monkeypatch):
    """Substitui a ida real ao JWKS do Keycloak pela chave pública de
    teste gerada acima — aplica-se a todos os testes deste módulo."""
    from app import security

    monkeypatch.setattr(security, "_get_signing_key", lambda token: _public_pem)


@pytest.fixture
def auth_headers():
    """Bearer token válido com o scope 'users:read'."""
    return {"Authorization": f"Bearer {_make_token('users:read')}"}


@pytest.fixture
def wrong_scope_headers():
    """Bearer token válido mas sem o scope necessário."""
    return {"Authorization": f"Bearer {_make_token('orders:read')}"}


@pytest.fixture
def expired_token_headers():
    """Bearer token expirado."""
    return {"Authorization": f"Bearer {_make_token('users:read', expires_in=-10)}"}
