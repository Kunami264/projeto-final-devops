SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

# ════════════════════════════════════════════════════════════════════
# VARIÁVEIS DE CONFIGURAÇÃO
# ════════════════════════════════════════════════════════════════════

PYTHON          := python3.12
VENV_DIR        := venv
VENV_PY         := $(VENV_DIR)/bin/python
VENV_PIP        := $(VENV_DIR)/bin/pip
STAMP           := $(VENV_DIR)/.installed

COMPOSE         := docker compose
KUBECTL         := sudo snap run microk8s kubectl

# Namespaces Kubernetes

NAMESPACE_STG   := staging
NAMESPACE_PRD   := prd
NAMESPACE_AUTH  := auth
NAMESPACE_OBS   := observability

# ════════════════════════════════════════════════════════════════════
# PORTAS / URLS
# ════════════════════════════════════════════════════════════════════

# DEV — Docker Compose

DEV_USERS_PORT      := 8002
DEV_ORDERS_PORT     := 8001
DEV_KEYCLOAK_PORT   := 8080
DEV_JAEGER_PORT     := 16686
DEV_PROMETHEUS_PORT := 9090
DEV_GRAFANA_PORT    := 3000

DEV_USERS_URL       := http://localhost:$(DEV_USERS_PORT)
DEV_ORDERS_URL      := http://localhost:$(DEV_ORDERS_PORT)
DEV_KEYCLOAK_URL    := http://localhost:$(DEV_KEYCLOAK_PORT)
DEV_JAEGER_URL      := http://localhost:$(DEV_JAEGER_PORT)
DEV_PROMETHEUS_URL  := http://localhost:$(DEV_PROMETHEUS_PORT)
DEV_GRAFANA_URL     := http://localhost:$(DEV_GRAFANA_PORT)

# STG — MicroK8s

STG_USERS_PORT          := 8102
STG_ORDERS_PORT         := 8101
STG_KEYCLOAK_PORT       := 8180
STG_KEYCLOAK_MGMT_PORT  := 8190

STG_USERS_URL           := http://localhost:$(STG_USERS_PORT)
STG_ORDERS_URL          := http://localhost:$(STG_ORDERS_PORT)
STG_KEYCLOAK_URL        := http://localhost:$(STG_KEYCLOAK_PORT)
STG_KEYCLOAK_MGMT_URL   := http://localhost:$(STG_KEYCLOAK_MGMT_PORT)

# PRD — MicroK8s

PRD_USERS_PORT          := 8202
PRD_ORDERS_PORT         := 8201
PRD_KEYCLOAK_PORT       := 8280
PRD_KEYCLOAK_MGMT_PORT  := 8290

PRD_USERS_URL           := http://localhost:$(PRD_USERS_PORT)
PRD_ORDERS_URL          := http://localhost:$(PRD_ORDERS_PORT)
PRD_KEYCLOAK_URL        := http://localhost:$(PRD_KEYCLOAK_PORT)
PRD_KEYCLOAK_MGMT_URL   := http://localhost:$(PRD_KEYCLOAK_MGMT_PORT)

# Kubernetes Observability
#
# Estes ports são diferentes dos utilizados pelo Docker Compose DEV.
#
# DEV:
#   Jaeger       16686
#   Prometheus    9090
#   Grafana       3000
#
# Kubernetes:
#   Jaeger       17686
#   Prometheus    9190
#   Grafana       3100

OBS_JAEGER_PORT       := 17686
OBS_PROMETHEUS_PORT   := 9190
OBS_GRAFANA_PORT      := 3100

OBS_JAEGER_URL        := http://localhost:$(OBS_JAEGER_PORT)
OBS_PROMETHEUS_URL    := http://localhost:$(OBS_PROMETHEUS_PORT)
OBS_GRAFANA_URL       := http://localhost:$(OBS_GRAFANA_PORT)

.DEFAULT_GOAL := help

.PHONY: \
	help \
	venv \
	install \
	clean \
	destroy \
	up \
	down \
	restart \
	logs \
	test-unit \
	helm-lint \
	helm-template-staging \
	helm-install-staging \
	wait-stg-healthy \
	test-integration-stg \
	monitor-stg \
	validate-dev \
	helm-template-production \
	helm-install-production \
	wait-prd-healthy \
	test-smoke-prd \
	monitor-prd \
	validate-prd \
	k8s-auth-apply \
	k8s-observability-apply \
	observability-stg \
	observability-prd \
	validate-all

# ════════════════════════════════════════════════════════════════════
# HELP
# ════════════════════════════════════════════════════════════════════

help: ## Lista todos os comandos disponíveis
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-32s\033[0m %s\n", $$1, $$2}'

# ════════════════════════════════════════════════════════════════════
# PYTHON / VENV
# ════════════════════════════════════════════════════════════════════

venv: ## Cria o ambiente virtual Python
	@echo "===== [PYTHON] A criar ambiente virtual ====="
	$(PYTHON) -m venv $(VENV_DIR)

$(STAMP): requirements.txt | venv
	@echo "===== [PYTHON] A instalar dependências ====="
	$(VENV_PIP) install --quiet --upgrade pip
	$(VENV_PIP) install --quiet -r requirements.txt
	@touch $(STAMP)

install: $(STAMP) ## Instala o ambiente Python e dependências
	@echo "===== [PYTHON] Ambiente virtual pronto ====="

# ════════════════════════════════════════════════════════════════════
# DEV — Docker Compose
# ════════════════════════════════════════════════════════════════════

up: ## [DEV] Sobe os serviços locais com Docker Compose
	@echo "===== [DEV] A iniciar Docker Compose ====="
	$(COMPOSE) up -d --build
	@echo ""
	@echo ">> [DEV] Serviços disponíveis:"
	@echo "   - service-users    -> $(DEV_USERS_URL)/health"
	@echo "   - service-orders   -> $(DEV_ORDERS_URL)/health"
	@echo "   - Keycloak         -> $(DEV_KEYCLOAK_URL)"
	@echo "   - Jaeger           -> $(DEV_JAEGER_URL)"
	@echo "   - Prometheus       -> $(DEV_PROMETHEUS_URL)"
	@echo "   - Grafana          -> $(DEV_GRAFANA_URL)"

down: ## [DEV] Para e remove os containers Docker Compose
	@echo "===== [DEV] A parar Docker Compose ====="
	$(COMPOSE) down -v

restart: down up ## [DEV] Reinicia os serviços Docker Compose

logs: ## [DEV] Acompanha os logs dos containers
	$(COMPOSE) logs -f

validate-dev: install up test-unit ## [DEV] Valida ambiente de desenvolvimento
	@echo ""
	@echo "===== [DEV] ✅ VALIDAÇÃO PASSOU ✅ ====="

# ════════════════════════════════════════════════════════════════════
# AUTENTICAÇÃO — KEYCLOAK
# ════════════════════════════════════════════════════════════════════

k8s-auth-apply: ## [AUTH] Aplica o Keycloak no cluster
	@echo "===== [AUTH] A garantir namespace ====="

	$(KUBECTL) create namespace $(NAMESPACE_AUTH) \
		--dry-run=client -o yaml | \
		$(KUBECTL) apply -f -

	$(KUBECTL) label namespace $(NAMESPACE_AUTH) \
		kubernetes.io/metadata.name=$(NAMESPACE_AUTH) \
		--overwrite

	@echo "===== [AUTH] A aplicar manifests do Keycloak ====="

	@for f in k8s/auth/*.yaml k8s/auth/*.yml; do \
		if [ -f "$$f" ]; then \
			$(KUBECTL) apply -f "$$f"; \
		fi; \
	done

	@echo "===== [AUTH] A aguardar Keycloak ====="

	$(KUBECTL) rollout status \
		deployment/keycloak \
		-n $(NAMESPACE_AUTH) \
		--timeout=180s

	@echo "===== [AUTH] Keycloak pronto ✅ ====="

# ════════════════════════════════════════════════════════════════════
# OBSERVABILIDADE — KUBERNETES
# ════════════════════════════════════════════════════════════════════

k8s-observability-apply: ## [OBS] Aplica Prometheus, Grafana e Jaeger
	@echo "===== [OBS] A garantir namespace ====="

	$(KUBECTL) create namespace $(NAMESPACE_OBS) \
		--dry-run=client -o yaml | \
		$(KUBECTL) apply -f -

	$(KUBECTL) label namespace $(NAMESPACE_OBS) \
		kubernetes.io/metadata.name=$(NAMESPACE_OBS) \
		--overwrite

	@echo "===== [OBS] A aplicar Grafana ====="
	$(KUBECTL) apply -f k8s/observability/grafana.yaml

	@echo "===== [OBS] A aplicar Jaeger ====="
	$(KUBECTL) apply -f k8s/observability/jaeger.yaml

	@echo "===== [OBS] A aplicar NetworkPolicy ====="
	$(KUBECTL) apply -f k8s/observability/networkpolicy.yaml

	@echo "===== [OBS] A aplicar Prometheus ====="
	$(KUBECTL) apply -f k8s/observability/prometheus.yaml

	@echo "===== [OBS] A aguardar Prometheus ====="
	$(KUBECTL) rollout status \
		deployment/prometheus \
		-n $(NAMESPACE_OBS) \
		--timeout=180s

	@echo "===== [OBS] A aguardar Grafana ====="
	$(KUBECTL) rollout status \
		deployment/grafana \
		-n $(NAMESPACE_OBS) \
		--timeout=180s

	@echo "===== [OBS] Stack pronta ✅ ====="
	$(KUBECTL) get pods,svc -n $(NAMESPACE_OBS)


# ════════════════════════════════════════════════════════════════════
# STG — MicroK8s
# ════════════════════════════════════════════════════════════════════

helm-template-staging: ## [STG] Renderiza os templates Helm
	@echo "===== [STG] Helm template ====="
	helm template projeto-final \
		./helm \
		-n $(NAMESPACE_STG) \
		-f ./helm/values-staging.yaml

helm-install-staging: ## [STG] Instala/Atualiza a release Helm
	@echo "===== [STG] A garantir namespace ====="
	$(KUBECTL) create namespace $(NAMESPACE_STG) \
		--dry-run=client -o yaml | \
		$(KUBECTL) apply -f -

	@echo "===== [STG] A fazer deploy via Helm ====="
	helm upgrade --install projeto-final \
		./helm \
		-n $(NAMESPACE_STG) \
		--create-namespace \
		-f ./helm/values-staging.yaml

wait-stg-healthy: ## [STG] Aguarda os deployments
	@echo "===== [STG] A aguardar workloads ====="

	$(KUBECTL) rollout status \
		deployment/postgres-orders \
		-n $(NAMESPACE_STG) \
		--timeout=120s

	$(KUBECTL) rollout status \
		deployment/service-users \
		-n $(NAMESPACE_STG) \
		--timeout=120s

	$(KUBECTL) rollout status \
		deployment/service-orders \
		-n $(NAMESPACE_STG) \
		--timeout=120s

	@echo "===== [STG] Workloads prontos ✅ ====="
	$(KUBECTL) get pods,svc -n $(NAMESPACE_STG)

test-integration-stg: install ## [STG] Executa testes de integração
	@echo "===== [STG] A limpar port-forwards antigos ====="

	@-sudo fuser -k \
		$(STG_USERS_PORT)/tcp \
		$(STG_ORDERS_PORT)/tcp \
		$(STG_KEYCLOAK_PORT)/tcp \
		$(STG_KEYCLOAK_MGMT_PORT)/tcp \
		>/dev/null 2>&1 || true

	@rm -f \
		users_stg_pf.log \
		orders_stg_pf.log \
		keycloak_stg_pf.log \
		keycloak_mgmt_stg_pf.log

	@echo "===== [STG] A iniciar port-forwards ====="

	@$(KUBECTL) port-forward \
		-n $(NAMESPACE_STG) \
		svc/service-users \
		$(STG_USERS_PORT):8002 \
		>users_stg_pf.log 2>&1 &

	@$(KUBECTL) port-forward \
		-n $(NAMESPACE_STG) \
		svc/service-orders \
		$(STG_ORDERS_PORT):8001 \
		>orders_stg_pf.log 2>&1 &

	@$(KUBECTL) port-forward \
		-n $(NAMESPACE_AUTH) \
		svc/keycloak \
		$(STG_KEYCLOAK_PORT):8080 \
		>keycloak_stg_pf.log 2>&1 &

	@$(KUBECTL) port-forward \
		-n $(NAMESPACE_AUTH) \
		svc/keycloak \
		$(STG_KEYCLOAK_MGMT_PORT):9000 \
		>keycloak_mgmt_stg_pf.log 2>&1 &

	@sleep 5

	@echo "===== [STG] A executar testes de integração ====="

	@USERS_URL=$(STG_USERS_URL) \
	ORDERS_URL=$(STG_ORDERS_URL) \
	KEYCLOAK_BASE_URL=$(STG_KEYCLOAK_URL) \
	KEYCLOAK_MGMT_URL=$(STG_KEYCLOAK_MGMT_URL) \
	$(VENV_PY) -m pytest tests/integration/ -v -m integration

	@echo "===== [STG] A terminar port-forwards ====="

	@-sudo fuser -k \
		$(STG_USERS_PORT)/tcp \
		$(STG_ORDERS_PORT)/tcp \
		$(STG_KEYCLOAK_PORT)/tcp \
		$(STG_KEYCLOAK_MGMT_PORT)/tcp \
		>/dev/null 2>&1 || true

	@rm -f \
		users_stg_pf.log \
		orders_stg_pf.log \
		keycloak_stg_pf.log \
		keycloak_mgmt_stg_pf.log

observability-stg: ## [OBS] Acede à observabilidade Kubernetes
	@echo "===== [OBS] Observabilidade Kubernetes ====="
	@echo ""
	@echo ">> Jaeger      -> $(OBS_JAEGER_URL)"
	@echo ">> Prometheus  -> $(OBS_PROMETHEUS_URL)"
	@echo ">> Grafana     -> $(OBS_GRAFANA_URL)"
	@echo ""
	@echo ">> Ctrl+C para sair."
	@echo ""

	@-sudo fuser -k \
		$(OBS_JAEGER_PORT)/tcp \
		$(OBS_PROMETHEUS_PORT)/tcp \
		$(OBS_GRAFANA_PORT)/tcp \
		>/dev/null 2>&1 || true

	@trap 'sudo fuser -k \
		$(OBS_JAEGER_PORT)/tcp \
		$(OBS_PROMETHEUS_PORT)/tcp \
		$(OBS_GRAFANA_PORT)/tcp \
		>/dev/null 2>&1 || true' EXIT INT TERM; \
	$(KUBECTL) port-forward \
		-n $(NAMESPACE_OBS) \
		svc/jaeger \
		$(OBS_JAEGER_PORT):16686 & \
	$(KUBECTL) port-forward \
		-n $(NAMESPACE_OBS) \
		svc/prometheus \
		$(OBS_PROMETHEUS_PORT):9090 & \
	$(KUBECTL) port-forward \
		-n $(NAMESPACE_OBS) \
		svc/grafana \
		$(OBS_GRAFANA_PORT):3000 & \
	wait

monitor-stg: ## [STG] Port-forward das aplicações
	@echo "===== [STG] A limpar portas anteriores ====="

	@-sudo fuser -k \
		$(STG_USERS_PORT)/tcp \
		$(STG_ORDERS_PORT)/tcp \
		>/dev/null 2>&1 || true

	@echo ""
	@echo "===== [STG] Port-forward ativo ====="
	@echo ">> service-users  -> $(STG_USERS_URL)"
	@echo ">> service-orders -> $(STG_ORDERS_URL)"
	@echo ">> Ctrl+C para sair."
	@echo ""

	@trap 'sudo fuser -k \
		$(STG_USERS_PORT)/tcp \
		$(STG_ORDERS_PORT)/tcp \
		>/dev/null 2>&1 || true' EXIT INT TERM; \
	$(KUBECTL) port-forward \
		-n $(NAMESPACE_STG) \
		svc/service-users \
		$(STG_USERS_PORT):8002 & \
	$(KUBECTL) port-forward \
		-n $(NAMESPACE_STG) \
		svc/service-orders \
		$(STG_ORDERS_PORT):8001 & \
	wait

validate-stg: helm-template-staging helm-install-staging wait-stg-healthy test-integration-stg ## [STG] Valida Staging
	@echo ""
	@echo "===== [STG] ✅ VALIDAÇÃO PASSOU ✅ ====="

# ════════════════════════════════════════════════════════════════════
# PRD — MicroK8s
# ════════════════════════════════════════════════════════════════════
helm-template-production: ## [PRD] Renderiza os templates Helm
	@echo "===== [PRD] Helm template ====="
	helm template projeto-final \
		./helm \
		-n $(NAMESPACE_PRD) \
		-f ./helm/values-production.yaml

helm-install-production: ## [PRD] Instala/Atualiza a release Helm
	@echo "===== [PRD] A garantir namespace ====="
	$(KUBECTL) create namespace $(NAMESPACE_PRD) \
		--dry-run=client -o yaml | \
		$(KUBECTL) apply -f -

	@echo "===== [PRD] A fazer deploy via Helm ====="
	helm upgrade --install projeto-final \
		./helm \
		-n $(NAMESPACE_PRD) \
		--create-namespace \
		-f ./helm/values-production.yaml

wait-prd-healthy: ## [PRD] Aguarda os deployments
	@echo "===== [PRD] A aguardar workloads ====="

	$(KUBECTL) rollout status \
		deployment/postgres-orders \
		-n $(NAMESPACE_PRD) \
		--timeout=120s

	$(KUBECTL) rollout status \
		deployment/service-users \
		-n $(NAMESPACE_PRD) \
		--timeout=120s

	$(KUBECTL) rollout status \
		deployment/service-orders \
		-n $(NAMESPACE_PRD) \
		--timeout=120s

	@echo "===== [PRD] Workloads prontos ✅ ====="
	$(KUBECTL) get pods,svc,hpa -n $(NAMESPACE_PRD)

test-smoke-prd: install ## [PRD] Executa smoke tests
	@echo "===== [PRD] A limpar port-forwards antigos ====="

	@-sudo fuser -k \
		$(PRD_USERS_PORT)/tcp \
		$(PRD_ORDERS_PORT)/tcp \
		>/dev/null 2>&1 || true

	@rm -f \
		users_prd_pf.log \
		orders_prd_pf.log \
		users_prd_pf.pid \
		orders_prd_pf.pid

	@echo "===== [PRD] A iniciar port-forwards ====="

	@$(KUBECTL) port-forward \
		-n $(NAMESPACE_PRD) \
		svc/service-users \
		$(PRD_USERS_PORT):8002 \
		>users_prd_pf.log 2>&1 & \
	echo $$! > users_prd_pf.pid

	@$(KUBECTL) port-forward \
		-n $(NAMESPACE_PRD) \
		svc/service-orders \
		$(PRD_ORDERS_PORT):8001 \
		>orders_prd_pf.log 2>&1 & \
	echo $$! > orders_prd_pf.pid

	@sleep 5

	@echo "===== [PRD] A executar smoke tests ====="

	@USERS_URL=$(PRD_USERS_URL) \
	ORDERS_URL=$(PRD_ORDERS_URL) \
	$(VENV_PY) -m pytest tests/smoke/ -v

	@echo "===== [PRD] A terminar port-forwards ====="

	@-kill $$(cat users_prd_pf.pid orders_prd_pf.pid 2>/dev/null) \
		>/dev/null 2>&1 || true

	@-sudo fuser -k \
		$(PRD_USERS_PORT)/tcp \
		$(PRD_ORDERS_PORT)/tcp \
		>/dev/null 2>&1 || true

	@rm -f \
		users_prd_pf.log \
		orders_prd_pf.log \
		users_prd_pf.pid \
		orders_prd_pf.pid

observability-prd: observability-stg ## [OBS] Acede à observabilidade Kubernetes em PRD

monitor-prd: ## [PRD] Port-forward das aplicações
	@echo "===== [PRD] A limpar portas anteriores ====="

	@-sudo fuser -k \
		$(PRD_USERS_PORT)/tcp \
		$(PRD_ORDERS_PORT)/tcp \
		>/dev/null 2>&1 || true

	@echo ""
	@echo "===== [PRD] Port-forward ativo ====="
	@echo ">> service-users  -> $(PRD_USERS_URL)"
	@echo ">> service-orders -> $(PRD_ORDERS_URL)"
	@echo ">> Ctrl+C para sair."
	@echo ""

	@trap 'sudo fuser -k \
		$(PRD_USERS_PORT)/tcp \
		$(PRD_ORDERS_PORT)/tcp \
		>/dev/null 2>&1 || true' EXIT INT TERM; \
	$(KUBECTL) port-forward \
		-n $(NAMESPACE_PRD) \
		svc/service-users \
		$(PRD_USERS_PORT):8002 & \
	$(KUBECTL) port-forward \
		-n $(NAMESPACE_PRD) \
		svc/service-orders \
		$(PRD_ORDERS_PORT):8001 & \
	wait

validate-prd: helm-template-production helm-install-production wait-prd-healthy test-smoke-prd ## [PRD] Valida Produção
	@echo ""
	@echo "===== [PRD] ✅ VALIDAÇÃO PASSOU ✅ ====="


# ════════════════════════════════════════════════════════════════════
# TESTES UNITÁRIOS / HELM
# ════════════════════════════════════════════════════════════════════

test-unit: install ## Executa os testes unitários
	@echo "===== [TEST] service-users ====="
	cd service-users && ../$(VENV_PY) -m pytest tests/ -v

	@echo "===== [TEST] service-orders ====="
	cd service-orders && ../$(VENV_PY) -m pytest tests/ -v

helm-lint: ## Valida os Helm Charts
	@echo "===== [HELM] A validar charts ====="
	helm lint ./helm
	helm lint ./helm -f ./helm/values-staging.yaml
	helm lint ./helm -f ./helm/values-production.yaml

# ════════════════════════════════════════════════════════════════════
# VALIDAÇÃO COMPLETA
# ════════════════════════════════════════════════════════════════════

validate-all: ## Executa a validação completa DEV -> STG -> PRD
	@echo ""
	@echo "=========================================================="
	@echo "        VALIDAÇÃO COMPLETA DO PROJETO"
	@echo "=========================================================="

	@echo ""
	@echo ">> [1/5] A validar DEV..."
	$(MAKE) validate-dev

	@echo ""
	@echo ">> [2/5] A preparar Keycloak..."
	$(MAKE) k8s-auth-apply

	@echo ""
	@echo ">> [3/5] A preparar Observabilidade..."
	$(MAKE) k8s-observability-apply

	@echo ""
	@echo ">> [4/5] A validar STG..."
	$(MAKE) validate-stg

	@echo ""
	@echo ">> [5/5] A validar PRD..."
	$(MAKE) validate-prd

	@echo ""
	@echo "=========================================================="
	@echo "         TODAS AS VALIDAÇÕES PASSARAM" ✅
	@echo "=========================================================="

# ════════════════════════════════════════════════════════════════════
# LIMPEZA
# ════════════════════════════════════════════════════════════════════

clean: ## Remove ficheiros temporários e ambiente Python
	@echo "===== [CLEAN] A limpar ficheiros temporários ====="

	rm -rf $(VENV_DIR)
	rm -rf .pytest_cache
	rm -rf .coverage
	rm -rf htmlcov

	find . \
		-type d \
		-name "__pycache__" \
		-prune \
		-exec rm -rf {} +

	find . \
		-type f \
		-name "*.pyc" \
		-delete

	find . \
		-type f \
		-name "*.pid" \
		-delete

	find . \
		-type f \
		-name "*.log" \
		-delete

	@echo "===== [CLEAN] Limpeza concluída ✅ ====="

# ════════════════════════════════════════════════════════════════════
# DESTROY
# ════════════════════════════════════════════════════════════════════

destroy: ## Remove aplicações, Docker Compose e ambiente Python
	@echo ""
	@echo "===== [DESTROY] A remover aplicações ====="
	@echo ""

	@echo ">> A remover release STG..."
	@unset KUBECONFIG; helm uninstall projeto-final -n $(NAMESPACE_STG) || true

	@echo ">> A remover release PRD..."
	@unset KUBECONFIG; helm uninstall projeto-final -n $(NAMESPACE_PRD) || true

	@echo ">> A parar Docker Compose..."
	$(COMPOSE) down -v --remove-orphans || true

	@echo ">> A remover ambiente virtual Python..."
	rm -rf $(VENV_DIR)

	@echo ""
	@echo ">> Aplicações e ambiente Python removidos. ✅"
	@echo ">> Os namespaces auth/observability não são removidos automaticamente por serem infraestrutura partilhada."