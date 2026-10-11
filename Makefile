SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

# ════════════════════════════════════════════════════════════════════
# VARIÁVEIS DE CONFIGURAÇÃO  (todas podem ser sobrepostas: make X VAR=valor)
# ════════════════════════════════════════════════════════════════════

PYTHON          ?= python3
VENV_DIR        ?= .venv
VENV_PY         := $(VENV_DIR)/bin/python
STAMP_DEV       := $(VENV_DIR)/.installed-dev
STAMP_STG       := $(VENV_DIR)/.installed-stg

DOCKER          ?= docker
COMPOSE         ?= docker compose
MICROK8S        ?= sudo snap run microk8s
KUBECTL         ?= $(MICROK8S) kubectl

# O Helm não usa o kubectl do MicroK8s: precisa de um kubeconfig próprio. Sem ele
# tenta http://localhost:8080 — que em DEV é o Keycloak — e falha com
# "kubernetes cluster unreachable: the server could not find the requested resource".
# Por isso o Makefile gera o kubeconfig a partir do cluster e passa-o sempre ao Helm.
KUBECONFIG_FILE ?= kubeconfig-make.yaml
KUBECONFIG_CMD  ?= $(MICROK8S) config
HELM            ?= helm --kubeconfig $(KUBECONFIG_FILE)

RELEASE         := projeto-final
SERVICES        := service-users service-orders web

# Imagens: a mesma imagem construída em STG é promovida (re-tag) para PRD.
IMAGE_REPO      ?= ghcr.io/kunami264/projeto-final-devops
STG_TAG         ?= stg
PRD_TAG         ?= main

# Namespaces Kubernetes
NAMESPACE_STG   := staging
NAMESPACE_PRD   := production
NAMESPACE_AUTH  := auth
NAMESPACE_OBS   := observability

# PRD — ponto de entrada HTTPS (Ingress)
PRD_HOST        ?= projeto-final.test
PRD_URL         := https://$(PRD_HOST)
INGRESS_CLASS   ?= public
INGRESS_NS      ?= ingress
TLS_SECRET      := projeto-final-tls
CERT_DIR        := .certs

# Credenciais de demonstração (definidas em k8s/auth/realm-export.json)
DEMO_USERNAME   ?= admin
DEMO_PASSWORD   ?= admin
TOKEN_PATH      := /realms/projeto-final/protocol/openid-connect/token

# ════════════════════════════════════════════════════════════════════
# PORTAS / URLS
# ════════════════════════════════════════════════════════════════════

# DEV — Docker Compose
DEV_WEB_URL         := http://localhost:8000
DEV_USERS_URL       := http://localhost:8002
DEV_ORDERS_URL      := http://localhost:8001
DEV_KEYCLOAK_URL    := http://localhost:8080
DEV_JAEGER_URL      := http://localhost:16686
DEV_PROMETHEUS_URL  := http://localhost:9090
DEV_GRAFANA_URL     := http://localhost:3000

# STG — MicroK8s (port-forward; portas diferentes das de DEV para coexistirem)
STG_WEB_PORT            := 8100
STG_USERS_PORT          := 8102
STG_ORDERS_PORT         := 8101
STG_KEYCLOAK_PORT       := 8180
STG_KEYCLOAK_MGMT_PORT  := 8190
STG_PORTS               := $(STG_WEB_PORT) $(STG_USERS_PORT) $(STG_ORDERS_PORT) $(STG_KEYCLOAK_PORT) $(STG_KEYCLOAK_MGMT_PORT)

STG_WEB_URL             := http://localhost:$(STG_WEB_PORT)
STG_USERS_URL           := http://localhost:$(STG_USERS_PORT)
STG_ORDERS_URL          := http://localhost:$(STG_ORDERS_PORT)
STG_KEYCLOAK_URL        := http://localhost:$(STG_KEYCLOAK_PORT)
STG_KEYCLOAK_MGMT_URL   := http://localhost:$(STG_KEYCLOAK_MGMT_PORT)

# Observabilidade e Keycloak no cluster (partilhados por STG e PRD)
OBS_JAEGER_PORT       := 17686
OBS_PROMETHEUS_PORT   := 9190
OBS_GRAFANA_PORT      := 3100
OBS_KEYCLOAK_PORT     := 8280
OBS_PORTS             := $(OBS_JAEGER_PORT) $(OBS_PROMETHEUS_PORT) $(OBS_GRAFANA_PORT) $(OBS_KEYCLOAK_PORT)

# ════════════════════════════════════════════════════════════════════
# FUNÇÕES AUXILIARES
# ════════════════════════════════════════════════════════════════════

# $(call kill_ports,<portas>) — termina port-forwards presos a essas portas
kill_ports = { fuser -k $(foreach p,$(1),$(p)/tcp); sudo fuser -k $(foreach p,$(1),$(p)/tcp); } >/dev/null 2>&1 || true
# $(call forward,<namespace>,<service>,<porta local>,<porta do service>)
forward = $(KUBECTL) port-forward -n $(1) svc/$(2) $(3):$(4) >/dev/null 2>&1 &
# $(call image,<service>,<tag>)
image = $(IMAGE_REPO)/$(1):$(2)

.DEFAULT_GOAL := help

.PHONY: help \
	build-dev run-dev test-dev demo-dev token-dev info-dev logs-dev stop-dev clean-dev \
	build-stg run-stg test-stg demo-stg forward-stg info-stg stop-stg clean-stg \
	build-prd push-prd tls-prd run-prd status-prd info-prd stop-prd clean-prd \
	kubeconfig run-infra forward-infra clean-infra \
	lint clean

# ════════════════════════════════════════════════════════════════════
# HELP
# ════════════════════════════════════════════════════════════════════

help: ## Lista todos os comandos disponíveis
	@echo ""
	@echo "Fluxo:  build-dev → run-dev → test-dev   |   build-stg → run-stg → test-stg   |   build-prd → run-prd"
	@echo ""
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-16s\033[0m %s\n", $$1, $$2}'

# ════════════════════════════════════════════════════════════════════
# PYTHON — ambiente virtual (python -m venv .venv)
# ════════════════════════════════════════════════════════════════════

$(VENV_PY):
	@echo "===== [PYTHON] A criar ambiente virtual em $(VENV_DIR) ====="
	$(PYTHON) -m venv $(VENV_DIR)
	$(VENV_PY) -m pip install --quiet --upgrade pip

$(STAMP_DEV): requirements-dev.txt requirements-stg.txt requirements-prd.txt $(wildcard service-*/requirements*.txt) | $(VENV_PY)
	@echo "===== [PYTHON] A instalar requirements-dev.txt ====="
	$(VENV_PY) -m pip install --quiet -r requirements-dev.txt
	@touch $@

$(STAMP_STG): requirements-stg.txt | $(VENV_PY)
	@echo "===== [PYTHON] A instalar requirements-stg.txt ====="
	$(VENV_PY) -m pip install --quiet -r requirements-stg.txt
	@touch $@

# ════════════════════════════════════════════════════════════════════
# KUBERNETES — acesso do Helm ao cluster
# ════════════════════════════════════════════════════════════════════

kubeconfig: ## [K8S] Gera o kubeconfig que o Helm usa para falar com o cluster
	@umask 077; \
	if $(KUBECONFIG_CMD) > $(KUBECONFIG_FILE).tmp 2>/dev/null && [ -s $(KUBECONFIG_FILE).tmp ]; then \
		mv $(KUBECONFIG_FILE).tmp $(KUBECONFIG_FILE); \
	else \
		rm -f $(KUBECONFIG_FILE).tmp; \
		echo "✗ Não foi possível obter o kubeconfig do cluster ($(KUBECONFIG_CMD))."; \
		echo "  O MicroK8s está instalado e a correr?  sudo snap start microk8s && sudo microk8s status --wait-ready"; \
		exit 1; \
	fi

# ════════════════════════════════════════════════════════════════════
# DEV — Docker Compose
# ════════════════════════════════════════════════════════════════════

build-dev: $(STAMP_DEV) ## [DEV] Cria o .venv (requirements-dev.txt) e constrói as imagens Docker
	@echo "===== [DEV] A construir imagens ====="
	$(COMPOSE) build
	@echo "===== [DEV] Build concluído ✅  (seguinte: make run-dev) ====="

run-dev: ## [DEV] Sobe o ambiente local com Docker Compose
	@echo "===== [DEV] A iniciar Docker Compose ====="
	$(COMPOSE) up -d --wait
	@$(MAKE) --no-print-directory info-dev

info-dev: ## [DEV] Mostra endereços e credenciais do ambiente local
	@echo ""
	@echo "===== [DEV] Endereços e credenciais ====="
	@echo "  BACKOFFICE (aplicação)      $(DEV_WEB_URL)       $(DEMO_USERNAME) / $(DEMO_PASSWORD)"
	@echo "  API utilizadores (Swagger)  $(DEV_USERS_URL)/docs  token: make token-dev"
	@echo "  API encomendas   (Swagger)  $(DEV_ORDERS_URL)/docs  token: make token-dev"
	@echo "  Keycloak (consola admin)    $(DEV_KEYCLOAK_URL)       admin / admin"
	@echo "  Grafana                     $(DEV_GRAFANA_URL)       admin / admin"
	@echo "  Prometheus                  $(DEV_PROMETHEUS_URL)       sem login"
	@echo "  Jaeger                      $(DEV_JAEGER_URL)      sem login"
	@echo ""
	@echo "  Criar/editar/apagar clientes e encomendas: no site, ou make demo-dev (README, secção 7)"
	@echo ""

test-dev: $(STAMP_DEV) ## [DEV] Executa os testes unitários
	@echo "===== [DEV] Testes unitários — service-users ====="
	cd service-users && ../$(VENV_PY) -m pytest tests/ -v
	@echo "===== [DEV] Testes unitários — service-orders ====="
	cd service-orders && ../$(VENV_PY) -m pytest tests/ -v

demo-dev: ## [DEV] Cria, edita e apaga um utilizador e uma encomenda (ciclo completo)
	@USERS_URL=$(DEV_USERS_URL) ORDERS_URL=$(DEV_ORDERS_URL) KEYCLOAK_BASE_URL=$(DEV_KEYCLOAK_URL) \
		$(PYTHON) scripts/demo.py --username '$(DEMO_USERNAME)' --password '$(DEMO_PASSWORD)'

token-dev: $(STAMP_DEV) ## [DEV] Imprime um token de acesso (para o Swagger ou curl)
	@$(VENV_PY) scripts/get_token.py --grant password \
		--token-url $(DEV_KEYCLOAK_URL)$(TOKEN_PATH) \
		--username '$(DEMO_USERNAME)' --password '$(DEMO_PASSWORD)'

logs-dev: ## [DEV] Acompanha os logs dos containers
	$(COMPOSE) logs -f

stop-dev: ## [DEV] Para os containers (mantém dados e imagens)
	@echo "===== [DEV] A parar Docker Compose ====="
	$(COMPOSE) down

clean-dev: ## [DEV] Remove containers, volumes, imagens construídas, .venv e temporários
	@echo "===== [CLEAN DEV] Containers, volumes, rede e imagens locais ====="
	-$(COMPOSE) down --volumes --rmi local --remove-orphans
	@echo "===== [CLEAN DEV] Ambiente virtual e ficheiros temporários ====="
	rm -rf $(VENV_DIR) venv .pytest_cache .coverage htmlcov
	find . -type d \( -name "__pycache__" -o -name ".pytest_cache" \) -prune -exec rm -rf {} +
	find . -type f \( -name "*.pyc" -o -name "*.pid" -o -name "*.log" -o -name "*.db" \) -not -path "./.git/*" -delete
	@echo "===== [CLEAN DEV] Concluído ✅ ====="

# ════════════════════════════════════════════════════════════════════
# INFRAESTRUTURA PARTILHADA NO CLUSTER — Keycloak + Observabilidade
# (usada por STG e PRD; aplicada automaticamente por run-stg / run-prd)
# ════════════════════════════════════════════════════════════════════

run-infra: ## [K8S] Aplica Keycloak, Prometheus, Grafana e Jaeger no cluster
	@echo "===== [K8S] Keycloak (namespace $(NAMESPACE_AUTH)) ====="
	$(KUBECTL) apply -f k8s/auth/keycloak.yaml -f k8s/auth/networkpolicy.yaml
	@echo "===== [K8S] Observabilidade (namespace $(NAMESPACE_OBS)) ====="
	$(KUBECTL) apply \
		-f k8s/observability/jaeger.yaml \
		-f k8s/observability/networkpolicy.yaml \
		-f k8s/observability/prometheus.yaml \
		-f k8s/observability/grafana.yaml
	@echo "===== [K8S] A aguardar que fiquem prontos ====="
	$(KUBECTL) rollout status deployment/keycloak   -n $(NAMESPACE_AUTH) --timeout=300s
	$(KUBECTL) rollout status deployment/jaeger     -n $(NAMESPACE_OBS)  --timeout=180s
	$(KUBECTL) rollout status deployment/prometheus -n $(NAMESPACE_OBS)  --timeout=180s
	$(KUBECTL) rollout status deployment/grafana    -n $(NAMESPACE_OBS)  --timeout=180s

forward-infra: ## [K8S] Port-forward de Grafana, Prometheus, Jaeger e Keycloak (STG/PRD)
	@echo ""
	@echo "===== [K8S] Observabilidade e Keycloak do cluster ====="
	@echo "  Grafana                   http://localhost:$(OBS_GRAFANA_PORT)      admin / admin"
	@echo "  Prometheus                http://localhost:$(OBS_PROMETHEUS_PORT)      sem login"
	@echo "  Jaeger                    http://localhost:$(OBS_JAEGER_PORT)     sem login"
	@echo "  Keycloak (consola admin)  http://localhost:$(OBS_KEYCLOAK_PORT)      admin / admin"
	@echo "  Ctrl+C para sair."
	@echo ""
	@$(call kill_ports,$(OBS_PORTS)); \
	trap '$(call kill_ports,$(OBS_PORTS))' EXIT INT TERM; \
	$(call forward,$(NAMESPACE_OBS),grafana,$(OBS_GRAFANA_PORT),3000) \
	$(call forward,$(NAMESPACE_OBS),prometheus,$(OBS_PROMETHEUS_PORT),9090) \
	$(call forward,$(NAMESPACE_OBS),jaeger,$(OBS_JAEGER_PORT),16686) \
	$(call forward,$(NAMESPACE_AUTH),keycloak,$(OBS_KEYCLOAK_PORT),8080) \
	wait

clean-infra: ## [K8S] Remove Keycloak e observabilidade (namespaces, PVCs, RBAC de cluster)
	@echo "===== [CLEAN K8S] Namespaces $(NAMESPACE_AUTH) e $(NAMESPACE_OBS) (inclui PVCs e Secrets) ====="
	-$(KUBECTL) delete namespace $(NAMESPACE_AUTH) $(NAMESPACE_OBS) --ignore-not-found --wait=true --timeout=180s
	@echo "===== [CLEAN K8S] Recursos de cluster do Prometheus ====="
	-$(KUBECTL) delete clusterrolebinding prometheus-scraper --ignore-not-found
	-$(KUBECTL) delete clusterrole prometheus-scraper --ignore-not-found

# ════════════════════════════════════════════════════════════════════
# STG — MicroK8s + Helm  (ambiente onde se testa antes de promover para PRD)
# ════════════════════════════════════════════════════════════════════

build-stg: $(STAMP_STG) ## [STG] Constrói as imagens com os pacotes de PRD, carrega-as no MicroK8s e instala requirements-stg.txt
	@for svc in $(SERVICES); do \
		echo "===== [STG] A construir $(IMAGE_REPO)/$$svc:$(STG_TAG) ====="; \
		$(DOCKER) build -t $(IMAGE_REPO)/$$svc:$(STG_TAG) ./$$svc; \
		echo "===== [STG] A carregar a imagem no MicroK8s ====="; \
		$(DOCKER) save $(IMAGE_REPO)/$$svc:$(STG_TAG) | $(MICROK8S) ctr image import -; \
	done
	$(HELM) lint ./helm -f ./helm/values-staging.yaml
	@echo "===== [STG] Build concluído ✅  (seguinte: make run-stg) ====="

run-stg: kubeconfig run-infra ## [STG] Faz o deploy em Staging (Helm) e aguarda os workloads
	@echo "===== [STG] Deploy via Helm ====="
	$(HELM) upgrade --install $(RELEASE) ./helm \
		-n $(NAMESPACE_STG) --create-namespace \
		-f ./helm/values-staging.yaml \
		--set image.tag=$(STG_TAG) \
		--wait --timeout 5m
	$(KUBECTL) get pods,svc -n $(NAMESPACE_STG)
	@$(MAKE) --no-print-directory info-stg

info-stg: ## [STG] Mostra como aceder ao ambiente de Staging
	@echo ""
	@echo "===== [STG] Staging pronto ✅ ====="
	@echo "  Validar o ambiente (integração + smoke)   make test-stg"
	@echo "  Criar/editar/apagar utilizadores e encomendas    make demo-stg"
	@echo "  Backoffice e APIs (port-forward)          make forward-stg"
	@echo "  Grafana / Prometheus / Jaeger / Keycloak  make forward-infra"
	@echo ""

test-stg: $(STAMP_STG) ## [STG] Testes de integração + smoke — validam Staging antes de promover para PRD
	@echo "===== [STG] A abrir port-forwards e a executar os testes ====="
	@$(call kill_ports,$(STG_PORTS)); \
	trap '$(call kill_ports,$(STG_PORTS))' EXIT; \
	$(call forward,$(NAMESPACE_STG),service-users,$(STG_USERS_PORT),8002) \
	$(call forward,$(NAMESPACE_STG),service-orders,$(STG_ORDERS_PORT),8001) \
	$(call forward,$(NAMESPACE_AUTH),keycloak,$(STG_KEYCLOAK_PORT),8080) \
	$(call forward,$(NAMESPACE_AUTH),keycloak,$(STG_KEYCLOAK_MGMT_PORT),9000) \
	$(call forward,$(NAMESPACE_STG),web,$(STG_WEB_PORT),8080) \
	sleep 5; \
	WEB_URL=$(STG_WEB_URL) \
	USERS_URL=$(STG_USERS_URL) \
	ORDERS_URL=$(STG_ORDERS_URL) \
	KEYCLOAK_BASE_URL=$(STG_KEYCLOAK_URL) \
	KEYCLOAK_MGMT_URL=$(STG_KEYCLOAK_MGMT_URL) \
	$(VENV_PY) -m pytest tests/integration/ tests/smoke/ -v
	@echo "===== [STG] ✅ Staging validado — pode promover para PRD (make build-prd) ====="

demo-stg: ## [STG] Cria, edita e apaga um utilizador e uma encomenda em Staging
	@$(call kill_ports,$(STG_PORTS)); \
	trap '$(call kill_ports,$(STG_PORTS))' EXIT; \
	$(call forward,$(NAMESPACE_STG),service-users,$(STG_USERS_PORT),8002) \
	$(call forward,$(NAMESPACE_STG),service-orders,$(STG_ORDERS_PORT),8001) \
	$(call forward,$(NAMESPACE_AUTH),keycloak,$(STG_KEYCLOAK_PORT),8080) \
	sleep 5; \
	USERS_URL=$(STG_USERS_URL) ORDERS_URL=$(STG_ORDERS_URL) KEYCLOAK_BASE_URL=$(STG_KEYCLOAK_URL) \
	$(PYTHON) scripts/demo.py --username '$(DEMO_USERNAME)' --password '$(DEMO_PASSWORD)'

forward-stg: ## [STG] Port-forward das APIs e do Keycloak de Staging (uso manual)
	@echo ""
	@echo "===== [STG] Port-forward ativo ====="
	@echo "  BACKOFFICE (aplicação)      $(STG_WEB_URL)       $(DEMO_USERNAME) / $(DEMO_PASSWORD)"
	@echo "  API utilizadores (Swagger)  $(STG_USERS_URL)/docs"
	@echo "  API encomendas   (Swagger)  $(STG_ORDERS_URL)/docs"
	@echo "  Keycloak (token)            $(STG_KEYCLOAK_URL)$(TOKEN_PATH)"
	@echo "  Ctrl+C para sair."
	@echo ""
	@$(call kill_ports,$(STG_PORTS)); \
	trap '$(call kill_ports,$(STG_PORTS))' EXIT INT TERM; \
	$(call forward,$(NAMESPACE_STG),web,$(STG_WEB_PORT),8080) \
	$(call forward,$(NAMESPACE_STG),service-users,$(STG_USERS_PORT),8002) \
	$(call forward,$(NAMESPACE_STG),service-orders,$(STG_ORDERS_PORT),8001) \
	$(call forward,$(NAMESPACE_AUTH),keycloak,$(STG_KEYCLOAK_PORT),8080) \
	wait

stop-stg: ## [STG] Remove a release de Staging (mantém namespace, imagens e infraestrutura)
	-@$(MAKE) --no-print-directory kubeconfig
	-$(HELM) uninstall $(RELEASE) -n $(NAMESPACE_STG) --wait

clean-stg: ## [STG] Remove release, namespace (PVCs, Secrets) e imagens de Staging
	@echo "===== [CLEAN STG] Release Helm e namespace $(NAMESPACE_STG) ====="
	-@$(MAKE) --no-print-directory kubeconfig
	-$(HELM) uninstall $(RELEASE) -n $(NAMESPACE_STG) --wait
	-$(KUBECTL) delete namespace $(NAMESPACE_STG) --ignore-not-found --wait=true --timeout=180s
	@echo "===== [CLEAN STG] Imagens (MicroK8s e Docker) ====="
	@for svc in $(SERVICES); do \
		$(MICROK8S) ctr image rm $(IMAGE_REPO)/$$svc:$(STG_TAG) >/dev/null 2>&1 || true; \
		$(DOCKER) image rm -f $(IMAGE_REPO)/$$svc:$(STG_TAG) >/dev/null 2>&1 || true; \
	done
	@$(call kill_ports,$(STG_PORTS))

# ════════════════════════════════════════════════════════════════════
# PRD — MicroK8s + Helm + Ingress HTTPS
# Não se instalam pacotes nem se correm testes em PRD: promove-se a imagem
# já construída e validada em STG e faz-se apenas o start.
# ════════════════════════════════════════════════════════════════════

build-prd: ## [PRD] Promove as imagens validadas em STG (re-tag stg → main, sem reconstruir)
	@for svc in $(SERVICES); do \
		if ! $(DOCKER) image inspect $(IMAGE_REPO)/$$svc:$(STG_TAG) >/dev/null 2>&1; then \
			echo "✗ Imagem $(IMAGE_REPO)/$$svc:$(STG_TAG) não existe."; \
			echo "  PRD só promove o que foi construído e validado em STG: make build-stg run-stg test-stg"; \
			exit 1; \
		fi; \
		echo "===== [PRD] A promover $$svc:$(STG_TAG) → $$svc:$(PRD_TAG) ====="; \
		$(DOCKER) tag $(IMAGE_REPO)/$$svc:$(STG_TAG) $(IMAGE_REPO)/$$svc:$(PRD_TAG); \
		$(DOCKER) save $(IMAGE_REPO)/$$svc:$(PRD_TAG) | $(MICROK8S) ctr image import -; \
	done
	$(HELM) lint ./helm -f ./helm/values-production.yaml
	@echo "===== [PRD] Imagens prontas ✅  (seguinte: make run-prd) ====="

push-prd: ## [PRD] (opcional) Publica as imagens de PRD no registry (requer docker login ghcr.io)
	@for svc in $(SERVICES); do \
		$(DOCKER) push $(IMAGE_REPO)/$$svc:$(PRD_TAG); \
	done

tls-prd: ## [PRD] Gera o certificado TLS (self-signed) e cria o Secret no cluster
	@mkdir -p $(CERT_DIR)
	@if [ ! -f $(CERT_DIR)/tls.crt ]; then \
		echo "===== [PRD] A gerar certificado self-signed para $(PRD_HOST) ====="; \
		openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
			-keyout $(CERT_DIR)/tls.key -out $(CERT_DIR)/tls.crt \
			-subj "/CN=$(PRD_HOST)" -addext "subjectAltName=DNS:$(PRD_HOST)" 2>/dev/null; \
		chmod 600 $(CERT_DIR)/tls.key; \
	fi
	@for ns in $(NAMESPACE_PRD) $(NAMESPACE_AUTH); do \
		$(KUBECTL) create namespace $$ns --dry-run=client -o yaml | $(KUBECTL) apply -f -; \
		$(KUBECTL) create secret tls $(TLS_SECRET) -n $$ns \
			--cert=$(CERT_DIR)/tls.crt --key=$(CERT_DIR)/tls.key \
			--dry-run=client -o yaml | $(KUBECTL) apply -f -; \
	done

run-prd: kubeconfig run-infra tls-prd ## [PRD] Faz o start em Produção (Helm + Ingress HTTPS) — sem build e sem testes
	@echo "===== [PRD] A garantir o Ingress controller ====="
	$(MICROK8S) enable ingress
	@echo "===== [PRD] Endpoint de token do Keycloak atrás do Ingress HTTPS ====="
	sed -e 's/__PRD_HOST__/$(PRD_HOST)/g' -e 's/__INGRESS_CLASS__/$(INGRESS_CLASS)/g' \
		k8s/ingress/keycloak-token-prd.yaml | $(KUBECTL) apply -f -
	@echo "===== [PRD] Start via Helm ====="
	$(HELM) upgrade --install $(RELEASE) ./helm \
		-n $(NAMESPACE_PRD) --create-namespace \
		-f ./helm/values-production.yaml \
		--set image.tag=$(PRD_TAG) \
		--set ingress.host=$(PRD_HOST) \
		--set ingress.className=$(INGRESS_CLASS) \
		--set ingress.controllerNamespace=$(INGRESS_NS) \
		--wait --timeout 5m
	@$(MAKE) --no-print-directory status-prd info-prd

status-prd: ## [PRD] Estado dos workloads (health-checks do Kubernetes, HPA, Ingress)
	$(KUBECTL) get deploy,pods,hpa,pdb,ingress -n $(NAMESPACE_PRD)

info-prd: ## [PRD] Mostra como aceder a Produção
	@echo ""
	@echo "===== [PRD] Produção disponível em $(PRD_URL) ✅ ====="
	@echo "  BACKOFFICE     $(PRD_URL)/"
	@echo "  API            $(PRD_URL)/users  ·  $(PRD_URL)/orders"
	@echo "  Token          $(PRD_URL)$(TOKEN_PATH)"
	@echo ""
	@echo "  O host tem de resolver para o nó do cluster. Na própria máquina:"
	@echo "      echo '127.0.0.1 $(PRD_HOST)' | sudo tee -a /etc/hosts"
	@echo "  Certificado self-signed: usar 'curl -k' (ou --cacert $(CERT_DIR)/tls.crt)."
	@echo "  Como usar: README, secções 5 e 7."
	@echo ""

stop-prd: ## [PRD] Remove a release de Produção (mantém namespace, imagens e infraestrutura)
	-@$(MAKE) --no-print-directory kubeconfig
	-$(HELM) uninstall $(RELEASE) -n $(NAMESPACE_PRD) --wait

clean-prd: ## [PRD] Remove release, namespace (PVCs, Secrets), Ingress, certificado e imagens de Produção
	@echo "===== [CLEAN PRD] Release Helm e namespace $(NAMESPACE_PRD) ====="
	-@$(MAKE) --no-print-directory kubeconfig
	-$(HELM) uninstall $(RELEASE) -n $(NAMESPACE_PRD) --wait
	-$(KUBECTL) delete namespace $(NAMESPACE_PRD) --ignore-not-found --wait=true --timeout=180s
	@echo "===== [CLEAN PRD] Ingress do token e Secret TLS no namespace $(NAMESPACE_AUTH) ====="
	-$(KUBECTL) delete ingress keycloak-token -n $(NAMESPACE_AUTH) --ignore-not-found
	-$(KUBECTL) delete secret $(TLS_SECRET) -n $(NAMESPACE_AUTH) --ignore-not-found
	rm -rf $(CERT_DIR)
	@echo "===== [CLEAN PRD] Imagens (MicroK8s e Docker) ====="
	@for svc in $(SERVICES); do \
		$(MICROK8S) ctr image rm $(IMAGE_REPO)/$$svc:$(PRD_TAG) >/dev/null 2>&1 || true; \
		$(DOCKER) image rm -f $(IMAGE_REPO)/$$svc:$(PRD_TAG) >/dev/null 2>&1 || true; \
	done

# ════════════════════════════════════════════════════════════════════
# GERAL
# ════════════════════════════════════════════════════════════════════

lint: ## Valida o Helm chart com os values de cada ambiente
	$(HELM) lint ./helm
	$(HELM) lint ./helm -f ./helm/values-staging.yaml
	$(HELM) lint ./helm -f ./helm/values-production.yaml

clean: clean-prd clean-stg clean-infra clean-dev ## Limpa TUDO: PRD, STG, infraestrutura do cluster e DEV
	@rm -f $(KUBECONFIG_FILE)
	@$(call kill_ports,$(OBS_PORTS))
	@echo ""
	@echo "===== [CLEAN] Tudo removido ✅ ====="
	@echo "  Cluster: releases Helm, namespaces $(NAMESPACE_PRD)/$(NAMESPACE_STG)/$(NAMESPACE_AUTH)/$(NAMESPACE_OBS),"
	@echo "           PVCs, Secrets, Ingress, ClusterRole/Binding e imagens importadas."
	@echo "  Local:   containers, volumes, rede e imagens do Compose, $(VENV_DIR), $(CERT_DIR), caches e *.db."
	@echo "  (O MicroK8s continua instalado; para o parar: sudo snap stop microk8s)"
