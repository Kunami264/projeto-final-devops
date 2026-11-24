"""Imprime um token de acesso (para o Swagger ou curl).

Faz login em POST /auth/token do service-users, com o utilizador e a password da plataforma.
Exemplo:  python scripts/get_token.py --username admin --password admin
"""
import argparse
import sys

try:
    import httpx
except ImportError:
    sys.exit("httpx não está instalado neste ambiente. Corre: pip install httpx")


DEFAULT_TOKEN_URL = "http://localhost:8002/auth/token"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--token-url", default=DEFAULT_TOKEN_URL, help=f"Endpoint de login (default: {DEFAULT_TOKEN_URL})")
    parser.add_argument("--username", required=True)
    parser.add_argument("--password", required=True)
    parser.add_argument("--insecure", action="store_true", help="Aceita certificado TLS self-signed (PRD local)")
    args = parser.parse_args()

    try:
        resp = httpx.post(
            args.token_url,
            json={"username": args.username, "password": args.password},
            timeout=10,
            verify=not args.insecure,
        )
        resp.raise_for_status()
    except httpx.HTTPStatusError as exc:
        sys.exit(f"Login recusado ({exc.response.status_code}): {exc.response.text}")
    except httpx.RequestError as exc:
        sys.exit(f"Não foi possível contactar {args.token_url}: {exc}")

    print(resp.json()["access_token"])


if __name__ == "__main__":
    main()
