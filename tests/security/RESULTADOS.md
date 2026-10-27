# Testes de vulnerabilidades — resultados

Testes de segurança do código e das dependências (M8). Não precisam do ambiente a correr: analisam o código, os ficheiros de dependências e as imagens já construídas.

| Ferramenta | O que analisa | Onde corre | Comando |
|---|---|---|---|
| **pip-audit** 2.10.1 | Dependências Python de cada serviço (`requirements-prd.txt` e `requirements-tracing.txt`) | DEV, STG e pipeline | `make security-deps` |
| **Trivy** 0.76.1 (fs) | Os mesmos ficheiros de dependências, com a base de dados do Trivy | DEV, STG e pipeline | `make security-deps` |
| **Trivy** 0.76.1 (imagem) | As imagens que seguem para PRD (sistema operativo e pacotes Python) | STG e pipeline | `make security-images` |
| **SonarQube** Community 26.9 | Código Python: vulnerabilidades, *security hotspots* e qualidade | DEV e pipeline | `make sonar` |

`make security` reúne o pip-audit, o Trivy às dependências e o SonarQube, e está incluído em `make test-dev`. `make test-stg` corre o pip-audit e o Trivy às dependências e às imagens. Os testes estão em [`test_vulnerabilidades.py`](test_vulnerabilidades.py). Cada execução grava os relatórios detalhados em `tests/security/reports/`, e o pipeline guarda-os como artefacto (`relatorios-seguranca`).

**Política:** nenhuma vulnerabilidade é ignorada. O `.trivyignore` foi eliminado, e qualquer vulnerabilidade HIGH ou CRITICAL (com ou sem correção disponível) faz falhar os testes.

## Resultado atual (última verificação: 27/10/2026)

| Análise | Resultado |
|---|---|
| pip-audit — 4 ficheiros de dependências | 0 vulnerabilidades |
| Trivy — dependências | 0 vulnerabilidades |
| Trivy — imagens `service-users`, `service-orders` e `web` | 0 vulnerabilidades, em todas as severidades |
| SonarQube | 0 *issues*; *quality gate* "Segurança" aprovado |

## Vulnerabilidades encontradas e como foram resolvidas

Antes desta correção, o `.trivyignore` escondia três CVEs. A análise completa das imagens mostrava ainda outras vulnerabilidades:

| Onde | Vulnerabilidades | Resolução |
|---|---|---|
| `starlette` 0.49.3 (dependência do FastAPI) | CVE-2026-48818 e CVE-2026-54283 (HIGH), CVE-2026-48710 e CVE-2026-48817 (MEDIUM) | `starlette` 1.10.0. O FastAPI passou para a 0.141.1, a última versão que aceita o Starlette 1.x sem depender do OpenTelemetry. O `prometheus-fastapi-instrumentator` passou para a 8.1.0 (compatível com o Starlette 1.x) |
| Sistema operativo da imagem (Debian 13, `python:3.12-slim`) | 44 HIGH, 58 MEDIUM e 61 LOW **sem correção disponível** | Base das imagens mudada para Alpine (`python:3.12-alpine3.24`): 0 vulnerabilidades |
| `pip` incluído na imagem (traz `urllib3`, `msgpack` e `setuptools` próprios) | 3 HIGH e vários MEDIUM | O `pip` é removido da imagem depois de instalar as dependências: não é necessário em execução |
| `setuptools` (fixado em `<81`) | 1 MEDIUM | Retirado: deixou de ser necessário |
| `PyJWT` 2.14.0 | 2 MEDIUM | `PyJWT` 2.15.1 |
| `opentelemetry-api` 1.39.1 | 1 MEDIUM | Versão 1.45.1, e o OpenTelemetry saiu da imagem de STG/PRD (fica só em DEV, em `requirements-tracing.txt`) |
| `pytest` 8.3.3 (testes) | 1 MEDIUM (CVE-2025-71176) | `pytest` 9.1.1 |
| CVE-2026-0994 | Já não aparece com as versões atuais | — |

## SonarQube: de 25 *issues* para 0

| *Issues* | Correção |
|---|---|
| 14 × respostas de erro (`HTTPException` 404, 409, 502, 503) não documentadas na API | Respostas declaradas em cada rota (`responses=`), visíveis em `/docs` |
| 4 × textos repetidos (`"orders:write"`, `"users:write"`, mensagens de erro) | Constantes (`SCOPE_READ`, `SCOPE_WRITE`, `ORDER_NOT_FOUND`, `USER_NOT_FOUND`, …) |
| 5 × `logging.error()` dentro de `except` | `logging.exception()`, que regista também a causa do erro |
| 1 × complexidade cognitiva de `scripts/demo.py` (17, limite 15) | Função `main` dividida em `parse_args`, `_build_request` e `call` |
| 2 × testes (`yield` inútil num *fixture*, asserção composta) | *Fixture* sem `yield`; asserção dividida em duas |

Foi também corrigido o *quality gate* "Segurança". O SonarQube 26 junta condições de "código novo" (cobertura de testes, duplicação, *issues*) a cada *gate* criado. Por isso, a partir da segunda análise o *gate* falhava sempre que o código mudava. O `make sonar-up` passa a deixar apenas a condição de segurança.
