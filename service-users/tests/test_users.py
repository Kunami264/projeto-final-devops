from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_health_does_not_require_auth():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok", "service": "service-users"}


def test_metrics_endpoint_does_not_require_auth():
    r = client.get("/metrics")
    assert r.status_code == 200
    assert "http_requests_total" in r.text or "python_info" in r.text


def test_get_existing_user(auth_headers):
    r = client.get("/users/1", headers=auth_headers)
    assert r.status_code == 200
    body = r.json()
    assert body["id"] == 1
    assert body["name"] == "Daniel Silva"
    assert "email" in body


def test_get_nonexistent_user_returns_404(auth_headers):
    r = client.get("/users/999", headers=auth_headers)
    assert r.status_code == 404


def test_list_users_returns_all(auth_headers):
    r = client.get("/users", headers=auth_headers)
    assert r.status_code == 200
    body = r.json()
    assert isinstance(body, list)
    assert len(body) == 3


def test_list_users_without_token_returns_401():
    r = client.get("/users")
    assert r.status_code == 401


def test_get_user_with_wrong_scope_returns_403(wrong_scope_headers):
    r = client.get("/users/1", headers=wrong_scope_headers)
    assert r.status_code == 403


def test_get_user_with_expired_token_returns_401(expired_token_headers):
    r = client.get("/users/1", headers=expired_token_headers)
    assert r.status_code == 401


def test_get_user_with_malformed_token_returns_401():
    r = client.get("/users/1", headers={"Authorization": "Bearer isto-nao-e-um-jwt"})
    assert r.status_code == 401


def test_azp_allowlist_rejects_client_not_in_list(auth_headers, monkeypatch):
    from app import security

    monkeypatch.setattr(security, "ALLOWED_CLIENTS", {"service-orders-production"})

    r = client.get("/users/1", headers=auth_headers)
    assert r.status_code == 403


def test_azp_allowlist_accepts_client_in_list(auth_headers, monkeypatch):
    from app import security

    monkeypatch.setattr(security, "ALLOWED_CLIENTS", {"api-cli"})
    r = client.get("/users/1", headers=auth_headers)
    assert r.status_code == 200
