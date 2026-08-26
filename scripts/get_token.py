import argparse
import sys

try:
    import httpx
except ImportError:
    sys.exit("httpx não está instalado neste ambiente. Corre: pip install httpx")


DEFAULT_TOKEN_URL = "http://localhost:8080/realms/projeto-final/protocol/openid-connect/token"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument(
        "--token-url",
        default=DEFAULT_TOKEN_URL,
        help=f"Endpoint de token do Keycloak (default: {DEFAULT_TOKEN_URL})",
    )
    parser.add_argument("--grant", choices=["password", "client_credentials"], required=True)
    parser.add_argument("--client-id", default="api-cli", help="Default 'api-cli' (grant=password) ou 'service-orders-local'/'-staging'/'-production' (grant=client_credentials)")
    parser.add_argument("--client-secret", default="troque-este-segredo-api-cli")
    parser.add_argument("--username", help="Obrigatório para --grant password")
    parser.add_argument("--password", help="Obrigatório para --grant password")
    parser.add_argument("--scope", default=None, help="Scopes pedidos explicitamente (opcional — por omissão usam-se os default client scopes do realm)")
    args = parser.parse_args()

    data = {
        "grant_type": args.grant,
        "client_id": args.client_id,
        "client_secret": args.client_secret,
    }
    if args.grant == "password":
        if not args.username or not args.password:
            sys.exit("--grant password requer --username e --password")
        data["username"] = args.username
        data["password"] = args.password
    if args.scope:
        data["scope"] = args.scope

    try:
        resp = httpx.post(args.token_url, data=data, timeout=10)
        resp.raise_for_status()
    except httpx.HTTPStatusError as exc:
        sys.exit(f"Keycloak recusou o pedido ({exc.response.status_code}): {exc.response.text}")
    except httpx.RequestError as exc:
        sys.exit(f"Não foi possível contactar o Keycloak em {args.token_url}: {exc}")

    print(resp.json()["access_token"])


if __name__ == "__main__":
    main()
