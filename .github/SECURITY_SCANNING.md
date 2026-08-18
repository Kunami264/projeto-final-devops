# Vulnerability scanning no CI

O pipeline usa Trivy em todos os `push` e `pull_request` para os branches
`dev`, `stg` e `main`.

- `security-source` analisa as dependências declaradas no repositório.
- `security-images` constrói cada imagem Docker localmente e analisa as
  dependências presentes nas layers finais.
- Ambos falham para vulnerabilidades `HIGH` ou `CRITICAL`; o job `build`, e
  por consequência qualquer deploy, só começa depois dos dois scans passarem.

O scanner é configurado apenas para vulnerabilidades (`scanners: vuln`). A
análise de secrets e de misconfigurations deve ser introduzida como controlos
dedicados, após tratar os respetivos findings, para evitar misturar políticas
e tornar os falsos positivos auditáveis.

Para investigar um finding, reproduz localmente com Trivy e corrige ou
actualiza a dependência/base image. Exceções temporárias devem ter ticket,
justificação, owner e data de expiração; não devem ser silenciadas globalmente
no workflow.

## Nota sobre segredos em `docker-compose.yml`

`OIDC_CLIENT_SECRET`, as credenciais de admin do Keycloak/Grafana e
`POSTGRES_PASSWORD` no `docker-compose.yml`, bem como os segredos dos
clients no `k8s/auth/realm-export.json`, são fixtures de desenvolvimento
local — o mesmo padrão já existente antes desta alteração
(`orders_dev_password`). Não são usados em staging/produção: aí,
`oidc.clientSecret` vem de um secret do GitHub, injetado via `--set` no
`helm upgrade` (ver `.github/workflows/pipeline.yml`), nunca de um
ficheiro versionado — e o Keycloak/Grafana de staging/produção têm as
suas próprias credenciais de admin, geridas fora deste repositório (ver
os placeholders com comentário "troque" em `k8s/auth/keycloak.yaml` e
`k8s/observability/grafana.yaml`). Um scanner de secrets (ex.:
`gitleaks`, ou o `scanners: secret` do próprio Trivy) devia normalmente
acusar isto — se for introduzido, terá de ter uma allowlist explícita
para estas linhas de dev, com a mesma justificação acima.
