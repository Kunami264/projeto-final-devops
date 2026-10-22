# Processo de implementação, decisões de design, ferramentas e bibliotecas Python

Plataforma de Gestão de Clientes e Encomendas — Projeto Final de DevOps — Daniel Almeida, Tokio School

## 1. Introdução

O presente documento descreve o processo de implementação da Plataforma de Gestão de Clientes e Encomendas, fundamenta as principais decisões de design e identifica as ferramentas e as bibliotecas Python utilizadas.

A plataforma permite a uma organização registar os seus clientes e as respetivas encomendas, através de um site de gestão destinado aos funcionários e de uma API REST, com respostas em JSON, destinada à integração com outras aplicações. A solução é entregue de forma automática em três ambientes — desenvolvimento (DEV), testes (STG) e produção (PRD) — e inclui autenticação centralizada e monitorização.

## 2. Arquitetura da solução

A solução é composta por três serviços aplicacionais executados em contentores — o site de gestão, a API de clientes e a API de encomendas —, por uma base de dados PostgreSQL, pelo Keycloak, responsável pela autenticação e autorização, e pelas ferramentas de monitorização Prometheus, Grafana e Jaeger (este último apenas em DEV e STG). A API de encomendas comunica com a API de clientes para validar o cliente associado a cada encomenda. A análise de vulnerabilidades do código é feita por um servidor SonarQube local, em Docker, que não faz parte da aplicação.

![Arquitetura de alto nível (HLD)](docs/hld.png)

*Figura 1 — Arquitetura de alto nível. O diagrama editável encontra-se em `docs/hld.drawio`.*

## 3. Processo de implementação

A implementação decorreu de forma incremental. Cada fase foi validada antes do início da seguinte, de modo a que os problemas fossem detetados na fase em que tiveram origem.

| Fase | Trabalho realizado |
|---|---|
| 1. Aplicação | Desenvolvimento de dois microsserviços em Python, com o FastAPI: clientes e encomendas, com as operações de criação, consulta, edição e eliminação. Persistência dos dados em PostgreSQL. |
| 2. Segurança da API | Integração com o Keycloak (OIDC/JWT). Cada pedido é validado quanto à autenticidade do *token* e à permissão exigida pela operação. |
| 3. Contentorização | Um Dockerfile por serviço. As imagens incluem apenas as dependências de execução e são executadas por um utilizador sem privilégios. |
| 4. Ambiente DEV | Ambiente local em Docker Compose, com todos os serviços, para desenvolvimento, testes unitários e testes de vulnerabilidades do código. |
| 5. Ambientes STG e PRD | Kubernetes (MicroK8s) com um único *chart* Helm e um ficheiro de valores por ambiente. Em PRD: réplicas, escalonamento automático e ponto de entrada único em HTTPS. |
| 6. Observabilidade | Métricas no Prometheus, painéis e alertas no Grafana e, em DEV e STG, rastreio distribuído dos pedidos no Jaeger, através do OpenTelemetry. |
| 7. Site de gestão | *Backoffice* web que permite aos funcionários gerir clientes e encomendas sem recorrer diretamente à API. |
| 8. Entrega contínua | Pipeline em GitHub Actions: análise de vulnerabilidades (código, dependências e imagens), construção das imagens, testes e *deploy*, segundo a ordem `dev`, `stg` e `main`. |
| 9. Consolidação | Separação estrita entre STG (onde tudo é construído, gerado e validado) e PRD (onde apenas se sobe o ambiente), limpeza integral dos ambientes e elaboração da documentação. |

## 4. Decisões de design

| Decisão | Fundamentação |
|---|---|
| Três ambientes com funções distintas | DEV destina-se ao desenvolvimento, STG à validação e PRD à exploração. Os testes de integração, *smoke* e de vulnerabilidades são executados em DEV e STG; em PRD não são executados testes, sendo a disponibilidade assegurada pelos *health-checks* do Kubernetes. DEV e STG não correm em simultâneo: `make build-stg` começa por limpar DEV (`make clean-dev`), libertando a memória da máquina para o cluster. |
| Em PRD nada é gerado | As imagens são construídas uma única vez em STG, com todas as dependências instaladas. O certificado TLS e o Ingress controller são igualmente preparados em STG. Só depois de os testes de STG passarem as imagens são promovidas para PRD, sem novo *build*. Em PRD apenas se sobe o ambiente, o que torna o arranque rápido e garante que é executado exatamente o que foi validado. |
| OpenTelemetry apenas em DEV e STG | O rastreio distribuído serve o diagnóstico durante o desenvolvimento e a validação. Em PRD os serviços não são instrumentados, evitando o custo de processamento e o volume de dados; a monitorização de produção faz-se por métricas (Prometheus) e alertas (Grafana). |
| Testes de vulnerabilidades em várias camadas | O SonarQube analisa o código Python e aplica o *quality gate* **Segurança**, que falha perante qualquer problema de segurança; é executado em DEV, em STG e em todas as execuções do pipeline (`make security`). O Trivy analisa as dependências e as imagens no pipeline, antes de qualquer construção ou promoção. |
| SonarQube local, a pedido | O SonarQube corre em Docker, no *profile* `sonar` do `docker-compose.yml`, fora da rede da aplicação. Só é iniciado por `make security`, pelo que não consome recursos durante a utilização normal de DEV. As análises ficam guardadas em volume e podem ser consultadas no painel. |
| Dependências separadas por ambiente | `requirements-prd.txt` contém apenas as dependências de execução. Os módulos de teste e de análise (`pytest`, `httpx`, `pysonar`) encontram-se em `requirements-stg.txt` e `requirements-dev.txt` e não são incluídos nas imagens. |
| Ponto de entrada único em HTTPS | Em PRD, um Ingress com TLS e redirecionamento de HTTP para HTTPS constitui o único acesso externo. Os serviços, a administração do Keycloak e as ferramentas de monitorização não são expostos. |
| Autenticação centralizada | O Keycloak assume a autenticação e a autorização, evitando que cada serviço gira credenciais. A configuração inicial é mantida em ficheiro, o que torna os ambientes reprodutíveis. |
| Rede restrita por omissão | As NetworkPolicies bloqueiam todo o tráfego no cluster e autorizam apenas as ligações necessárias entre componentes. |
| Isolamento por *namespace* | A aplicação, a identidade e a observabilidade residem em *namespaces* distintos. O Keycloak e a monitorização são partilhados por STG e PRD. |
| Persistência dos dados | A base de dados utiliza um volume persistente, que se mantém após o reinício dos serviços e a paragem do ambiente. Apenas os comandos de limpeza o eliminam. |
| *Chart* Helm único | O mesmo *chart* serve STG e PRD; as diferenças (réplicas, HTTPS, rastreio, recursos) residem nos ficheiros de valores. |
| Makefile como ponto de entrada | Os mesmos comandos em todos os ambientes (`build`, `run`, `test`, `clean`). O Makefile deteta o cluster e a variante do Docker Compose disponíveis e arranca o MicroK8s quando este se encontra parado. |
| Limpeza integral | `make clean` remove os recursos do projeto no cluster (aplicação, Keycloak, monitorização, Ingress controller e imagens) e aplica a limpeza Docker completa adotada nas aulas (`compose down -v --rmi all`, `system prune -af --volumes`, `volume`, `network` e `builder prune`), bem como o ambiente virtual, os certificados, os ficheiros de acesso ao cluster e a entrada no `/etc/hosts`. |
| Site de gestão sem *framework* | HTML, CSS e JavaScript servidos por nginx. É suficiente para as operações necessárias e não introduz etapas de construção nem dependências adicionais. |

## 5. Ferramentas utilizadas

| Ferramenta | Utilização |
|---|---|
| Python 3.12 | Linguagem dos microsserviços e dos testes |
| Docker e Docker Compose | Construção das imagens e ambiente DEV |
| Kubernetes (MicroK8s) | Orquestração dos ambientes STG e PRD |
| Helm | Instalação e atualização da aplicação no cluster |
| PostgreSQL 16 | Base de dados de clientes e encomendas |
| Keycloak 26 | Autenticação e autorização (OIDC) |
| nginx | Servidor do site de gestão e Ingress HTTPS em PRD |
| Prometheus e Grafana | Métricas, painéis e alertas (todos os ambientes) |
| Jaeger e OpenTelemetry | Rastreio distribuído (DEV e STG) |
| SonarQube Community 26.9 | Testes de vulnerabilidades do código Python (*quality gate* de segurança) |
| Trivy | Análise de vulnerabilidades das dependências e das imagens |
| GitHub Actions | Pipeline de integração e entrega contínuas |
| GitHub Container Registry | Registo das imagens |
| Make | Ponto de entrada único para todos os ambientes |
| Git e GitHub | Controlo de versões, com os ramos `dev`, `stg` e `main` |
| draw.io | Diagrama de arquitetura |

## 6. Bibliotecas Python

### 6.1 Execução (`requirements-prd.txt`)

| Biblioteca | Versão | Finalidade |
|---|---|---|
| fastapi | 0.120.1 | *Framework* web das duas API |
| uvicorn | 0.30.6 | Servidor de aplicações (ASGI) |
| pydantic | 2.12.5 | Validação dos dados recebidos |
| sqlalchemy | 2.0.35 | Acesso à base de dados (ORM) |
| psycopg2-binary | 2.9.11 | Ligação ao PostgreSQL |
| pyjwt | 2.14.0 | Validação dos *tokens* de autenticação |
| cryptography | 50.0.0 | Verificação da assinatura dos *tokens* |
| httpx | 0.27.2 | Comunicação entre a API de encomendas e a API de clientes |
| opentelemetry-api, -sdk e -exporter-otlp-proto-grpc | 1.39.1 | Geração e envio de *traces* para o Jaeger (ativo apenas em DEV e STG) |
| opentelemetry-instrumentation-fastapi e -httpx | 0.60b1 | Rastreio automático dos pedidos (ativo apenas em DEV e STG) |
| prometheus-fastapi-instrumentator | 7.0.0 | Exposição de métricas para o Prometheus |

As bibliotecas `starlette` e `setuptools` encontram-se igualmente fixadas, por razões de compatibilidade.

### 6.2 Testes e análise (`requirements-stg.txt` e `requirements-dev.txt`)

| Biblioteca | Versão | Finalidade |
|---|---|---|
| pytest | 8.3.3 | Testes unitários, de integração e *smoke* |
| httpx | 0.27.2 | Cliente HTTP utilizado pelos testes |
| pysonar | 1.9.0.5762 | Envio do código Python para análise no SonarQube |

## 7. Validação

| Tipo | Ferramenta | Ambiente | N.º | Âmbito |
|---|---|---|---|---|
| Unitários | pytest | DEV | 42 | Cada serviço isoladamente: operações, validação de dados, autenticação e permissões |
| Vulnerabilidades do código | SonarQube | DEV, STG e pipeline | — | Código das duas API e dos *scripts*; falha perante qualquer problema de segurança |
| Vulnerabilidades das dependências e imagens | Trivy | Pipeline | — | Dependências Python e imagens Docker |
| Integração | pytest | STG | 12 | Ciclo completo com *tokens* reais do Keycloak, comunicação entre serviços e acesso pelo site de gestão |
| *Smoke* | pytest | STG | 3 | Disponibilidade dos três serviços após o *deploy* |

No pipeline, os testes unitários correm no ramo `dev` e os testes de integração e *smoke* no ramo `stg`, contra o cluster; se forem aprovados, o pipeline de `stg` prepara PRD. No ramo `main` não são executados testes funcionais: repete-se apenas a análise de vulnerabilidades, a imagem validada em STG é promovida sem nova construção e, após aprovação manual, instalada em PRD.

## 8. Limitações e evolução

A configuração entregue destina-se a demonstração e avaliação. Para uma utilização com dados reais, recomenda-se a substituição das credenciais de demonstração e do certificado autoassinado, a execução do Keycloak em modo de produção com base de dados dedicada, a definição de perfis de acesso diferenciados e a utilização de um cluster com vários nós, com cópias de segurança da base de dados.
