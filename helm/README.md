# Chart Helm — Projeto Final

Substitui a duplicação manual que existia entre `k8s/staging/*.yaml` e
`k8s/production/*.yaml` (6 ficheiros idênticos na forma, diferentes só em
réplicas, tag de imagem e tipo de `Service`) por um único conjunto de
templates parametrizado por `values-<ambiente>.yaml`.

## Estrutura

```
helm/
├── Chart.yaml
├── values.yaml
├── values-staging.yaml
├── values-production.yaml
└── templates/
    ├── _helpers.tpl
    ├── configmap.yaml
    ├── secret-postgres.yaml
    ├── secret-auth.yaml
    ├── postgres-pvc.yaml
    ├── postgres-deployment.yaml
    ├── service-users.yaml
    ├── service-orders.yaml
    ├── hpa.yaml
    ├── ingress.yaml
    ├── networkpolicy.yaml
    ├── poddisruptionbudget.yaml
    └── NOTES.txt
```

Fora do chart, `k8s/` tem dois conjuntos de manifestos standalone
(aplicados com `kubectl apply -f`, nunca por `helm`):

```
k8s/
├── observability/
└── auth/
```


**Decisão deliberada: o Namespace NÃO é gerido por este chart.** Um recurso
`Namespace` dentro dos templates cria um risco real — se o `Namespace` for
adotado como parte do release do Helm, um `helm uninstall` pode arrastar
consigo o namespace inteiro (e, em cascata, o PVC do Postgres com os dados
de encomendas). Preferiu-se manter a criação do namespace fora do ciclo de
vida do release, via `--create-namespace`, que é a prática mais comum e
mais segura.

## Instalar / atualizar

```bash
# Staging
helm upgrade --install projeto-final ./helm \
  -n staging --create-namespace \
  -f ./helm/values-staging.yaml

# Produção
helm upgrade --install projeto-final ./helm \
  -n production --create-namespace \
  -f ./helm/values-production.yaml
```

O `Secret` de credenciais do GHCR (`ghcr-secret`) continua a não ser gerido
pelo chart — ver o `NOTES.txt` (mostrado automaticamente após o
`helm upgrade --install`) para o comando exato.

## Validar antes de aplicar

```bash
helm lint ./helm
helm template projeto-final ./helm -f ./helm/values-staging.yaml
helm template projeto-final ./helm -f ./helm/values-production.yaml
```

## Exposição HTTPS / TLS

O chart suporta terminação TLS no `Ingress` para a API pública
`service-orders`. O tráfego service-to-service continua privado dentro do
cluster. Por segurança, o `Ingress` vem desativado até existir um DNS real e
um `Ingress Controller`.
Quando o `Ingress` é ativado, o backend `service-orders` é forçado a
`ClusterIP`, mesmo que o overlay de produção configure `NodePort`; assim não
fica uma via HTTP pública que contorne TLS.

Para usar um certificado gerido pelo `cert-manager`, instala previamente um
`Ingress Controller` e o `cert-manager`, cria um `ClusterIssuer` adequado
(por exemplo, ACME/Let's Encrypt) e define um domínio cujo DNS aponta para o
load balancer do controller. Depois cria um ficheiro de override que **não
deve ser versionado com domínios ou configurações de produção**:

```yaml
# values-tls-production.yaml
ingress:
  enabled: true
  className: nginx
  host: api.exemplo.pt
  tls:
    enabled: true
    secretName: projeto-final-api-tls
    certManager:
      enabled: true
      clusterIssuer: letsencrypt-prod
```

```bash
helm upgrade --install projeto-final ./helm \
  -n production --create-namespace \
  -f ./helm/values-production.yaml \
  -f ./helm/values-tls-production.yaml

curl --fail --silent --show-error https://api.exemplo.pt/health
```

Quando a PKI é gerida externamente, mantém `certManager.enabled: false` e
cria antecipadamente no namespace o `Secret` TLS indicado em
`ingress.tls.secretName`, com as chaves `tls.crt` e `tls.key`.

## Autenticação / Autorização (Keycloak — Bearer JWT via OIDC)

Todos os endpoints de negócio exigem um `Authorization: Bearer <token>`
válido — `GET/POST /orders` e `GET /users` são protegidos por *scope*;
só `/health` e `/metrics` ficam abertos (isolados por `NetworkPolicy`,
não por token, pelo mesmo motivo que já se aplicava aos probes do
kubelet).

| Scope | Concede acesso a |
|---|---|
| `users:read` | `GET /users`, `GET /users/{id}` |
| `orders:read` | `GET /orders`, `GET /orders/{id}` |
| `orders:write` | `POST /orders` |

O Authorization Server é agora um **Keycloak real** (`k8s/auth/keycloak.yaml`,
namespace `auth`, fora do ciclo de vida deste chart — mesma lógica já
usada para o Jaeger/Prometheus/Grafana em `observability`). Os tokens
são **RS256**, assinados com a chave privada do Keycloak; os
microsserviços só conhecem a chave pública, obtida em runtime via JWKS
(`{issuer}/protocol/openid-connect/certs`) — já não existe nenhum
segredo partilhado capaz de assinar tokens.

O realm `projeto-final` (`k8s/auth/realm-export.json`) define:
- **`service-orders-local` / `service-orders-staging` / `service-orders-production`**
  — um client confidencial M2M (`client_credentials`) por ambiente, cada
  um com o seu próprio segredo, scope por omissão `users:read`. Ambiente
  isolado ≠ Keycloak isolado: os três continuam a confiar no mesmo
  realm/Keycloak partilhado (namespace `auth`), mas comprometer o
  segredo de staging não dá acesso a produção — são credenciais
  diferentes, revogáveis independentemente. O `service-orders` de cada
  ambiente pede o seu próprio token sob demanda (`app/oidc_client.py`),
  com cache e renovação automática — já não há um JWT estático de longa
  duração num Secret.
- **`api-cli`** — client de demonstração (`password` grant, considerado
  legacy pelo próprio Keycloak — só serve para gerar tokens de teste
  manualmente), com os 3 scopes por omissão. Partilhado entre ambientes
  de propósito: não é uma identidade de deployment.
- Utilizador de demonstração `daniel` / `MudaEstaPassword123!`.

```bash
# Token de demonstração (utilizador daniel, via client api-cli)
python scripts/get_token.py --grant password \
  --username daniel --password "MudaEstaPassword123!"

# Token M2M do service-orders local (para reproduzir manualmente o que
# ele faz ao chamar o service-users) — troca o client-id para
# service-orders-staging/-production consoante o ambiente que estiveres
# a depurar.
python scripts/get_token.py --grant client_credentials \
  --client-id service-orders-local --client-secret <segredo-do-realm-export>
```

`oidc.clientSecret` (o segredo do client `service-orders-<ambiente>` no
Keycloak — `oidc.clientId` já define qual, por omissão
`service-orders-staging` em `values.yaml` e `service-orders-production`
em `values-production.yaml`) fica vazio nos `values.yaml`/`values-<ambiente>.yaml`
versionados de propósito — é um segredo real, não pode viver em git.
Para não partir `helm lint`/`helm template` (que correm sem segredos,
ver "Validar antes de aplicar"), `secret-auth.yaml` só falha a
instalação quando **ambos** `oidc.clientSecret` está vazio **e**
`oidc.requireClientSecret=true` são verdade — e é exactamente isso que
os jobs `deploy-stg`/`deploy-prd` do pipeline definem, a par do valor
real do segredo (`OIDC_CLIENT_SECRET_STG`/`OIDC_CLIENT_SECRET_PRD`, dois
secrets do GitHub distintos — cada um corresponde ao client Keycloak
certo para esse ambiente):

```bash
helm upgrade --install projeto-final ./helm \
  -n production --create-namespace \
  -f ./helm/values-production.yaml \
  --set oidc.clientSecret="<segredo-real-do-client-service-orders-production>" \
  --set oidc.requireClientSecret=true
```

Sem `oidc.requireClientSecret=true`, esquecer o `--set
oidc.clientSecret` não bloqueia o `helm upgrade` — o `service-orders`
arranca à mesma mas regista um aviso no log e todas as chamadas a
`service-users` passam a falhar com 503. Em staging/produção, usa
sempre a flag para transformar isso num erro de instalação em vez de um
serviço parcialmente funcional.

### Camada extra de defesa: allowlist de `azp`

Scope autoriza "o quê" (`users:read`, `orders:write`, ...), mas não
"quem" — por omissão, um token com o scope certo é aceite
independentemente de qual client Keycloak o pediu. `OIDC_ALLOWED_CLIENTS`
(lista separada por vírgulas, verificada contra o claim `azp` do token)
fecha isso: rejeita com 403 qualquer token cujo client emissor não
conste da lista, mesmo com o scope certo. Fica vazia por omissão — o
comportamento é aditivo, nunca obrigatório.

Configurado via `oidc.allowedClientsForUsers`/`oidc.allowedClientsForOrders`
em `values.yaml` (staging) e `values-production.yaml`, injetado como env
var direta nos Deployments (não passa pelo `app-config` partilhado,
porque cada serviço confia em clients diferentes):

| Ambiente | `service-users` aceita chamadas de | `service-orders` aceita chamadas de |
|---|---|---|
| local (docker-compose) | `service-orders-local`, `api-cli` | `api-cli` |
| staging | `service-orders-staging`, `api-cli` | `api-cli` |
| produção | `service-orders-production` **(sem `api-cli`)** | `api-cli` |

Produção é deliberadamente mais restrita: o client de
demonstração/testes manuais (`api-cli`) não devia conseguir chamar
`service-users` diretamente em produção — só o próprio
`service-orders-production`. `service-orders` continua a aceitar
`api-cli` em todos os ambientes porque, nesta iteração, é o único
client "de utilizador final" que existe — não há ainda uma
aplicação/frontend real com o seu próprio client Keycloak; quando
existir, é essa allowlist que se aperta.

**Testado** (`tests/test_users.py::test_azp_allowlist_*`,
`tests/test_orders.py::test_azp_allowlist_*`): token com scope certo
mas `azp` fora da lista → 403; `azp` dentro da lista → passa. Não
validado contra o Keycloak real desta vez — mas como o mecanismo não
depende de nada específico do Keycloak (é só comparar uma string extraída
de um claim já validado), o risco residual aqui é bastante menor do que
o dos itens marcados acima como não confirmados.

### ✅ Keycloak — validado contra uma instância real (Keycloak 26.0.7)

Ao contrário da primeira versão deste chart, **`k8s/auth/realm-export.json`
e `k8s/auth/keycloak.yaml` foram entretanto validados de ponta a ponta**
contra um Keycloak 26.0.7 real (distribuição standalone, sem Docker —
mas o mesmo binário/realm-import da imagem oficial), incluindo a cadeia
completa `daniel` (login) → `service-orders` (valida + pede o seu
próprio token M2M) → `service-users` (valida) → resposta. Esse processo
apanhou três bugs reais que a validação sintática (JSON/YAML válidos)
não detetava:

1. **`KC_HOSTNAME` no formato errado.** No Keycloak ≥26 (hostname v2,
   agora por omissão), `KC_HOSTNAME` tem de ser um **URL completo**
   (`http://keycloak:8080`), não um hostname nu. `KC_HOSTNAME_PORT` é
   uma opção v1 que já não existe — usá-la faz o arranque falhar com
   `"Hostname v1 options [hostname-port] are still in use"`. Corrigido
   em `docker-compose.yml` e `k8s/auth/keycloak.yaml`.
2. **`/health/ready` não está na porta 8080 — está na porta de
   management, 9000.** Os healthchecks/probes apontavam para a porta
   errada e nunca ficariam saudáveis. Corrigido nos dois sítios acima e
   no `pipeline.yml`.
3. **O `access_token` saía sem o claim `sub`** (o `id_token` tinha-o,
   mas os microsserviços validam o `access_token`). Causa: listar
   `clientScopes` explicitamente no realm-export **substitui** os
   scopes nativos do Keycloak (`basic`, `profile`, `roles`, etc.) em
   vez de os complementar — ao contrário do que eu tinha assumido.
   `basic` (que transporta o mapper `oidc-sub-mapper`) teve de ser
   redefinido à mão e adicionado a `defaultClientScopes` em todos os
   clients. Sem isto, `security.py` rejeitaria **todos** os tokens
   (`sub` é um claim obrigatório).

Confirmado também, sem surpresas: nomes de scope com `:` (`users:read`)
funcionam sem problemas; `defaultClientScopes` aceita os nomes custom
definidos no mesmo ficheiro; o utilizador `daniel` precisa de
`lastName` preenchido (o User Profile por omissão do Keycloak exige-o,
senão o grant `password` falha com `"Account is not fully set up"`); e
as colunas de descrição no Keycloak têm um limite de 255 caracteres —
três das minhas descrições iniciais excediam isso.

Checklist para reproduzir a validação (ou revalidar depois de mexer no
realm):

```bash
docker compose up -d keycloak
# esperar ~30-40s pelo arranque + import do realm, depois:
curl -s http://localhost:9000/health/ready
curl -s http://localhost:8080/realms/projeto-final/.well-known/openid-configuration | jq .issuer
# tem de devolver exatamente: http://keycloak:8080/realms/projeto-final

TOKEN=$(python scripts/get_token.py --grant password \
  --username daniel --password "MudaEstaPassword123!")
echo "$TOKEN" | cut -d. -f2 | base64 -d 2>/dev/null | jq .
# confirmar que "sub" aparece no payload — é o sintoma do bug #3 acima
# se voltar a desaparecer depois de editares clientScopes/clients.
```

**O que continua por confirmar** (menor risco, mas ainda não testado):
o comportamento em Kubernetes real do `KC_HOSTNAME` fixo combinado com
`kubectl port-forward` (só testei via docker-compose/rede local — o
mecanismo devia ser idêntico, já que `KC_HOSTNAME` não depende de como
se chega ao pod, mas não tive um cluster real para confirmar); e se a
imagem `quay.io/keycloak/keycloak:26.0` tem `curl` disponível para os
healthchecks (testei com a distribuição standalone via `kc.sh`, não
com a imagem Docker propriamente dita).

## Observabilidade: métricas (Prometheus + Grafana) e logs correlacionados

Os dois microsserviços expõem `/metrics` (formato Prometheus, via
`prometheus-fastapi-instrumentator`) com contagens e latências por rota,
método e código de estado. Prometheus e Grafana correm como manifestos
standalone no namespace `observability` (mesmo padrão do Jaeger),
aplicados fora do ciclo de vida deste chart:

```bash
kubectl apply -f k8s/observability/
kubectl -n observability port-forward svc/prometheus 9090:9090 &
kubectl -n observability port-forward svc/grafana 3000:3000 &
# Prometheus: http://localhost:9090 — confirmar o target "kubernetes-pods"
# Grafana:    http://localhost:3000 — dashboard "service-users / service-orders
#             — visão geral" já provisionado na pasta "Projeto Final"
```

A descoberta de alvos do Prometheus usa `kubernetes_sd_configs` (role
`pod`), restrita aos namespaces `staging`/`production`, e só faz scrape
de pods com a anotação `prometheus.io/scrape: "true"` — já aplicada
pelos templates `service-users.yaml`/`service-orders.yaml`. O Grafana
vem com o datasource Prometheus e o dashboard provisionados por
ficheiro (não clicados na UI), para sobreviverem a um restart do pod.
Localmente, `docker-compose.yml` sobe um Prometheus + Grafana
equivalentes, acessíveis em `http://localhost:9090` e
`http://localhost:3000` (admin / `admin_dev_password`).

Prometheus e Grafana guardam o seu estado em `PersistentVolumeClaim`
(2Gi e 1Gi respectivamente) — sobrevivem a um restart do pod, ao
contrário do Jaeger (que continua em `emptyDir`, por estar fora do
âmbito pedido nesta ronda). Retenção do Prometheus: 15 dias
(`--storage.tsdb.retention.time`), ajustável em
`k8s/observability/prometheus.yaml` se entrarem mais serviços ou
métricas de alta cardinalidade.

**Nota de honestidade:** tal como o Keycloak, o dashboard do Grafana
(`k8s/observability/grafana.yaml`, ConfigMap
`grafana-dashboard-services`) foi escrito à mão com base no schema
conhecido de dashboards Grafana — os nomes de métricas usados
(`http_requests_total`, `http_request_duration_seconds_bucket`, com a
label `service` adicionada pelo relabelling do Prometheus) **foram
confirmados empiricamente** contra um `service-users` real a correr
localmente (`curl localhost:8002/metrics` depois de gerar tráfego) —
incluindo o detalhe de que `status` vem agrupado como `"2xx"/"4xx"/"5xx"`,
não como códigos exatos, e que os buckets de latência por omissão são
grosseiros (`[0.1, 0.5, 1.0, +Inf]`). O que continua por confirmar é o
próprio *layout*/renderização do dashboard num Grafana real (schema de
painéis, não os dados que os alimentam).

### Alertas (Grafana unified alerting)

Três regras provisionadas por ficheiro (`grafana-provisioning/alerting/`,
mesmo mecanismo dos dashboards — sobrevivem a um restart do pod e não
dependem de cliques na UI):

| Alerta | Dispara quando | Severidade |
|---|---|---|
| `high-error-rate-5xx` | >5% dos pedidos a um serviço devolvem 5xx (5 min) | warning |
| `slow-requests-ratio` | >5% dos pedidos a um serviço demoram mais de 1s (5 min) | warning |
| `service-down` | Prometheus deixa de conseguir fazer scrape a um serviço (2 min) | critical |

O alerta de latência usa "fração de pedidos acima de 1s" em vez de
`histogram_quantile(0.95, ...)` de propósito: com só 3 buckets finitos
(`0.1`, `0.5`, `1.0`), um p95 interpolado seria impreciso; a fração
acima de um limiar fixo é mais robusta com buckets tão grosseiros.

Todas as regras notificam o *contact point* `default-webhook`
(`grafana-provisioning/alerting/contactpoints.yml`) — **um placeholder**
(`https://example.com/...`) que nunca vai receber nada. Antes de
depender disto, substitui pelo endpoint real (Slack incoming webhook,
PagerDuty, Opsgenie, ou SMTP configurado no próprio Grafana) e confirma
que a `NetworkPolicy` `allow-grafana-egress-to-prometheus` (que também
liberta egress HTTPS genérico para o contact point) cobre o destino
certo — trocar `to: []` por um `ipBlock` específico assim que souberes
qual é.

**Nota de honestidade:** ao contrário do realm-export.json do Keycloak
(validado contra uma instância real nesta mesma iteração), **este
provisioning de alertas não foi validado contra um Grafana a sério** —
tentei obter o binário standalone do Grafana da mesma forma que fiz com
o Keycloak (GitHub Releases), mas os binários do Grafana só são
distribuídos via grafana.com/dl.grafana.com, fora dos domínios de rede
permitidos no ambiente onde isto foi produzido. O esquema de
provisioning de alertas (`condition`, os nós `data`/`datasourceUid:
__expr__`/`type: threshold`) já mudou de forma não totalmente
compatível entre versões do Grafana no passado. Antes de confiar nisto:

```bash
docker compose up -d grafana
# esperar ~15-20s, depois abrir http://localhost:3000 (admin / admin_dev_password)
# Alerting -> Alert rules: confirmar que as 3 regras aparecem e "Evaluate" sem erro
# Alerting -> Contact points: confirmar que "default-webhook" aparece
```

Cada linha de log dos dois serviços sai em JSON com `trace_id`/`span_id`
do span OpenTelemetry ativo (`app/logging_setup.py`), o que permite:
- a partir de uma linha de erro nos logs, saltar diretamente para o
  trace completo do pedido no Jaeger, pesquisando por `trace_id`;
- a partir de um trace lento no Jaeger, encontrar todas as linhas de
  log emitidas por qualquer um dos dois serviços durante esse pedido,
  fazendo `grep` ao mesmo `trace_id` (ou, num cluster real, pesquisando
  esse campo num agregador como Loki/ELK — não incluído neste projeto).

```bash
kubectl -n staging logs deploy/service-orders | grep '"trace_id": "4bf92f..."'
```

## Horizontal Pod Autoscaler (HPA)

O chart usa `autoscaling/v2` e cria um `HorizontalPodAutoscaler` por
microserviço quando `autoscaling.enabled` está ativo. Em produção está
ativo, com mínimo de 2 réplicas e máximos de 6 (`service-users`) e 8
(`service-orders`); em staging mantém-se desativado para controlar custos.

O cluster tem de ter o `metrics-server` operacional. As métricas de CPU são
calculadas a partir dos `resources.requests`, que já estão definidos para os
dois workloads. A política permite crescimento rápido e aplica uma janela de
estabilização de 5 minutos no scale-down, reduzindo oscilações.

```bash
kubectl get hpa -n production
kubectl describe hpa service-orders -n production
```

Para ajustar os limites ou thresholds, usa um override por ambiente:

```yaml
serviceOrders:
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70
    targetMemoryUtilizationPercentage: 80
```

**Nota de honestidade:** este chart foi construído e revisto manualmente,
mas não foi possível correr `helm lint`/`helm template` num Helm real no
ambiente onde foi produzido (o binário do Helm não está acessível nos
domínios de rede permitidos nesse ambiente — validei apenas o
balanceamento de chavetas `{{ }}` de cada template alterado e uma
inspeção linha a linha). Isto aplica-se a todos os templates desta
iteração (`secret-auth.yaml`, `networkpolicy.yaml` dos três namespaces).
O Keycloak em si já foi validado contra uma instância real (ver
"Keycloak — validado contra uma instância real" acima); o dashboard do
Grafana continua por validar da mesma forma. Corre `helm lint` e
`helm template --debug` antes do primeiro `helm upgrade --install` real.

## O que muda entre staging e produção (e só aqui)

| | staging | produção |
|---|---|---|
| Réplicas (cada serviço) | 1 | 2 |
| Tag de imagem | `stg` | `main` |
| `Service` de service-orders | `ClusterIP` | `NodePort` (30001) |
| Armazenamento do Postgres | 1Gi | 5Gi |
| `PodDisruptionBudget` | desativado | ativado |
| HPA | desativado | ativo (2–6 users, 2–8 orders) |
