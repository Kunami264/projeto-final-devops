"""Espera que o ambiente responda antes dos testes de integração e smoke.

Em STG os serviços chegam por port-forward (kubectl). A porta local pode já estar aberta
antes de o túnel até ao pod responder, e os primeiros testes falhavam com
"Connection refused". Aqui espera-se, uma única vez, que cada endereço responda por HTTP.
"""
import os
import time

import httpx
import pytest

TIMEOUT = int(os.getenv("WAIT_READY_TIMEOUT", "120"))


def _enderecos() -> dict[str, str]:
    users = os.getenv("USERS_URL", "http://localhost:8002")
    orders = os.getenv("ORDERS_URL", "http://localhost:8001")
    web = os.getenv("WEB_URL", "http://localhost:8000")
    keycloak_mgmt = os.getenv("KEYCLOAK_MGMT_URL", "http://localhost:9000")
    return {
        "service-users": f"{users}/health",
        "service-orders": f"{orders}/health",
        "web": f"{web}/healthz",
        "keycloak": f"{keycloak_mgmt}/health/ready",
    }


def _esperar_ambiente() -> str:
    em_falta = _enderecos()
    limite = time.monotonic() + TIMEOUT
    while em_falta and time.monotonic() < limite:
        for nome, url in list(em_falta.items()):
            try:
                if httpx.get(url, timeout=3).status_code == 200:
                    del em_falta[nome]
            except httpx.HTTPError:
                pass
        if em_falta:
            time.sleep(2)
    if not em_falta:
        return ""
    detalhe = ", ".join(f"{n} ({u})" for n, u in em_falta.items())
    return (f"O ambiente não respondeu em {TIMEOUT} s: {detalhe}. "
            "Confirmar que os pods estão prontos (kubectl get pods -n staging; kubectl get pods -n auth).")


@pytest.fixture(scope="session", autouse=True)
def ambiente_pronto(request):
    """Corre antes de qualquer outro fixture; só quando a sessão inclui testes de integração ou smoke."""
    pastas = {item.path.parent.name for item in request.session.items}
    if not pastas & {"integration", "smoke"}:
        return
    erro = _esperar_ambiente()
    if erro:
        pytest.fail(erro, pytrace=False)
