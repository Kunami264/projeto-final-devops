import os
import time

import httpx
import pytest

USERS_URL = os.getenv("USERS_URL", "http://localhost:8002")
ORDERS_URL = os.getenv("ORDERS_URL", "http://localhost:8001")
WEB_URL = os.getenv("WEB_URL", "http://localhost:8000")
DEMO_USERNAME = os.getenv("DEMO_USERNAME", "admin")
DEMO_PASSWORD = os.getenv("DEMO_PASSWORD", "admin")
TOKEN_URL = f"{USERS_URL}/auth/token"


def _get_real_token() -> str:
    last_error = None
    for _attempt in range(10):
        try:
            resp = httpx.post(TOKEN_URL, json={"username": DEMO_USERNAME, "password": DEMO_PASSWORD}, timeout=10)
            resp.raise_for_status()
            return resp.json()["access_token"]
        except (httpx.HTTPStatusError, httpx.RequestError) as exc:
            last_error = exc
            time.sleep(2)
    raise RuntimeError(f"Não foi possível obter um token em {TOKEN_URL}: {last_error}")


@pytest.fixture(scope="module")
def orders_write_headers():
    return {"Authorization": f"Bearer {_get_real_token()}"}


@pytest.mark.integration
def test_login_with_wrong_password_is_rejected():
    r = httpx.post(TOKEN_URL, json={"username": DEMO_USERNAME, "password": "password-errada"}, timeout=10)
    assert r.status_code == 401


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


@pytest.mark.integration
def test_create_edit_and_delete_user_and_order_end_to_end(orders_write_headers):
    headers = orders_write_headers
    email = f"cliente.{int(time.time() * 1000)}@example.com"

    r = httpx.post(f"{USERS_URL}/users", json={"name": "Cliente de Teste", "email": email}, headers=headers, timeout=10)
    assert r.status_code == 201
    user_id = r.json()["id"]

    try:
        r = httpx.post(
            f"{ORDERS_URL}/orders",
            json={"user_id": user_id, "item": "Portátil", "quantity": 1},
            headers=headers,
            timeout=10,
        )
        assert r.status_code == 200
        order_id = r.json()["id"]
        assert r.json()["user"]["email"] == email

        r = httpx.put(
            f"{USERS_URL}/users/{user_id}",
            json={"name": "Cliente de Teste Editado", "email": email},
            headers=headers,
            timeout=10,
        )
        assert r.status_code == 200
        assert r.json()["name"] == "Cliente de Teste Editado"

        r = httpx.put(
            f"{ORDERS_URL}/orders/{order_id}",
            json={"item": "Portátil", "quantity": 2},
            headers=headers,
            timeout=10,
        )
        assert r.status_code == 200
        assert r.json()["quantity"] == 2

        r = httpx.delete(f"{ORDERS_URL}/orders/{order_id}", headers=headers, timeout=10)
        assert r.status_code == 204
        assert httpx.get(f"{ORDERS_URL}/orders/{order_id}", headers=headers, timeout=10).status_code == 404
    finally:
        r = httpx.delete(f"{USERS_URL}/users/{user_id}", headers=headers, timeout=10)

    assert r.status_code == 204
    assert httpx.get(f"{USERS_URL}/users/{user_id}", headers=headers, timeout=10).status_code == 404


@pytest.mark.integration
def test_create_user_requires_authentication():
    r = httpx.post(f"{USERS_URL}/users", json={"name": "Anónimo", "email": "anonimo@example.com"}, timeout=5)
    assert r.status_code == 401


@pytest.mark.integration
def test_backoffice_serves_the_application():
    r = httpx.get(f"{WEB_URL}/", timeout=5)
    assert r.status_code == 200
    assert "Backoffice" in r.text
    assert "default-src 'self'" in r.headers["content-security-policy"]
    assert httpx.get(f"{WEB_URL}/app.js", timeout=5).status_code == 200


@pytest.mark.integration
def test_backoffice_login_and_crud_through_its_own_address():
    r = httpx.post(f"{WEB_URL}/auth/token", json={"username": DEMO_USERNAME, "password": DEMO_PASSWORD}, timeout=10)
    assert r.status_code == 200
    headers = {"Authorization": f"Bearer {r.json()['access_token']}"}

    email = f"backoffice.{int(time.time() * 1000)}@example.com"
    r = httpx.post(f"{WEB_URL}/users", json={"name": "Via Backoffice", "email": email}, headers=headers, timeout=10)
    assert r.status_code == 201
    user_id = r.json()["id"]
    try:
        r = httpx.post(f"{WEB_URL}/orders", json={"user_id": user_id, "item": "Rato", "quantity": 1}, headers=headers, timeout=10)
        assert r.status_code == 200
        order_id = r.json()["id"]
        r = httpx.put(f"{WEB_URL}/orders/{order_id}", json={"item": "Rato", "quantity": 4}, headers=headers, timeout=10)
        assert r.status_code == 200
        assert r.json()["quantity"] == 4
        assert httpx.delete(f"{WEB_URL}/orders/{order_id}", headers=headers, timeout=10).status_code == 204
    finally:
        r = httpx.delete(f"{WEB_URL}/users/{user_id}", headers=headers, timeout=10)
    assert r.status_code == 204


@pytest.mark.integration
def test_backoffice_only_proxies_the_login_endpoint():
    # Só /auth/token passa para o service-users; o resto de /auth não existe no site
    assert httpx.get(f"{WEB_URL}/auth/outra-coisa", timeout=5).status_code == 404
