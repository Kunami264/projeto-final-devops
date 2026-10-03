# Implementação do Pipeline de Entrega Contínua

## 1. Objetivo

Este projeto implementa uma aplicação Python baseada em microsserviços, com integração e entrega contínuas (CI/CD), testes automatizados, contentorização, orquestração Kubernetes e observabilidade.

A solução é constituída por dois microsserviços **FastAPI**:

- service-users - gestão de utilizadores;
- service-orders - gestão de encomendas.

Os serviços disponibilizam APIs HTTP com respostas em JSON.

O service-orders comunica com o service-users através de HTTP/JSON e utiliza PostgreSQL para persistência.

A autenticação e autorização são asseguradas pelo **Keycloak**, através de OIDC/JWT e scopes.

A observabilidade integra **OpenTelemetry, Jaeger, Prometheus e Grafana**.

O código é versionado com Git e disponibilizado no GitHub.

---

## 2. Arquitetura do Pipeline

O pipeline é implementado com **GitHub Actions** e organiza a promoção da aplicação através das branches:

```text
dev → stg → main
```

| Ambiente | Branch | Execução | Validação |
|-----------|-----------|-----------|-----------|
| DEV | dev | Docker Compose | Testes unitários + Health Checks |
| STG | stg | Kubernetes/MicroK8s + Helm | Testes de Integração |
| PRD | main | Kubernetes/MicroK8s + Helm | Aprovação manual + Smoke Tests |

### Fluxo Simplificado

```text
Push / Pull Request
        ↓
Análise de Segurança (Trivy)
        ↓
Build Docker / Buildx
        ↓
Publicação no GHCR
        ↓
Testes Automatizados
        ↓
Deploy no Ambiente Correspondente
        ↓
Validação Pós-Deploy
```

As imagens são construídas para Linux/amd64 e Linux/arm64 e identificadas através do SHA do commit.

O workflow principal encontra-se em:

```text
.github/workflows/pipeline.yml
```

---

## 3. Estrutura da Solução

```text
ProjetoFinal/
├── .github/
│   └── workflows/
│       └── pipeline.yml
├── service-users/
│   ├── app/
│   ├── tests/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── requirements-dev.txt
├── service-orders/
│   ├── app/
│   ├── tests/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── requirements-dev.txt
├── tests/
│   ├── integration/
│   │   └── test_integration.py
│   └── smoke/
│       └── test_smoke.py
├── helm/
├── k8s/
├── scripts/
├── docker-compose.yml
├── Makefile
├── pytest.ini
├── requirements.txt
└── Arquitetura-ProjetoFinal.drawio
```

O Makefile constitui o principal ponto de entrada para build, testes, deploy, validação e limpeza local.

---

## 4. Implementação, Build, Teste e Deploy

### 4.1 Preparação

```bash
git clone git@github.com:Kunami264/projeto-final-devops.git

cd projeto-final-devops

python3.12 -m venv venv
source venv/bin/activate

pip install -r requirements.txt
```

A promoção da aplicação segue:

```text
dev → stg → main
```

### 4.2 Microsserviços

O service-users disponibiliza operações de gestão de utilizadores.

O service-orders disponibiliza operações de gestão de encomendas.

Ambos expõem endpoints como:

```text
/health
/metrics
```

Fluxo de criação de encomenda:

```text
Cliente
   ↓
service-orders
   ↓
service-users
   ↓
PostgreSQL
```

Cada microsserviço possui um Dockerfile próprio.

### 4.3 Autenticação e Autorização

O Keycloak fornece identidade e tokens JWT.

As APIs validam:

- autenticação;
- emissor;
- validade do token;
- scopes.

Scopes utilizados:

```text
users:read
orders:read
orders:write
```

### 4.4 DEV - Docker Compose

Execução:

```bash
make up
```

Validação de disponibilidade:

```bash
curl http://localhost:8002/health
curl http://localhost:8001/health
```

Testes unitários:

```bash
make test-unit
```

Validação completa:

```bash
make validate-dev
```

### 4.5 STG - Kubernetes/MicroK8s

Verificação do cluster:

```bash
sudo snap start microk8s

sudo snap run microk8s status --wait-ready
sudo snap run microk8s kubectl get nodes
```

Validação dos templates Helm:

```bash
make helm-template-staging

helm lint ./helm -f ./helm/values-staging.yaml
```

Deploy:

```bash
make helm-install-staging
```

Validação:

```bash
make validate-stg
```

### 4.6 PRD - Kubernetes/MicroK8s

Validação de templates:

```bash
make helm-template-production
```

Deploy:

```bash
make helm-install-production
make wait-prd-healthy
```

Smoke tests:

```bash
make test-smoke-prd
```

Validação completa:

```bash
make validate-prd
```

---

## 5. Testes Automatizados

O projeto utiliza **Pytest** em três níveis:

| Tipo | Localização | Nº Testes | Objetivo |
|--------|--------|--------|--------|
| Unitários | service-users/tests | 11 | Validação do service-users |
| Unitários | service-orders/tests | 12 | Validação do service-orders |
| Integração | tests/integration | 7 | Comunicação entre componentes |
| Smoke | tests/smoke | 2 | Disponibilidade pós-deploy |
| **Total** |  | **32** | |

Os testes de integração validam:

- Keycloak;
- microsserviços;
- métricas;
- comunicação end-to-end.

---

## 6. CI/CD e Segurança

O GitHub Actions automatiza:

- Análise;
- Build;
- Testes;
- Deploy.

O **Trivy** é utilizado para:

- análise de vulnerabilidades de dependências;
- análise de imagens Docker.

O build utiliza:

```text
Docker Buildx
```

para:

```text
linux/amd64
linux/arm64
```

As imagens são publicadas no:

```text
GitHub Container Registry (GHCR)
```

---

## 7. Observabilidade

| Ferramenta | Função |
|------------|---------|
| OpenTelemetry | Instrumentação e geração de traces |
| Jaeger | Distributed Tracing |
| Prometheus | Recolha de métricas |
| Grafana | Visualização e dashboards |

Os microsserviços expõem métricas através de:

```text
/metrics
```

---

## 8. Problemas Identificados e Soluções

### Execução do MicroK8s

```makefile
KUBECTL := sudo snap run microk8s kubectl
```

### Conflitos de Portas

Solução:

- Separação de portas por ambiente;
- Utilização de `kubectl port-forward`.

### PostgreSQL em Kubernetes

Problema resolvido através de:

- Ajuste de volumes persistentes;
- Correção de permissões.

### NodePort

Solução:

- Utilização de ClusterIP;
- Port Forwarding.

### Namespaces

Namespace atualmente utilizado em produção:

```text
production
```

---

## 9. Evidências de Validação

```bash
make test-unit
make validate-dev
make validate-stg
make validate-prd
```

Evidências apresentadas:

- Testes unitários;
- Testes de integração;
- Smoke tests;
- Deploys;
- Métricas Prometheus;
- Traces Jaeger;
- Dashboards Grafana.

---

## 10. Paragem, Destruição e Limpeza

### 10.1 DEV

```bash
make down
```

### 10.2 MicroK8s

```bash
sudo snap stop microk8s

make clean
```

Destruição completa:

```bash
make destroy
```

