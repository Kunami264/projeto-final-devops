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


def test_create_user(write_headers, auth_headers):
    r = client.post("/users", json={"name": "Rita Lopes", "email": "rita.lopes@example.com"}, headers=write_headers)
    assert r.status_code == 201
    body = r.json()
    assert body["id"] == 4
    assert body["name"] == "Rita Lopes"

    fetched = client.get(f"/users/{body['id']}", headers=auth_headers)
    assert fetched.status_code == 200
    assert fetched.json()["email"] == "rita.lopes@example.com"


def test_create_user_with_duplicate_email_returns_409(write_headers):
    r = client.post("/users", json={"name": "Outra Ana", "email": "ana.costa@example.com"}, headers=write_headers)
    assert r.status_code == 409


def test_create_user_with_invalid_email_returns_422(write_headers):
    r = client.post("/users", json={"name": "Sem Email", "email": "nao-e-um-email"}, headers=write_headers)
    assert r.status_code == 422


def test_create_user_with_read_only_scope_returns_403(auth_headers):
    r = client.post("/users", json={"name": "Rita Lopes", "email": "rita.lopes@example.com"}, headers=auth_headers)
    assert r.status_code == 403


def test_create_user_without_token_returns_401():
    r = client.post("/users", json={"name": "Rita Lopes", "email": "rita.lopes@example.com"})
    assert r.status_code == 401


def test_delete_user(write_headers, auth_headers):
    r = client.delete("/users/3", headers=write_headers)
    assert r.status_code == 204

    assert client.get("/users/3", headers=auth_headers).status_code == 404
    assert len(client.get("/users", headers=auth_headers).json()) == 2


def test_delete_nonexistent_user_returns_404(write_headers):
    r = client.delete("/users/999", headers=write_headers)
    assert r.status_code == 404


def test_delete_user_with_read_only_scope_returns_403(auth_headers):
    r = client.delete("/users/1", headers=auth_headers)
    assert r.status_code == 403


def test_update_user(write_headers, auth_headers):
    r = client.put("/users/2", json={"name": "Ana Costa Lima", "email": "ana.lima@example.com"}, headers=write_headers)
    assert r.status_code == 200
    assert r.json() == {"id": 2, "name": "Ana Costa Lima", "email": "ana.lima@example.com"}

    assert client.get("/users/2", headers=auth_headers).json()["email"] == "ana.lima@example.com"


def test_update_nonexistent_user_returns_404(write_headers):
    r = client.put("/users/999", json={"name": "Ninguém", "email": "ninguem@example.com"}, headers=write_headers)
    assert r.status_code == 404


def test_update_user_with_email_of_another_user_returns_409(write_headers):
    r = client.put("/users/2", json={"name": "Ana Costa", "email": "daniel.silva@example.com"}, headers=write_headers)
    assert r.status_code == 409


def test_update_user_with_read_only_scope_returns_403(auth_headers):
    r = client.put("/users/2", json={"name": "Ana", "email": "ana@example.com"}, headers=auth_headers)
    assert r.status_code == 403
