# Processo de implementação, decisões de design, ferramentas e bibliotecas Python

Plataforma de Gestão de Clientes e Encomendas — Projeto Final de DevOps — Daniel Almeida, Tokio School

## 1. Introdução

O presente documento descreve o processo de implementação da Plataforma de Gestão de Clientes e Encomendas, fundamenta as principais decisões de design e identifica as ferramentas e as bibliotecas Python utilizadas.

A plataforma permite a uma organização registar os seus clientes e as respetivas encomendas, através de um site de gestão destinado aos funcionários e de uma API REST, com respostas em JSON, destinada à integração com outras aplicações. A solução é entregue de forma automática em três ambientes — desenvolvimento (DEV), testes (STG) e produção (PRD) — e inclui autenticação centralizada e monitorização.

## 2. Arquitetura da solução

A solução é composta por três serviços aplicacionais executados em contentores — o site de gestão, a API de clientes e a API de encomendas —, por uma base de dados PostgreSQL, pelo Keycloak, responsável pela autenticação e autorização, e pelas ferramentas de monitorização Prometheus e Grafana (DEV e STG) e Jaeger (só DEV). PRD não tem observabilidade. A API de encomendas comunica com a API de clientes para validar o cliente associado a cada encomenda. A análise de vulnerabilidades é feita pelo SonarQube (código), pelo pip-audit (dependências Python) e pelo Trivy (dependências e imagens), fora da aplicação.

![Arquitetura de alto nível (HLD)](20261026-HLD-ProjetoFinal-DevOps.png)

*Figura 1 — Arquitetura de alto nível (versão 3.1). O diagrama editável encontra-se em `docs/20261026-HLD-ProjetoFinal-DevOps.drawio`.*

O diagrama segue as regras de arquitetura e design de redes do Módulo 2:

- **Organização e hierarquia:** máquina → ambientes → segmentos (rede Docker ou *namespace* Kubernetes), e em cada ambiente as camadas de apresentação, aplicação e dados.
- **Segmentação e microssegmentação:** as camadas estão separadas por *firewalls* (NetworkPolicies com bloqueio por omissão), e só os fluxos representados são permitidos.
- **Fluxos:** setas Norte/Sul (utilizadores e Internet) e Este/Oeste (entre serviços), sem cruzamentos de linhas.
- **Classificação de criticidade:** dados públicos, privados e restritos (RGPD).
- **Ícones normalizados e rotulagem:** ícones oficiais do Kubernetes e do Docker; rótulos com endereços IP, sub-redes e portas.
- **Legenda, versão e data:** o ficheiro editável é versionado no Git.

## 3. Processo de implementação

A implementação decorreu de forma incremental. Cada fase foi validada antes do início da seguinte, de modo a que os problemas fossem detetados na fase em que tiveram origem.

| Fase | Trabalho realizado |
|---|---|
| 1. Aplicação | Desenvolvimento de dois microsserviços em Python, com o FastAPI: clientes e encomendas, com as operações de criação, consulta, edição e eliminação. Persistência dos dados em PostgreSQL. |
| 2. Segurança da API | Integração com o Keycloak (OIDC/JWT). Cada pedido é validado quanto à autenticidade do *token* e à permissão exigida pela operação. |
| 3. Contentorização | Um Dockerfile por serviço. As imagens incluem apenas as dependências de execução e são executadas por um utilizador sem privilégios. |
| 4. Ambiente DEV | Ambiente local em Docker Compose, com todos os serviços, para desenvolvimento, testes unitários e testes de vulnerabilidades do código. |
| 5. Ambientes STG e PRD | Kubernetes (MicroK8s) com um único *chart* Helm e um ficheiro de valores por ambiente. Em PRD: réplicas, escalonamento automático e ponto de entrada único em HTTPS. |
| 6. Observabilidade | Em DEV e STG, métricas no Prometheus e painéis e alertas no Grafana; em DEV, também rastreio distribuído dos pedidos no Jaeger, através do OpenTelemetry. PRD não tem observabilidade. |
| 7. Site de gestão | *Backoffice* web que permite aos funcionários gerir clientes e encomendas sem recorrer diretamente à API. |
| 8. Entrega contínua | Pipeline em GitHub Actions: análise de vulnerabilidades (código, dependências e imagens), construção das imagens, testes e *deploy*, segundo a ordem `dev`, `stg` e `main`. |
| 9. Consolidação | Separação estrita entre STG (onde tudo é construído, gerado e validado) e PRD (onde apenas se sobe o ambiente), limpeza integral dos ambientes e elaboração da documentação. |
| 10. Segurança e portabilidade | Resolução de todas as vulnerabilidades, sem exceções: bibliotecas atualizadas e imagens em Alpine. Correção dos 25 *issues* do SonarQube. Testes de vulnerabilidades em `tests/security`, com resultados documentados. Verificação dos pré-requisitos e permissões da máquina (`make check`) e testes sem o ambiente a correr, para poupar memória. |

## 4. Decisões de design

| Decisão | Fundamentação |
|---|---|
| Três ambientes com funções distintas | DEV destina-se ao desenvolvimento, STG à validação e PRD à exploração. Os testes unitários e de vulnerabilidades são executados em DEV, e os de integração, *smoke* e de vulnerabilidades em STG; em PRD não são executados testes, sendo a disponibilidade assegurada pelos *health-checks* do Kubernetes. DEV e STG não correm em simultâneo: `make build-stg` começa por limpar DEV (`make clean-dev`), libertando a memória da máquina para o cluster. Os testes de código não precisam do ambiente: `make test-dev` para-o antes de correr. |
| Em PRD nada é gerado | As imagens são construídas uma única vez em STG, com todas as dependências instaladas. O certificado TLS e o Ingress controller são igualmente preparados em STG. Só depois de os testes de STG passarem as imagens são promovidas para PRD, sem novo *build*. Em PRD apenas se sobe o ambiente, o que torna o arranque rápido e garante que é executado exatamente o que foi validado. |
| OpenTelemetry apenas em DEV | O rastreio distribuído serve o diagnóstico e a resolução de problemas durante o desenvolvimento. As bibliotecas estão num ficheiro próprio (`requirements-tracing.txt`), instalado só nas imagens de DEV. A imagem de STG, que é a mesma que segue para PRD, não as inclui. Assim, PRD executa exatamente o que foi validado e não tem código de diagnóstico nem o custo de processamento e o volume de dados associados. A monitorização de STG faz-se por métricas (Prometheus) e alertas (Grafana). |
| Sem observabilidade em PRD | A observabilidade (métricas e rastreio) serve o diagnóstico e a validação, que decorrem em DEV e STG. Em PRD não se fazem testes nem diagnóstico: o Prometheus não recolhe métricas de `production` (`observability.enableMetrics: false` em `values-production.yaml`, sem regra de NetworkPolicy para o *namespace* `observability`), e o pipeline de `main` não aplica nem consulta a monitorização. A disponibilidade em PRD é assegurada pelos *health-checks* do Kubernetes, pelo número mínimo de réplicas e pelo escalonamento automático. |
| Testes de vulnerabilidades em várias camadas, sem exceções | O SonarQube analisa o código Python. O pip-audit e o Trivy analisam as dependências Python, e o Trivy analisa também as imagens que seguem para PRD. Os testes estão em `tests/security` e correm em DEV (`make test-dev`), em STG (`make test-stg`) e no pipeline. Nenhuma vulnerabilidade é ignorada (o `.trivyignore` não tem exceções). As que existiam foram resolvidas: atualização do `starlette` e do `PyJWT`, mudança da base das imagens de Debian para Alpine (eliminou 44 vulnerabilidades HIGH do sistema operativo sem correção) e remoção do `pip` das imagens. Os resultados estão em `tests/security/RESULTADOS.md`. |
| SonarQube local, a pedido | O SonarQube corre em Docker, no *profile* `sonar` do `docker-compose.yml`, fora da rede da aplicação. Só é iniciado por `make security`, com a memória limitada a cerca de 1,5 GB, e é parado no fim da análise. Não corre em STG, onde não cabe em memória ao lado do cluster; o código é o mesmo já analisado em DEV e no pipeline. As análises ficam guardadas em volume e podem ser consultadas no painel (`make sonar-up`). |
| Portabilidade entre máquinas | O projeto é executado noutras máquinas Ubuntu, com outras permissões. `make check` verifica os programas, o acesso ao Docker sem `sudo`, as permissões de `sudo` e a memória, e indica como corrigir cada falha. O `make` pede a palavra-passe do `sudo` antes de abrir *port-forwards* e espera que fiquem ativos antes de correr os testes. Os pré-requisitos estão no README (secção 3). |
| Dependências separadas por ambiente | `requirements-prd.txt` contém apenas as dependências de execução. O OpenTelemetry está em `requirements-tracing.txt`, só para DEV. Os módulos de teste e de análise (`pytest`, `httpx`, `pysonar`, `pip-audit`) encontram-se em `requirements-stg.txt` e `requirements-dev.txt` e não são incluídos nas imagens. |
| Ponto de entrada único em HTTPS | Em PRD, um Ingress com TLS e redirecionamento de HTTP para HTTPS constitui o único acesso externo. Os serviços, a administração do Keycloak e as ferramentas de monitorização não são expostos. |
| Autenticação centralizada | O Keycloak assume a autenticação e a autorização, evitando que cada serviço gira credenciais. A configuração inicial é mantida em ficheiro, o que torna os ambientes reprodutíveis. |
| Sub-redes fixas em DEV | A rede da aplicação (`172.30.10.0/24`) e a das ferramentas de segurança (`172.30.20.0/24`) são definidas no `docker-compose.yml`. O plano de endereçamento fica previsível e documentado no HLD, e as ferramentas de análise ficam num segmento separado da aplicação. |
| Rede restrita por omissão | As NetworkPolicies bloqueiam todo o tráfego no cluster e autorizam apenas as ligações necessárias entre componentes. |
| Isolamento por *namespace* | A aplicação, a identidade e a observabilidade residem em *namespaces* distintos. O Keycloak é partilhado por STG e PRD; a monitorização serve apenas STG. |
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
| Prometheus e Grafana | Métricas, painéis e alertas (DEV e STG) |
| Jaeger e OpenTelemetry | Rastreio distribuído (DEV) |
| SonarQube Community 26.9 | Testes de vulnerabilidades do código Python (*quality gate* de segurança) |
| Trivy 0.76.1 | Análise de vulnerabilidades das dependências e das imagens (corre num contentor) |
| pip-audit | Análise de vulnerabilidades das dependências Python |
| Alpine Linux | Base das imagens das API (`python:3.12-alpine3.24`) e do site de gestão |
| GitHub Actions | Pipeline de integração e entrega contínuas |
| GitHub Container Registry | Registo das imagens |
| Make | Ponto de entrada único para todos os ambientes |
| Git e GitHub | Controlo de versões, com os ramos `dev`, `stg` e `main` |
| draw.io | Diagrama de arquitetura |

## 6. Bibliotecas Python

### 6.1 Execução (`requirements-prd.txt`, imagens de STG e PRD)

| Biblioteca | Versão | Finalidade |
|---|---|---|
| fastapi | 0.141.1 | *Framework* web das duas API (a versão mais recente sem dependência do OpenTelemetry) |
| starlette | 1.10.0 | Base do FastAPI (corrige as CVE-2026-48818 e CVE-2026-54283) |
| uvicorn | 0.30.6 | Servidor de aplicações (ASGI) |
| pydantic | 2.12.5 | Validação dos dados recebidos |
| sqlalchemy | 2.0.35 | Acesso à base de dados (ORM) |
| psycopg2-binary | 2.9.11 | Ligação ao PostgreSQL |
| pyjwt | 2.15.1 | Validação dos *tokens* de autenticação |
| cryptography | 50.0.0 | Verificação da assinatura dos *tokens* |
| httpx | 0.27.2 | Comunicação entre a API de encomendas e a API de clientes |
| prometheus-fastapi-instrumentator | 8.1.0 | Exposição de métricas para o Prometheus |

### 6.2 Rastreio (`requirements-tracing.txt`, só DEV)

| Biblioteca | Versão | Finalidade |
|---|---|---|
| opentelemetry-api, -sdk e -exporter-otlp-proto-grpc | 1.45.1 | Geração e envio de *traces* para o Jaeger |
| opentelemetry-instrumentation-fastapi e -httpx | 0.66b1 | Rastreio automático dos pedidos |

### 6.3 Testes e análise (`requirements-stg.txt` e `requirements-dev.txt`)

| Biblioteca | Versão | Finalidade |
|---|---|---|
| pytest | 9.1.1 | Testes unitários, de integração, *smoke* e de vulnerabilidades |
| httpx | 0.27.2 | Cliente HTTP utilizado pelos testes |
| pysonar | 1.9.0.5762 | Envio do código Python para análise no SonarQube |
| pip-audit | 2.10.1 | Análise de vulnerabilidades das dependências Python |

## 7. Validação

| Tipo | Ferramenta | Ambiente | N.º | Âmbito |
|---|---|---|---|---|
| Unitários | pytest | DEV | 42 | Cada serviço isoladamente: operações, validação de dados, autenticação e permissões |
| Vulnerabilidades do código | SonarQube | DEV e pipeline | — | Código das duas API, dos *scripts* e dos testes: 0 *issues* (eram 25) |
| Vulnerabilidades das dependências | pip-audit e Trivy | DEV, STG e pipeline | 5 | Dependências Python de cada serviço: 0 vulnerabilidades |
| Vulnerabilidades das imagens | Trivy | STG e pipeline | 3 | Imagens que seguem para PRD: 0 vulnerabilidades, em todas as severidades |
| Integração | pytest | STG | 12 | Ciclo completo com *tokens* reais do Keycloak, comunicação entre serviços e acesso pelo site de gestão |
| *Smoke* | pytest | STG | 3 | Disponibilidade dos três serviços após o *deploy* |

No pipeline, os testes unitários correm no ramo `dev` e os testes de integração e *smoke* no ramo `stg`, contra o cluster; se forem aprovados, o pipeline de `stg` prepara PRD. Os resultados detalhados dos testes de vulnerabilidades estão em `tests/security/RESULTADOS.md`. No ramo `main` não são executados testes funcionais: repete-se apenas a análise de vulnerabilidades, a imagem validada em STG é promovida sem nova construção e, após aprovação manual, instalada em PRD.

## 8. Limitações e evolução

A configuração entregue destina-se a demonstração e avaliação. Para uma utilização com dados reais, recomenda-se a substituição das credenciais de demonstração e do certificado autoassinado, a execução do Keycloak em modo de produção com base de dados dedicada, a definição de perfis de acesso diferenciados e a utilização de um cluster com vários nós, com cópias de segurança da base de dados.
