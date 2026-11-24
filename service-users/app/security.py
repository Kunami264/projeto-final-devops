"""Autenticação por JWT assinado (HS256), sem servidor de identidade externo.

O service-users emite os tokens em POST /auth/token; as duas APIs validam-nos com o mesmo
segredo (AUTH_JWT_SECRET, guardado num Secret do Kubernetes ou no docker-compose.yml).
Cada endpoint exige um scope (users:read, users:write, orders:read, orders:write).
"""
import logging
import os
import time

import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

logger = logging.getLogger("service-users.security")

ALGORITHM = "HS256"
ISSUER = os.getenv("AUTH_ISSUER", "projeto-final")
SECRET = os.getenv("AUTH_JWT_SECRET", "")

if len(SECRET) < 32:
    raise RuntimeError(
        "AUTH_JWT_SECRET em falta ou com menos de 32 caracteres — obrigatório para assinar e "
        "validar os tokens. Ver docker-compose.yml (DEV) ou helm/values*.yaml (STG/PRD)."
    )

_bearer_scheme = HTTPBearer(auto_error=False)


class TokenClaims:
    __slots__ = ("subject", "scopes")

    def __init__(self, subject: str, scopes: set[str]):
        self.subject = subject
        self.scopes = scopes


def issue_token(subject: str, scopes: list[str], ttl_seconds: int) -> str:
    now = int(time.time())
    payload = {
        "sub": subject,
        "scope": " ".join(scopes),
        "iss": ISSUER,
        "iat": now,
        "exp": now + ttl_seconds,
    }
    return jwt.encode(payload, SECRET, algorithm=ALGORITHM)


def _unauthorized(detail: str) -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail=detail,
        headers={"WWW-Authenticate": "Bearer"},
    )


def _decode_token(token: str) -> TokenClaims:
    try:
        payload = jwt.decode(
            token,
            SECRET,
            algorithms=[ALGORITHM],
            issuer=ISSUER,
            options={"require": ["exp", "sub", "scope", "iss"]},
        )
    except jwt.ExpiredSignatureError as exc:
        raise _unauthorized("Token expirado") from exc
    except jwt.InvalidTokenError as exc:
        logger.warning("Token JWT rejeitado: %s", exc)
        raise _unauthorized("Token inválido") from exc

    return TokenClaims(subject=payload["sub"], scopes=set(payload["scope"].split()))


def require_scope(*required: str):
    required_scopes = set(required)

    def _dependency(
        credentials: HTTPAuthorizationCredentials | None = Depends(_bearer_scheme),
    ) -> TokenClaims:
        if credentials is None:
            raise _unauthorized("Autenticação necessária (Bearer token em falta)")

        claims = _decode_token(credentials.credentials)

        if not (claims.scopes & required_scopes):
            logger.warning(
                "Acesso negado a '%s': scopes %s insuficientes (requer um de %s)",
                claims.subject,
                sorted(claims.scopes),
                sorted(required_scopes),
            )
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Permissões insuficientes para este endpoint",
            )

        return claims

    return _dependency
