from unittest.mock import MagicMock, patch
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_health_does_not_require_auth():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok", "service": "service-orders"}


def test_metrics_endpoint_does_not_require_auth():
    r = client.get("/metrics")
    assert r.status_code == 200


@patch("app.main.httpx.Client")
def test_create_order_success(mock_client_cls, write_headers):
    mock_response = MagicMock()
    mock_response.raise_for_status.return_value = None
    mock_response.json.return_value = {
        "id": 1,
        "name": "Daniel Silva",
        "email": "daniel.silva@example.com",
    }
    mock_client = MagicMock()
    mock_client.__enter__.return_value.get.return_value = mock_response
    mock_client_cls.return_value = mock_client

    r = client.post(
        "/orders",
        json={"user_id": 1, "item": "Teclado mecânico", "quantity": 2},
        headers=write_headers,
    )
    assert r.status_code == 200
    body = r.json()
    assert body["item"] == "Teclado mecânico"
    assert body["quantity"] == 2
    assert body["user"]["id"] == 1


@patch("app.main.httpx.Client")
def test_create_order_user_not_found(mock_client_cls, write_headers):
    import httpx

    mock_response = MagicMock()
    mock_response.raise_for_status.side_effect = httpx.HTTPStatusError(
        "404", request=MagicMock(), response=MagicMock(status_code=404)
    )
    mock_client = MagicMock()
    mock_client.__enter__.return_value.get.return_value = mock_response
    mock_client_cls.return_value = mock_client

    r = client.post(
        "/orders",
        json={"user_id": 999, "item": "Rato", "quantity": 1},
        headers=write_headers,
    )
    assert r.status_code == 404


def test_create_order_without_token_returns_401():
    r = client.post("/orders", json={"user_id": 1, "item": "Rato", "quantity": 1})
    assert r.status_code == 401


def test_create_order_with_read_only_scope_returns_403(read_headers):
    r = client.post(
        "/orders",
        json={"user_id": 1, "item": "Rato", "quantity": 1},
        headers=read_headers,
    )
    assert r.status_code == 403


def test_get_nonexistent_order_returns_404(read_headers):
    r = client.get("/orders/999999", headers=read_headers)
    assert r.status_code == 404


def test_list_orders_without_token_returns_401():
    r = client.get("/orders")
    assert r.status_code == 401


def test_create_order_rejects_zero_or_negative_quantity(write_headers):
    r = client.post(
        "/orders",
        json={"user_id": 1, "item": "Rato", "quantity": 0},
        headers=write_headers,
    )
    assert r.status_code == 422

    r = client.post(
        "/orders",
        json={"user_id": 1, "item": "Rato", "quantity": -5},
        headers=write_headers,
    )
    assert r.status_code == 422


@patch("app.main.httpx.Client")
def test_created_order_is_persisted_and_listed(mock_client_cls, write_headers, read_headers):
    mock_response = MagicMock()
    mock_response.raise_for_status.return_value = None
    mock_response.json.return_value = {
        "id": 2,
        "name": "Ana Costa",
        "email": "ana.costa@example.com",
    }
    mock_client = MagicMock()
    mock_client.__enter__.return_value.get.return_value = mock_response
    mock_client_cls.return_value = mock_client

    created = client.post(
        "/orders",
        json={"user_id": 2, "item": "Monitor", "quantity": 1},
        headers=write_headers,
    ).json()

    fetched = client.get(f"/orders/{created['id']}", headers=read_headers)
    assert fetched.status_code == 200
    assert fetched.json()["item"] == "Monitor"

    listed = client.get("/orders", headers=read_headers).json()
    assert any(o["id"] == created["id"] for o in listed)


def test_azp_allowlist_rejects_client_not_in_list(read_headers, monkeypatch):
    from app import security

    monkeypatch.setattr(security, "ALLOWED_CLIENTS", {"outro-client"})

    r = client.get("/orders/1", headers=read_headers)
    assert r.status_code == 403


def test_azp_allowlist_accepts_client_in_list(read_headers, monkeypatch):
    from app import security

    monkeypatch.setattr(security, "ALLOWED_CLIENTS", {"api-cli"})
    r = client.get("/orders/999999", headers=read_headers)


    assert r.status_code == 404
