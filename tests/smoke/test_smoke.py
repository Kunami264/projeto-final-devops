"""Smoke tests — correm em STG, logo após o deploy, como última validação antes de PRD."""

import os

import httpx

USERS_URL = os.getenv("USERS_URL", "http://localhost:8002")
ORDERS_URL = os.getenv("ORDERS_URL", "http://localhost:8001")
WEB_URL = os.getenv("WEB_URL", "http://localhost:8000")


def test_users_service_responds():
    r = httpx.get(f"{USERS_URL}/health", timeout=5)
    assert r.status_code == 200


def test_orders_service_responds():
    r = httpx.get(f"{ORDERS_URL}/health", timeout=5)
    assert r.status_code == 200


def test_backoffice_responds():
    r = httpx.get(f"{WEB_URL}/healthz", timeout=5)
    assert r.status_code == 200
