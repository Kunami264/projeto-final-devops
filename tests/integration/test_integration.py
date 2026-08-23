import os
import time

import httpx
import pytest

USERS_URL = os.getenv("USERS_URL", "http://localhost:8002")
ORDERS_URL = os.getenv("ORDERS_URL", "http://localhost:8001")
KEYCLOAK_BASE_URL = os.getenv("KEYCLOAK_BASE_URL", "http://localhost:8080")
KEYCLOAK_MGMT_URL = os.getenv("KEYCLOAK_MGMT_URL", "http://localhost:9000")
KEYCLOAK_TOKEN_URL = os.getenv(
    "KEYCLOAK_TOKEN_URL",
    f"{KEYCLOAK_BASE_URL}/realms/projeto-final/protocol/openid-connect/token",
)


API_CLI_CLIENT_ID = os.getenv("API_CLI_CLIENT_ID", "api-cli")
API_CLI_CLIENT_SECRET = os.getenv("API_CLI_CLIENT_SECRET", "troque-este-segredo-api-cli")
DEMO_USERNAME = os.getenv("DEMO_USERNAME", "daniel")
DEMO_PASSWORD = os.getenv("DEMO_PASSWORD", "MudaEstaPassword123!")


def _get_real_token() -> str:
    """Pede um token a sério ao Keycloak (grant_type=password, client
    api-cli) — ao contrário dos testes unitários, aqui não há nenhum
    JWKS simulado: isto testa a integração real com o Authorization
    Server, tal como aconteceria em produção."""
    last_error = None
    for attempt in range(10):
        try:
            resp = httpx.post(
                KEYCLOAK_TOKEN_URL,
                data={
                    "grant_type": "password",
                    "client_id": API_CLI_CLIENT_ID,
                    "client_secret": API_CLI_CLIENT_SECRET,
                    "username": DEMO_USERNAME,
                    "password": DEMO_PASSWORD,
                },
                timeout=10,
            )
            resp.raise_for_status()
            return resp.json()["access_token"]
        except (httpx.HTTPStatusError, httpx.RequestError) as exc:
            last_error = exc
            time.sleep(2)
    raise RuntimeError(f"Não foi possível obter um token do Keycloak em {KEYCLOAK_TOKEN_URL}: {last_error}")


@pytest.fixture(scope="module")
def orders_write_headers():
    return {"Authorization": f"Bearer {_get_real_token()}"}


@pytest.mark.integration
def test_keycloak_is_healthy():
    r = httpx.get(f"{KEYCLOAK_MGMT_URL}/health/ready", timeout=5)
    assert r.status_code == 200


@pytest.mark.integration
def test_users_service_is_healthy():
    r = httpx.get(f"{USERS_URL}/health", timeout=5)
    assert r.status_code == 200
    assert r.json()["status"] == "ok"


@pytest.mark.integration
def test_orders_service_is_healthy():
    r = httpx.get(f"{ORDERS_URL}/health", timeout=5)
    assert r.status_code == 200
    assert r.json()["status"] == "ok"


@pytest.mark.integration
def test_users_metrics_endpoint_is_exposed():
    r = httpx.get(f"{USERS_URL}/metrics", timeout=5)
    assert r.status_code == 200


@pytest.mark.integration
def test_orders_endpoint_requires_authentication():
    payload = {"user_id": 2, "item": "Monitor 27\"", "quantity": 1}
    r = httpx.post(f"{ORDERS_URL}/orders", json=payload, timeout=5)
    assert r.status_code == 401


@pytest.mark.integration
def test_order_creation_calls_users_service_end_to_end(orders_write_headers):
    """Cobre a cadeia toda: Keycloak emite o token do utilizador →
    service-orders valida-o (JWKS) → service-orders pede o seu próprio
    token M2M ao Keycloak (client_credentials) → chama service-users →
    service-users valida esse segundo token (JWKS) → responde."""
    payload = {"user_id": 2, "item": "Monitor 27\"", "quantity": 1}
    r = httpx.post(f"{ORDERS_URL}/orders", json=payload, headers=orders_write_headers, timeout=10)
    assert r.status_code == 200

    body = r.json()
    assert body["item"] == payload["item"]
    assert body["user"]["id"] == 2
    assert body["user"]["name"] == "Ana Costa"


@pytest.mark.integration
def test_order_creation_with_invalid_user_returns_404(orders_write_headers):
    payload = {"user_id": 9999, "item": "Item inexistente", "quantity": 1}
    r = httpx.post(f"{ORDERS_URL}/orders", json=payload, headers=orders_write_headers, timeout=10)
    assert r.status_code == 404
