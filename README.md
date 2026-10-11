# Plataforma de Gestão de Clientes e Encomendas

Este documento é um **tutorial**: seguindo os passos por ordem, fica com a aplicação a funcionar em cada ambiente e sabe onde entrar e com que credenciais.

- [1. O que é a aplicação](#1-o-que-é-a-aplicação)
- [2. Antes de começar](#2-antes-de-começar)
- [3. Tutorial DEV — no seu computador](#3-tutorial-dev--no-seu-computador)
- [4. Tutorial STG — ambiente de testes](#4-tutorial-stg--ambiente-de-testes)
- [5. Tutorial PRD — produção com HTTPS](#5-tutorial-prd--produção-com-https)
- [6. Resumo de acessos e credenciais](#6-resumo-de-acessos-e-credenciais)
- [7. Como usar o site de gestão](#7-como-usar-o-site-de-gestão)
- [8. Como usar o Grafana, o Prometheus e o Jaeger](#8-como-usar-o-grafana-o-prometheus-e-o-jaeger)
- [9. Parar e limpar](#9-parar-e-limpar)
- [10. Referência técnica](#10-referência-técnica)

---

## 1. O que é a aplicação

É o sistema de **gestão de clientes e encomendas** de uma empresa de encomendas. Os funcionários usam um **site de gestão** (backoffice) para:

- **criar, consultar, editar e apagar clientes**;
- **criar, consultar, editar e apagar encomendas**, sempre associadas a um cliente.

A mesma informação fica disponível, de forma segura, para outras aplicações da empresa (loja online, app móvel) através de uma API.

**Mais-valia para a empresa**

- **Lançar depressa e com segurança** — cada alteração é testada e publicada automaticamente em três ambientes (DEV → STG → PRD). O que chega a produção é exatamente o que foi validado antes.
- **Crescer sem refazer** — em produção cada serviço escala sozinho com a carga e continua disponível se uma réplica falhar.
- **Dados protegidos** — em produção há uma única porta de entrada, em HTTPS, e tudo exige login.
- **Problemas visíveis cedo** — erros, tempos de resposta e disponibilidade em tempo real, com alertas.

### Os três ambientes

| Ambiente | Onde corre | Para que serve |
|---|---|---|
| **DEV** | Docker Compose, no computador | Desenvolver e experimentar |
| **STG** | Kubernetes (MicroK8s), namespace `staging` | **Testar**: só o que passa aqui segue para produção |
| **PRD** | Kubernetes (MicroK8s), namespace `production` | Servir a empresa, em **HTTPS**. Não se constrói nem se testa aqui |

### As peças

| Peça | Função |
|---|---|
| **web** | O site de gestão que os funcionários abrem no browser |
| **service-users** | API dos clientes |
| **service-orders** | API das encomendas |
| **PostgreSQL** | Base de dados |
| **Keycloak** | Login e permissões |
| **Prometheus** | Recolhe métricas |
| **Grafana** | Dashboards e alertas |
| **Jaeger** | Mostra o percurso de cada pedido entre os serviços |

![Arquitetura (HLD)](docs/hld.png)

O diagrama editável está em `docs/hld.drawio`.

---

## 2. Antes de começar

### 2.1 O que tem de estar instalado

| Para | É preciso |
|---|---|
| DEV | Docker com Compose v2, `make`, Python 3.12 (`python3`) |
| STG e PRD | O anterior + MicroK8s, Helm, `openssl`, `fuser` (pacote `psmisc`) |

Preparar o MicroK8s (só uma vez):

```bash
sudo snap install microk8s --classic
```

```bash
sudo microk8s enable dns hostpath-storage metrics-server
```

Não é preciso configurar o Helm à mão: o `make` gera sozinho o ficheiro de acesso ao cluster (`kubeconfig-make.yaml`) antes de cada deploy.

### 2.2 Obter o projeto

```bash
git clone git@github.com:Kunami264/projeto-final-devops.git
```

```bash
cd projeto-final-devops
```

### 2.3 Como funcionam os comandos

Tudo se faz com `make`. Cada ambiente tem os mesmos passos:

```text
DEV:  make build-dev → make run-dev → make test-dev
STG:  make build-stg → make run-stg → make test-stg
PRD:  make build-prd → make run-prd
```

`make help` mostra a lista completa.

---

## 3. Tutorial DEV — no seu computador

### Passo 1 — Construir

```bash
make build-dev
```

Cria o ambiente virtual Python (`.venv`) e constrói as imagens Docker.

### Passo 2 — Arrancar

```bash
make run-dev
```

Quando termina, mostra no terminal todos os endereços e credenciais. Para os voltar a ver: `make info-dev`.

### Passo 3 — Abrir o site de gestão

Abrir **<http://localhost:8000>** e entrar com:

| Utilizador | Password |
|---|---|
| `admin` | `admin` |

Para criar, editar e apagar clientes e encomendas, ver a [secção 7](#7-como-usar-o-site-de-gestão).

### Passo 4 — Abrir as ferramentas de monitorização

| Ferramenta | Endereço | Utilizador | Password |
|---|---|---|---|
| **Grafana** | <http://localhost:3000> | `admin` | `admin` |
| **Prometheus** | <http://localhost:9090> | abre diretamente, não pede login | |
| **Jaeger** | <http://localhost:16686> | abre diretamente, não pede login | |

O que ver em cada uma está na [secção 8](#8-como-usar-o-grafana-o-prometheus-e-o-jaeger).

### Passo 5 — Correr os testes unitários

```bash
make test-dev
```

### Passo 6 — (opcional) Demonstração automática

```bash
make demo-dev
```

Faz login e cria, edita e apaga um cliente e uma encomenda, mostrando cada passo no terminal.

### Passo 7 — Parar

```bash
make stop-dev
```

Para os contentores e mantém os dados. Para apagar tudo, ver a [secção 9](#9-parar-e-limpar).

---

## 4. Tutorial STG — ambiente de testes

STG corre no Kubernetes e não fica exposto para fora do cluster. Acede-se por *port-forward*: um comando que fica a correr num terminal enquanto se usa o browser.

### Passo 1 — Construir

```bash
make build-stg
```

Constrói as imagens **já com todos os pacotes instalados**, carrega-as no MicroK8s e instala no `.venv` os módulos de teste.

### Passo 2 — Arrancar

```bash
make run-stg
```

Instala o Keycloak, o Prometheus, o Grafana, o Jaeger e a aplicação.

### Passo 3 — Testar o ambiente

```bash
make test-stg
```

Corre os testes de integração e os *smoke tests*. **Só se avança para PRD se passarem.**

### Passo 4 — Abrir o site de gestão

Num terminal, deixar a correr:

```bash
make forward-stg
```

Abrir **<http://localhost:8100>** e entrar com:

| Utilizador | Password |
|---|---|
| `admin` | `admin` |

`Ctrl+C` no terminal termina o acesso.

### Passo 5 — Abrir as ferramentas de monitorização

Noutro terminal, deixar a correr:

```bash
make forward-infra
```

| Ferramenta | Endereço | Utilizador | Password |
|---|---|---|---|
| **Grafana** | <http://localhost:3100> | `admin` | `admin` |
| **Prometheus** | <http://localhost:9190> | abre diretamente, não pede login | |
| **Jaeger** | <http://localhost:17686> | abre diretamente, não pede login | |

### Passo 6 — (opcional) Demonstração automática

```bash
make demo-stg
```

---

## 5. Tutorial PRD — produção com HTTPS

Em produção **não se constrói nem se testa**: promove-se a imagem que foi construída e validada em STG e faz-se apenas o arranque. Por isso é rápido.

### Passo 1 — Promover as imagens de STG

```bash
make build-prd
```

Não reconstrói nem instala pacotes: reutiliza as imagens de STG. Se elas não existirem, o comando recusa-se a avançar e pede para fazer primeiro os passos de STG.

### Passo 2 — Arrancar

```bash
make run-prd
```

Cria o certificado TLS, ativa o ponto de entrada HTTPS e arranca a aplicação. No fim mostra o estado dos serviços.

### Passo 3 — Dar nome ao endereço (só uma vez)

O site de produção responde em `projeto-final.test`. Na máquina onde corre o cluster:

```bash
echo '127.0.0.1 projeto-final.test' | sudo tee -a /etc/hosts
```

### Passo 4 — Abrir o site de gestão

Abrir **<https://projeto-final.test/>** e entrar com:

| Utilizador | Password |
|---|---|
| `admin` | `admin` |

O certificado é *self-signed*, por isso o browser mostra um aviso na primeira visita: escolher *Avançadas → Continuar*. Com um domínio real usa-se um certificado emitido por uma autoridade (cert-manager, em `helm/values-production.yaml`).

Quem escrever `http://` é redirecionado automaticamente para `https://`.

### Passo 5 — Abrir as ferramentas de monitorização

As ferramentas de monitorização são partilhadas por STG e PRD e, por segurança, não estão expostas para fora do cluster. Num terminal, deixar a correr:

```bash
make forward-infra
```

| Ferramenta | Endereço | Utilizador | Password |
|---|---|---|---|
| **Grafana** | <http://localhost:3100> | `admin` | `admin` |
| **Prometheus** | <http://localhost:9190> | abre diretamente, não pede login | |
| **Jaeger** | <http://localhost:17686> | abre diretamente, não pede login | |

### Passo 6 — Ver o estado de produção

```bash
make status-prd
```

Mostra as réplicas, os *health-checks* e o escalonamento automático. Em PRD não há testes: a disponibilidade é garantida pelos *health-checks* do Kubernetes, por 2 réplicas mínimas de cada serviço e pelo escalonamento automático.

---

## 6. Resumo de acessos e credenciais

Em todos os casos onde é pedido login: utilizador **`admin`**, password **`admin`**.

| | DEV | STG | PRD |
|---|---|---|---|
| **Antes de abrir** | `make run-dev` | `make forward-stg` (site) e `make forward-infra` (ferramentas) | `make forward-infra` (só para as ferramentas) |
| **Site de gestão** — `admin` / `admin` | <http://localhost:8000> | <http://localhost:8100> | <https://projeto-final.test/> |
| **Grafana** — `admin` / `admin` | <http://localhost:3000> | <http://localhost:3100> | <http://localhost:3100> |
| **Prometheus** — sem login | <http://localhost:9090> | <http://localhost:9190> | <http://localhost:9190> |
| **Jaeger** — sem login | <http://localhost:16686> | <http://localhost:17686> | <http://localhost:17686> |
| **Keycloak** (administração) — `admin` / `admin` | <http://localhost:8080> | <http://localhost:8280> | <http://localhost:8280> |

Notas:

- O **Prometheus** e o **Jaeger** não têm ecrã de login: abrem diretamente. Em STG e PRD só são alcançáveis a partir da máquina do cluster, através do `make forward-infra`.
- O Grafana, o Prometheus, o Jaeger e o Keycloak do cluster são os mesmos para STG e PRD; por isso os endereços coincidem.
- **`admin` / `admin` são credenciais de demonstração.** Antes de usar com dados reais, alterar as passwords: a do site no Keycloak (ver 7.4), as do Grafana e do Keycloak nos respetivos ficheiros de `k8s/`. No pipeline, a password do Grafana de STG e PRD vem dos *Secrets* do GitHub.

---

## 7. Como usar o site de gestão

Funciona da mesma forma nos três ambientes; só muda o endereço (secção 6).

### 7.1 Entrar

Abrir o endereço, escrever `admin` / `admin` e clicar em **Entrar**. A sessão mantém-se enquanto a página estiver aberta; fechar ou recarregar a página termina-a.

### 7.2 Clientes

No separador **Clientes**:

| Para… | Fazer |
|---|---|
| **Criar** | Clicar em **Novo cliente**, preencher *Nome* e *Email*, **Guardar** |
| **Editar** | Clicar em **Editar** na linha do cliente, alterar, **Guardar** |
| **Apagar** | Clicar em **Apagar** na linha do cliente e confirmar |

Dois clientes não podem ter o mesmo email.

### 7.3 Encomendas

No separador **Encomendas**:

| Para… | Fazer |
|---|---|
| **Criar** | Clicar em **Nova encomenda**, escolher o *Cliente*, preencher *Artigo* e *Quantidade*, **Guardar** |
| **Editar** | Clicar em **Editar** na linha da encomenda, alterar o artigo ou a quantidade, **Guardar** |
| **Apagar** | Clicar em **Apagar** na linha da encomenda e confirmar |

Para criar uma encomenda tem de existir pelo menos um cliente. O cliente de uma encomenda não se altera depois de criada.

### 7.4 Criar contas para outros funcionários

Os "clientes" do site são os clientes da empresa. As contas de quem pode **entrar** no site gerem-se no Keycloak:

1. Abrir a administração do Keycloak (endereço na secção 6) e entrar com `admin` / `admin`
2. No canto superior esquerdo, escolher o realm **projeto-final**
3. *Users* → *Add user* → preencher o *Username* → *Create*
4. No separador *Credentials* → *Set password* → desligar *Temporary* → *Save*

Para alterar a password da conta `admin` do site: mesmo realm, *Users* → `admin` → *Credentials* → *Reset password*.

---

## 8. Como usar o Grafana, o Prometheus e o Jaeger

Para haver dados para ver, usar primeiro o site durante uns minutos ou correr `make demo-dev` algumas vezes.

### 8.1 Grafana — dashboards e alertas

1. Abrir o endereço e entrar com `admin` / `admin` (se pedir para mudar a password, pode escolher *Skip*)
2. Menu **Dashboards** → **service-users / service-orders — visão geral**

O dashboard mostra, por serviço: pedidos por segundo, percentagem de erros, tempo de resposta (mediana e percentil 95) e pedidos por operação.

Em **Alerting → Alert rules** estão três alertas já configurados: taxa de erros elevada, respostas lentas e serviço em baixo.

### 8.2 Prometheus — métricas

1. Abrir o endereço (não pede login)
2. **Status → Targets**: os dois serviços devem aparecer como `UP`
3. No separador **Graph**, experimentar a consulta:

```text
sum(rate(http_requests_total[5m])) by (service)
```

### 8.3 Jaeger — percurso dos pedidos

1. Abrir o endereço (não pede login)
2. Em *Service*, escolher **service-orders** e clicar em **Find Traces**
3. Abrir um pedido `POST /orders`: vê-se a encomenda a chegar ao service-orders e este a confirmar o cliente no service-users, com o tempo gasto em cada passo

---

## 9. Parar e limpar

| Comando | O que faz |
|---|---|
| `make stop-dev` / `make stop-stg` / `make stop-prd` | Para o ambiente; mantém dados e imagens |
| `make clean-dev` | Remove contentores, volumes, rede e imagens do Compose, o `.venv` e ficheiros temporários |
| `make clean-stg` | Remove a aplicação, o namespace `staging` (dados incluídos) e as imagens de STG |
| `make clean-prd` | Remove a aplicação, o namespace `production`, o certificado e as imagens de PRD |
| `make clean-infra` | Remove Keycloak, Prometheus, Grafana e Jaeger do cluster |
| **`make clean`** | **Remove tudo o que está acima** |

Depois de `make clean` não fica nenhum recurso do projeto no cluster nem na máquina. O MicroK8s continua instalado; para o parar: `sudo snap stop microk8s`.

### Problemas frequentes

| Mensagem | Causa e solução |
|---|---|
| `kubernetes cluster unreachable: the server could not find the requested resource` | O Helm não sabia onde está o cluster e foi bater à porta 8080 (o Keycloak de DEV). Está resolvido: `run-stg` e `run-prd` geram o acesso ao cluster automaticamente. Se usar o `helm` à mão, acrescentar `--kubeconfig kubeconfig-make.yaml` (depois de `make kubeconfig`) |
| `Não foi possível obter o kubeconfig do cluster` | O MicroK8s não está a correr: `sudo snap start microk8s` e `sudo microk8s status --wait-ready` |
| `401 Unauthorized` no login do site ou nos testes (`make test-stg`), depois de atualizar o projeto | O Keycloak do cluster ainda tem as contas da versão anterior (ver a nota seguinte). Correr `make reset-keycloak` e repetir |

> O Keycloak só lê as contas e permissões iniciais no primeiro arranque e guarda-as em disco. Depois de atualizar o projeto ou de alterar `k8s/auth/realm-export.json`: no cluster, correr `make reset-keycloak`; em DEV, `make clean-dev` e voltar a subir. Atenção: isto apaga as contas criadas à mão no Keycloak.

---

## 10. Referência técnica

### 10.1 Dependências Python por ambiente

O de **PRD é o mais limpo**: só o que é preciso para executar. Os módulos de teste existem apenas em STG e DEV.

| Ficheiro | Ambiente | Conteúdo |
|---|---|---|
| `requirements-prd.txt` | **PRD** | Só *runtime*. Sem `pytest` nem módulos de teste. É o que as imagens Docker instalam |
| `requirements-stg.txt` | STG | Módulos de teste (`pytest`, `httpx`) para integração e *smoke* |
| `requirements-dev.txt` | DEV | `requirements-prd.txt` + `requirements-stg.txt` |

Cada serviço tem o seu `service-*/requirements-prd.txt` (o que o `Dockerfile` instala) e `service-*/requirements-dev.txt`.

Como isto garante um PRD rápido:

1. `make build-stg` constrói a imagem **uma vez**, com todos os pacotes de PRD instalados — e só esses.
2. `make test-stg` valida essa imagem; os módulos de teste ficam no `.venv`, fora da imagem.
3. `make build-prd` não instala nada: promove a mesma imagem (`stg` → `main`).
4. `make run-prd` faz só o arranque.

O ambiente virtual é criado com `python -m venv .venv` pelos comandos `build-dev` e `build-stg`.

### 10.2 Testes

| Tipo | Onde corre | Localização | N.º |
|---|---|---|---|
| Unitários | DEV | `service-users/tests` | 23 |
| Unitários | DEV | `service-orders/tests` | 19 |
| Integração | STG | `tests/integration` | 12 |
| Smoke | STG | `tests/smoke` | 3 |
| **Total** | | | **57** |

### 10.3 Pipeline (GitHub Actions)

A promoção segue as branches `dev → stg → main` (`.github/workflows/pipeline.yml`):

| Branch | Passos |
|---|---|
| `dev` | Análise de segurança (Trivy) → build e publicação das imagens → testes unitários → deploy DEV |
| `stg` | Trivy → build e publicação → testes de integração → deploy STG → **integração + smoke contra o cluster** |
| `main` | Trivy → **promoção da imagem de STG** (sem novo build) → aprovação manual → deploy PRD com HTTPS → verificação dos *health-checks* |

A limpeza dos ambientes é manual (`.github/workflows/cleanup.yml`).

### 10.4 API (para integração com outras aplicações)

Todos os pedidos levam um token no cabeçalho `Authorization: Bearer <token>`. Em DEV e STG há documentação interativa (Swagger) em `/docs` de cada serviço — por exemplo <http://localhost:8002/docs>; `make token-dev` imprime um token para colar em *Authorize*.

| Operação | Pedido | Permissão | Resposta |
|---|---|---|---|
| Listar clientes | `GET /users` | `users:read` | 200 |
| Consultar cliente | `GET /users/{id}` | `users:read` | 200 / 404 |
| Criar cliente | `POST /users` `{name, email}` | `users:write` | 201 / 409 / 422 |
| Editar cliente | `PUT /users/{id}` `{name, email}` | `users:write` | 200 / 404 / 409 / 422 |
| Apagar cliente | `DELETE /users/{id}` | `users:write` | 204 / 404 |
| Listar encomendas | `GET /orders` | `orders:read` | 200 |
| Consultar encomenda | `GET /orders/{id}` | `orders:read` | 200 / 404 |
| Criar encomenda | `POST /orders` `{user_id, item, quantity}` | `orders:write` | 200 / 404 / 422 |
| Editar encomenda | `PUT /orders/{id}` `{item, quantity}` | `orders:write` | 200 / 404 / 422 |
| Apagar encomenda | `DELETE /orders/{id}` | `orders:write` | 204 / 404 |

Exemplo com `curl` em DEV (em PRD, trocar os três endereços por `https://projeto-final.test`):

```bash
TOKEN=$(curl -sk http://localhost:8080/realms/projeto-final/protocol/openid-connect/token \
  -d grant_type=password -d client_id=api-cli -d client_secret=troque-este-segredo-api-cli \
  -d username=admin -d password=admin \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["access_token"])')
```

```bash
curl -sk -X POST http://localhost:8002/users -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" -d '{"name": "Maria Sousa", "email": "maria.sousa@example.com"}'
```

```bash
curl -sk -X POST http://localhost:8001/orders -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" -d '{"user_id": 1, "item": "Teclado", "quantity": 2}'
```

### 10.5 Ajustar sem editar o Makefile

```bash
make build-dev PYTHON=python3.12
```

```bash
make run-prd PRD_HOST=encomendas.minhaempresa.pt
```

Noutro cluster que não o MicroK8s, o *Ingress controller* indica-se com `INGRESS_CLASS` e `INGRESS_NS` (por omissão `public` e `ingress`).

### 10.6 Estrutura do repositório

```text
├── .github/workflows/      pipeline.yml (CI/CD) · cleanup.yml (limpeza manual)
├── web/                    site de gestão: static/ (HTML, CSS, JS) · nginx.conf.template · Dockerfile
├── service-users/          app/ · tests/ · Dockerfile · requirements-prd.txt · requirements-dev.txt
├── service-orders/         app/ · tests/ · Dockerfile · requirements-prd.txt · requirements-dev.txt
├── tests/                  integration/ · smoke/   (correm em STG)
├── helm/                   chart único · values-staging.yaml · values-production.yaml
├── k8s/                    auth/ (Keycloak) · observability/ · ingress/
├── scripts/                demo.py · get_token.py
├── docs/                   hld.png · hld.drawio (arquitetura)
├── docker-compose.yml      ambiente DEV
├── requirements-prd.txt    PRD: só runtime
├── requirements-stg.txt    STG: módulos de teste
├── requirements-dev.txt    DEV: prd + stg
└── Makefile                ponto de entrada
```
