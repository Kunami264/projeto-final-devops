import argparse
import json
import os
import ssl
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

REALM_TOKEN_PATH = "/realms/projeto-final/protocol/openid-connect/token"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Cria, edita e apaga um cliente e uma encomenda (demonstração).")
    parser.add_argument("--base-url", help="Ponto de entrada único (Ingress). Define users/orders/keycloak de uma vez.")
    parser.add_argument("--users-url", default=os.getenv("USERS_URL", "http://localhost:8002"))
    parser.add_argument("--orders-url", default=os.getenv("ORDERS_URL", "http://localhost:8001"))
    parser.add_argument("--keycloak-url", default=os.getenv("KEYCLOAK_BASE_URL", "http://localhost:8080"))
    parser.add_argument("--client-id", default=os.getenv("API_CLI_CLIENT_ID", "api-cli"))
    parser.add_argument("--client-secret", default=os.getenv("API_CLI_CLIENT_SECRET", "troque-este-segredo-api-cli"))
    parser.add_argument("--username", default=os.getenv("DEMO_USERNAME", "admin"))
    parser.add_argument("--password", default=os.getenv("DEMO_PASSWORD", "admin"))
    parser.add_argument("--insecure", action="store_true", help="Aceita certificado TLS self-signed")
    args = parser.parse_args()

    if args.base_url:
        args.users_url = args.orders_url = args.keycloak_url = args.base_url.rstrip("/")
    for url in (args.users_url, args.orders_url, args.keycloak_url):
        if urllib.parse.urlparse(url).scheme not in ("http", "https"):
            sys.exit(f"Endereço inválido (só http/https): {url}")
    return args


def _build_request(method: str, url: str, token: str | None, body: dict | None, form: dict | None) -> urllib.request.Request:
    headers = {}
    data = None
    if token:
        headers["Authorization"] = f"Bearer {token}"
    if body is not None:
        data = json.dumps(body).encode()
        headers["Content-Type"] = "application/json"
    if form is not None:
        data = urllib.parse.urlencode(form).encode()
    return urllib.request.Request(url, data=data, headers=headers, method=method)


def call(method: str, url: str, token: str | None = None, body: dict | None = None,
         form: dict | None = None, context: ssl.SSLContext | None = None):
    request = _build_request(method, url, token, body, form)
    try:
        with urllib.request.urlopen(request, timeout=15, context=context) as resp:
            raw = resp.read()
            status = resp.status
    except urllib.error.HTTPError as exc:
        sys.exit(f"   ✗ {method} {url} -> HTTP {exc.code}: {exc.read().decode(errors='replace')}")
    except urllib.error.URLError as exc:
        sys.exit(f"   ✗ {method} {url} -> sem resposta ({exc.reason}). O ambiente está a correr?")
    print(f"   ✓ {method} {url} -> HTTP {status}")
    return json.loads(raw) if raw else None


def main() -> None:
    args = parse_args()
    context = ssl._create_unverified_context() if args.insecure else None  # NOSONAR — opção explícita, só para o certificado autoassinado de PRD
    users, orders = args.users_url, args.orders_url

    print("1) Autenticação no Keycloak")
    token = call(
        "POST",
        args.keycloak_url.rstrip("/") + REALM_TOKEN_PATH,
        form={
            "grant_type": "password",
            "client_id": args.client_id,
            "client_secret": args.client_secret,
            "username": args.username,
            "password": args.password,
        },
        context=context,
    )["access_token"]

    print("2) Criar utilizador")
    user = call("POST", f"{users}/users", token, context=context,
                body={"name": "Cliente Demo", "email": f"cliente.demo.{int(time.time())}@example.com"})
    print(f"     {user}")

    print("3) Criar encomenda para esse utilizador")
    order = call("POST", f"{orders}/orders", token, context=context,
                 body={"user_id": user["id"], "item": "Portátil 14\"", "quantity": 1})
    print(f"     {order}")

    print("4) Editar o utilizador (novo nome)")
    user = call("PUT", f"{users}/users/{user['id']}", token, context=context,
                body={"name": "Cliente Demo Lda.", "email": user["email"]})
    print(f"     {user}")

    print("5) Editar a encomenda (nova quantidade)")
    order = call("PUT", f"{orders}/orders/{order['id']}", token, context=context,
                 body={"item": order["item"], "quantity": 3})
    print(f"     {order}")

    print("6) Listar utilizadores e encomendas")
    print(f"     {len(call('GET', f'{users}/users', token, context=context))} utilizadores")
    print(f"     {len(call('GET', f'{orders}/orders', token, context=context))} encomendas")

    print("7) Apagar a encomenda")
    call("DELETE", f"{orders}/orders/{order['id']}", token, context=context)

    print("8) Apagar o utilizador")
    call("DELETE", f"{users}/users/{user['id']}", token, context=context)

    print("\nDemonstração concluída ✅")


if __name__ == "__main__":
    main()
