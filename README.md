# Implementação do Pipeline de Entrega Contínua

## 1. Objetivo

Este projeto implementa uma aplicação Python baseada em microsserviços, com integração e entrega contínuas (CI/CD), testes automatizados, contentorização, orquestração Kubernetes e observabilidade.

A solução é constituída por dois microsserviços **FastAPI**:

- service-users — gestão de utilizadores;
- service-orders — gestão de encomendas.

Os serviços disponibilizam APIs HTTP com respostas em JSON. O service-orders comunica com o service-users através de HTTP/JSON e utiliza PostgreSQL para persistência. A autenticação e autorização são asseguradas pelo **Keycloak**, através de OIDC/JWT e scopes.

A observabilidade integra **OpenTelemetry, Jaeger, Prometheus e Grafana**.

O código é versionado com Git e disponibilizado no GitHub.



## 2. Arquitetura do pipeline

O pipeline é implementado com **GitHub Actions** e organiza a promoção da aplicação através das branches:


dev  →  stg  →  main
DEV     STG      PRD


| Ambiente | Branch | Execução | Validação |
|---|---|---|---|
| DEV | dev | Docker Compose | testes unitários + health checks |
| STG | stg | Kubernetes/MicroK8s + Helm | testes de integração |
| PRD | main | Kubernetes/MicroK8s + Helm | aprovação manual + smoke tests |

Fluxo simplificado:


Push / Pull Request
        ↓
Análise de segurança (Trivy)
        ↓
Build Docker / Buildx
        ↓
Publicação no GHCR
        ↓
Testes automatizados
        ↓
Deploy no ambiente correspondente
        ↓
Validação pós-deploy


As imagens são construídas para linux/amd64 e linux/arm64 (no meu caso pessoal uso arm64) e identificadas através do SHA do commit.

O workflow principal encontra-se em .github/workflows/pipeline.yml.



## 3. Estrutura da solução

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
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── values-staging.yaml
│   ├── values-production.yaml
│   └── templates/
├── k8s/
│   ├── auth/
│   └── observability/
├── scripts/
├── docker-compose.yml
├── Makefile
├── pytest.ini
├── requirements.txt
└── Arquitetura-ProjetoFinal.drawio


O Makefile constitui o principal ponto de entrada para build, testes, deploy, validação e limpeza, localmente.



## 4. Implementação, build, teste e deploy

### 4.1 Preparação

bash
git clone git@github.com:Kunami264/projeto-final-devops.git
cd projeto-final-devops
python3.12 -m venv venv
source venv/bin/activate
pip install -r requirements.txt


A promoção da aplicação segue dev → stg → main.


### 4.2 Microsserviços

O service-users disponibiliza operações de gestão de utilizadores e o service-orders disponibiliza operações de gestão de encomendas. Ambos expõem, entre outros, /health e /metrics.

A criação de uma encomenda implica a validação do utilizador através de uma chamada HTTP entre os microsserviços:

Cliente → service-orders → service-users → PostgreSQL

Cada microsserviço possui um Dockerfile próprio.


### 4.3 Autenticação e autorização

O Keycloak fornece a identidade e os tokens JWT. As APIs validam autenticação, emissor, validade e scopes, incluindo:

users:read
orders:read
orders:write


### 4.4 DEV — Docker Compose

O ambiente DEV é executado com:

bash
make up

São iniciados os microsserviços, PostgreSQL, Keycloak e a stack de observabilidade.

A disponibilidade dos serviços pode ser verificada com:

bash
curl http://localhost:8002/health
curl http://localhost:8001/health

Os testes unitários são executados com:

bash
make test-unit

A validação do ambiente pode ser realizada com:

bash
make validate-dev


### 4.5 STG — Kubernetes/MicroK8s

A disponibilidade do cluster é verificada com:

bash (verificar o estado do microk8s -> iniciar com sudo snap start microk8s)
sudo snap run microk8s status --wait-ready
sudo snap run microk8s kubectl get nodes


Antes do deploy são validados os templates Helm:

bash
make helm-template-staging
helm lint ./helm -f ./helm/values-staging.yaml


O deploy é realizado com:

bash
make helm-install-staging

A validação completa é executada com:

bash
make validate-stg


Esta validação inclui rollout dos deployments e testes de integração.


### 4.6 PRD — Kubernetes/MicroK8s

Os templates de produção são validados com:

bash
make helm-template-production


O deploy é realizado com:

bash
make helm-install-production
make wait-prd-healthy


O namespace utilizado pela configuração atual é production. No GitHub Actions, o deploy PRD requer aprovação manual através de um GitHub Environment protegido.

Após o deploy são executados os smoke tests:

bash
make test-smoke-prd


ou (para validação completa do ambiente):

bash
make validate-prd



## 5. Testes automatizados

O projeto utiliza **Pytest** em três níveis:

| Tipo | Localização | Nº de testes | Objetivo |
| Unitários | service-users/tests | 11 | validação do service-users |
| Unitários | service-orders/tests | 12 | validação do service-orders |
| Integração | tests/integration | 7 | comunicação entre componentes |
| Smoke | tests/smoke | 2 | disponibilidade pós-deploy |
| **Total** | | **32** | |

Os testes de integração validam, entre outros aspetos, Keycloak, os dois microsserviços, métricas e comunicação end-to-end. Os smoke tests verificam a disponibilidade dos serviços em produção.

O número indicado corresponde aos testes definidos no código. As evidências dos testes encontra-se nas imagens com o passo 5.(...).



## 6. CI/CD e segurança

O GitHub Actions automatiza as fases de análise, build, teste e deploy.

O **Trivy** é utilizado para análise de vulnerabilidades do código/dependências e das imagens Docker. O build utiliza Docker Buildx para amd64 e arm64, seguindo-se a publicação no **GitHub Container Registry (GHCR)**.

A versão promovida é identificada pelo SHA do commit, permitindo associar cada ambiente a uma versão concreta do código.

As credenciais e configurações sensíveis são disponibilizadas através de **GitHub Secrets/Environments**, não sendo armazenadas diretamente no código-fonte.



## 7. Observabilidade

| Ferramenta | Função |
| OpenTelemetry | instrumentação e geração de traces |
| Jaeger | distributed tracing |
| Prometheus | recolha de métricas |
| Grafana | visualização e dashboards |

Os microsserviços expõem métricas em /metrics e utilizam OpenTelemetry para rastreamento das transações, incluindo a comunicação entre service-orders e service-users.



## 8. Problemas identificados e soluções

### Execução do MicroK8s

Foi necessário utilizar privilégios elevados para os comandos Kubernetes e iniciar o microk8s localmente antes de fazer um push para o GitHub Actions. O Makefile define:

make
KUBECTL := sudo snap run microk8s kubectl


### Conflitos de portas

Foram identificados conflitos entre serviços Docker e Kubernetes. A solução consistiu na separação das portas por ambiente e na utilização de kubectl port-forward durante as validações.


### PostgreSQL em Kubernetes

Foram identificados problemas de permissões no armazenamento persistente. A configuração do volume e das permissões foi ajustada para permitir a inicialização do PostgreSQL.


### NodePort

Foram identificados conflitos de NodePort. A utilização de ClusterIP e port-forward reduziu a dependência de portas externas.


### Namespaces

O namespace PRD atualmente utilizado é production. O namespace prd pode existir apenas como resultado de execuções anteriores e deve ser verificado durante a limpeza.



## 9. Evidências de validação (Encontra-se nas fotos enviadas as evidências dos testes realizados remotamente e localmente)

make test-unit
make validate-dev
make validate-stg
make validate-prd


- execução dos testes unitários
- execução dos testes de integração;
- execução dos smoke tests;
- deploy nos ambientes
- métricas do Prometheus;
- traces do Jaeger;
- dashboard do Grafana.



## 10. Paragem, destruição e limpeza


### 10.1 DEV

bash
make down


### 10.2 MicroK8s e limpeza local

bash
sudo snap stop microk8s
make clean


Pode ainda ser utilizado:

bash
make destroy

