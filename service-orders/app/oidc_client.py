import logging
import threading
import time
import httpx

logger = logging.getLogger("service-orders.oidc_client")


_EXPIRY_SAFETY_MARGIN_SECONDS = 15


class ClientCredentialsTokenProvider:
    """Thread-safe; pensado para um único processo uvicorn (sem workers
    múltiplos). Com >1 worker, cada processo mantém a sua própria cache
    — aceitável, dado o baixo custo de um pedido de token adicional."""

    def __init__(self, token_url: str, client_id: str, client_secret: str, timeout: float = 5.0):
        self._token_url = token_url
        self._client_id = client_id
        self._client_secret = client_secret
        self._timeout = timeout
        self._lock = threading.Lock()
        self._cached_token: str | None = None
        self._expires_at: float = 0.0

    def get_token(self) -> str:
        with self._lock:
            if self._cached_token and time.time() < self._expires_at - _EXPIRY_SAFETY_MARGIN_SECONDS:
                return self._cached_token
            return self._fetch_new_token()

    def _fetch_new_token(self) -> str:
        try:
            with httpx.Client(timeout=self._timeout) as client:
                resp = client.post(
                    self._token_url,
                    data={
                        "grant_type": "client_credentials",
                        "client_id": self._client_id,
                        "client_secret": self._client_secret,
                    },
                )
                resp.raise_for_status()
        except httpx.HTTPStatusError as exc:
            logger.error(
                "Keycloak recusou o pedido de token client_credentials (%s): %s",
                exc.response.status_code if exc.response is not None else "?",
                exc,
            )
            raise
        except httpx.RequestError as exc:
            logger.error("Keycloak indisponível ao pedir token client_credentials: %s", exc)
            raise

        body = resp.json()
        token = body["access_token"]
        expires_in = float(body.get("expires_in", 60))
        self._cached_token = token
        self._expires_at = time.time() + expires_in
        logger.info("Novo token M2M obtido do Keycloak (válido por ~%ds)", int(expires_in))
        return token
