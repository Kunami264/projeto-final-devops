"""
Autenticação e autorização da API — Bearer JWT (RS256) validado contra o
Authorization Server (Keycloak), via JWKS.

Ao contrário da iteração anterior (HS256 com segredo partilhado), este
serviço já não conhece nenhum segredo capaz de assinar tokens — só
verifica assinaturas com a chave pública do Keycloak, obtida em runtime
no endpoint JWKS do realm (`{issuer}/protocol/openid-connect/certs`) e
mantida em cache (`PyJWKClient`, TTL default da biblioteca). A
autorização mantém-se por *scope* OAuth2 (claim `scope`, string
separada por espaços) — Keycloak popula este claim automaticamente a
partir dos Client Scopes atribuídos por omissão a cada client no realm
`projeto-final` (ver k8s/auth/realm-export.json).

Camada extra de defesa (opt-in, `OIDC_ALLOWED_CLIENTS`): scope por si só
autoriza "o quê", mas não "quem" — um token com scope `users:read`
emitido para *qualquer* client é aceite, mesmo que esse client nunca
devesse chamar este serviço. Quando `OIDC_ALLOWED_CLIENTS` está
definida (lista separada por vírgulas de `client_id`s, verificados
contra o claim `azp`), passa a rejeitar com 403 qualquer token cujo
`azp` não conste da lista — mesmo com o scope certo. Fica vazia por
omissão (comportamento antigo, só scope) para não partir instalações
existentes só por teres esquecido de a definir.
"""
import logging
import os

import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

logger = logging.getLogger("service-orders.security")

OIDC_ISSUER = os.getenv("OIDC_ISSUER")
JWKS_TIMEOUT_SECONDS = float(os.getenv("OIDC_JWKS_TIMEOUT_SECONDS", "5"))
ALLOWED_CLIENTS = {c.strip() for c in os.getenv("OIDC_ALLOWED_CLIENTS", "").split(",") if c.strip()}

if not OIDC_ISSUER:


    raise RuntimeError(
        "OIDC_ISSUER não definido — obrigatório para localizar o endpoint JWKS "
        "do Keycloak. Ver k8s/auth/keycloak.yaml (cluster) ou docker-compose.yml (local)."
    )

_JWKS_URL = f"{OIDC_ISSUER.rstrip('/')}/protocol/openid-connect/certs"
_jwks_client = jwt.PyJWKClient(_JWKS_URL, timeout=JWKS_TIMEOUT_SECONDS, cache_keys=True)

_bearer_scheme = HTTPBearer(auto_error=False)


class TokenClaims:
    __slots__ = ("subject", "scopes", "client_id")

    def __init__(self, subject: str, scopes: set[str], client_id: str | None):
        self.subject = subject
        self.scopes = scopes
        self.client_id = client_id


def _get_signing_key(token: str):
    """Isolado numa função à parte para que os testes possam substituir
    esta chamada (sem bater num Keycloak real) por uma chave RSA de teste."""
    try:
        return _jwks_client.get_signing_key_from_jwt(token).key
    except jwt.PyJWKClientError as exc:
        logger.error("Falha a obter a chave de assinatura no JWKS do Keycloak: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Não foi possível validar a assinatura do token (identidade indisponível)",
            headers={"WWW-Authenticate": "Bearer"},
        )


def _decode_token(token: str) -> TokenClaims:
    signing_key = _get_signing_key(token)
    try:
        payload = jwt.decode(
            token,
            signing_key,
            algorithms=["RS256"],
            issuer=OIDC_ISSUER,


            options={"require": ["exp", "sub", "scope"], "verify_aud": False},
        )
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token expirado",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except jwt.InvalidTokenError as exc:
        logger.warning("Token JWT rejeitado: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido",
            headers={"WWW-Authenticate": "Bearer"},
        )

    scopes = set(payload.get("scope", "").split())
    subject = payload.get("sub", "desconhecido")


    client_id = payload.get("azp")
    return TokenClaims(subject=subject, scopes=scopes, client_id=client_id)


def require_scope(*required: str):
    """Dependency factory: exige um Bearer token válido com pelo menos um
    dos scopes indicados. Uso: `Depends(require_scope("users:read"))`."""
    required_scopes = set(required)

    def _dependency(
        credentials: HTTPAuthorizationCredentials | None = Depends(_bearer_scheme),
    ) -> TokenClaims:
        if credentials is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Autenticação necessária (Bearer token em falta)",
                headers={"WWW-Authenticate": "Bearer"},
            )

        claims = _decode_token(credentials.credentials)

        if ALLOWED_CLIENTS and claims.client_id not in ALLOWED_CLIENTS:
            logger.warning(
                "Acesso negado a '%s': client '%s' não está na allowlist %s",
                claims.subject,
                claims.client_id,
                sorted(ALLOWED_CLIENTS),
            )
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Client não autorizado para este serviço",
            )

        if not (claims.scopes & required_scopes):
            logger.warning(
                "Acesso negado a '%s' (client '%s'): scopes %s insuficientes (requer um de %s)",
                claims.subject,
                claims.client_id,
                sorted(claims.scopes),
                sorted(required_scopes),
            )
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Permissões insuficientes para este endpoint",
            )

        return claims

    return _dependency
