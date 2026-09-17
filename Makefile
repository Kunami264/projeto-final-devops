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
NAMESPACE_OBS   := observability

# URLs / Portas Locais por Ambiente (sem conflito)
DEV_USERS_URL   := http://localhost:8002
DEV_ORDERS_URL  := http://localhost:8001

STG_USERS_PORT    := 8102
STG_ORDERS_PORT   := 8101
STG_KEYCLOAK_PORT := 8180
STG_USERS_URL     := http://localhost:$(STG_USERS_PORT)
STG_ORDERS_URL    := http://localhost:$(STG_ORDERS_PORT)
STG_KEYCLOAK_URL  := http://localhost:$(STG_KEYCLOAK_PORT)
STG_KEYCLOAK_MGMT_PORT := 8190
STG_KEYCLOAK_MGMT_URL  := http://localhost:$(STG_KEYCLOAK_MGMT_PORT)

PRD_USERS_PORT  := 8202
PRD_ORDERS_PORT := 8201
PRD_USERS_URL   := http://localhost:$(PRD_USERS_PORT)
PRD_ORDERS_URL  := http://localhost:$(PRD_ORDERS_PORT)

.DEFAULT_GOAL := help
.PHONY: help venv install clean destroy lint \
        up down restart logs validate-dev \
        helm-template-staging helm-install-staging wait-stg-healthy test-integration-stg monitor-stg validate-stg \
        helm-template-production helm-install-production wait-prd-healthy test-smoke-prd monitor-prd validate-prd \
        k8s-observability-apply validate-all

help: ## Lista todos os comandos disponíveis
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-28s\033[0m %s\n", $$1, $$2}'

venv:
	$(PYTHON) -m venv $(VENV_DIR)

$(STAMP): requirements.txt | venv
	$(VENV_PIP) install --quiet --upgrade pip
	$(VENV_PIP) install --quiet -r requirements.txt
	touch $(STAMP)

install: $(STAMP)

# ════════════════════════════════════════════════════════════════════
# DEV — Docker
# ════════════════════════════════════════════════════════════════════

up: ## [DEV] Sobe os serviços locais com Docker Compose
	$(COMPOSE) up -d --build
	@echo ">> [DEV] Serviços e dependências locais iniciados:"
	@echo "   - service-users   -> $(DEV_USERS_URL)/health"
	@echo "   - service-orders  -> $(DEV_ORDERS_URL)/health"
	@echo "   - postgres-orders -> localhost:5432"

down: ## [DEV] Para e remove os containers e volumes do Docker Compose
	$(COMPOSE) down -v

restart: down up ## [DEV] Reinicia os serviços do Docker Compose

logs: ## [DEV] Acompanha os logs dos containers Docker em tempo real
	$(COMPOSE) logs -f

validate-dev: install test-unit ## [DEV] Valida ambiente de desenvolvimento (testes unitários)
	@echo "===== [DEV] ✅ VALIDAÇÃO PASSOU ====="

# ════════════════════════════════════════════════════════════════════
# STG — MicroK8s
# ════════════════════════════════════════════════════════════════════

helm-template-staging: ## [STG] Renderiza os templates Helm para Staging
	helm template projeto-final ./helm -n $(NAMESPACE_STG) -f ./helm/values-staging.yaml

helm-install-staging: ## [STG] Instala/Atualiza a release Helm em Staging
	@echo "===== [STG] A garantir namespace $(NAMESPACE_STG) ====="
	$(KUBECTL) create namespace $(NAMESPACE_STG) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@echo "===== [STG] A fazer deploy via Helm ====="
	helm upgrade --install projeto-final ./helm -n $(NAMESPACE_STG) --create-namespace -f ./helm/values-staging.yaml

wait-stg-healthy: ## [STG] Aguarda que todos os pods fiquem operacionais
	@echo "===== [STG] A aguardar Rollout das aplicações (Timeout 120s) ====="
	$(KUBECTL) rollout status deployment/postgres-orders -n $(NAMESPACE_STG) --timeout=120s
	$(KUBECTL) rollout status deployment/service-users -n $(NAMESPACE_STG) --timeout=120s
	$(KUBECTL) rollout status deployment/service-orders -n $(NAMESPACE_STG) --timeout=120s
	@echo "===== [STG] Workloads prontos ====="
	$(KUBECTL) get pods,svc -n $(NAMESPACE_STG)

test-integration-stg: install ## [STG] Executa testes de integração apontando ao Staging
	@echo "===== [STG] A limpar eventuais túneis antigos ====="
	@-sudo fuser -k $(STG_USERS_PORT)/tcp $(STG_ORDERS_PORT)/tcp $(STG_KEYCLOAK_PORT)/tcp $(STG_KEYCLOAK_MGMT_PORT)/tcp >/dev/null 2>&1 || true
	@sleep 1
	@echo "===== [STG] A iniciar port-forward temporário para testes ====="
	@$(KUBECTL) port-forward svc/service-users $(STG_USERS_PORT):8002 -n $(NAMESPACE_STG) > users_stg_pf.log 2>&1 &
	@$(KUBECTL) port-forward svc/service-orders $(STG_ORDERS_PORT):8001 -n $(NAMESPACE_STG) > orders_stg_pf.log 2>&1 &
	@$(KUBECTL) port-forward svc/keycloak $(STG_KEYCLOAK_PORT):8080 -n auth > keycloak_stg_pf.log 2>&1 &
	@$(KUBECTL) port-forward svc/keycloak $(STG_KEYCLOAK_MGMT_PORT):9000 -n auth > keycloak_mgmt_stg_pf.log 2>&1 &
	@sleep 3
	@echo "===== [STG] A executar testes de integração ====="
	@USERS_URL=$(STG_USERS_URL) ORDERS_URL=$(STG_ORDERS_URL) \
		KEYCLOAK_BASE_URL=$(STG_KEYCLOAK_URL) KEYCLOAK_MGMT_URL=$(STG_KEYCLOAK_MGMT_URL) \
		$(VENV_PY) -m pytest tests/integration/ -v -m integration || \
		(sudo fuser -k $(STG_USERS_PORT)/tcp $(STG_ORDERS_PORT)/tcp $(STG_KEYCLOAK_PORT)/tcp $(STG_KEYCLOAK_MGMT_PORT)/tcp >/dev/null 2>&1 || true; rm -f *_stg_pf.log; exit 1)
	@echo "===== [STG] A terminar port-forward ====="
	@-sudo fuser -k $(STG_USERS_PORT)/tcp $(STG_ORDERS_PORT)/tcp $(STG_KEYCLOAK_PORT)/tcp $(STG_KEYCLOAK_MGMT_PORT)/tcp >/dev/null 2>&1 || true
	@rm -f *_stg_pf.log

monitor-stg: ## [STG] Port-forward para aceder diretamente aos pods em Staging
	@echo ">> A limpar portas anteriores..."
	@-sudo fuser -k $(STG_ORDERS_PORT)/tcp $(STG_USERS_PORT)/tcp >/dev/null 2>&1 || true
	@sleep 1
	@echo ">> A ligar a Staging via port-forward (Ctrl+C para sair)..."
	@echo ">> service-orders: $(STG_ORDERS_URL)"
	@echo ">> service-users:  $(STG_USERS_URL)"
	@trap 'sudo fuser -k $(STG_ORDERS_PORT)/tcp $(STG_USERS_PORT)/tcp >/dev/null 2>&1 || true' EXIT INT TERM; \
	$(KUBECTL) port-forward -n $(NAMESPACE_STG) svc/service-orders $(STG_ORDERS_PORT):8001 & \
	$(KUBECTL) port-forward -n $(NAMESPACE_STG) svc/service-users $(STG_USERS_PORT):8002 & \
	wait

validate-stg: helm-template-staging helm-install-staging wait-stg-healthy test-integration-stg ## [STG] Valida Staging (Helm + Rollout + Testes de Integração)
	@echo "===== [STG] ✅ VALIDAÇÃO PASSOU ====="

# ════════════════════════════════════════════════════════════════════
# PRD — MicroK8s
# ════════════════════════════════════════════════════════════════════

helm-template-production: ## [PRD] Renderiza os templates Helm para Produção
	helm template projeto-final ./helm -n $(NAMESPACE_PRD) -f ./helm/values-production.yaml

helm-install-production: ## [PRD] Instala/Atualiza a release Helm em Produção
	@echo "===== [PRD] A garantir namespace $(NAMESPACE_PRD) ====="
	$(KUBECTL) create namespace $(NAMESPACE_PRD) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@echo "===== [PRD] A fazer deploy via Helm ====="
	helm upgrade --install projeto-final ./helm -n $(NAMESPACE_PRD) --create-namespace -f ./helm/values-production.yaml

wait-prd-healthy: ## [PRD] Aguarda que todos os pods fiquem operacionais
	@echo "===== [PRD] A aguardar Rollout das aplicações (Timeout 120s) ====="
	$(KUBECTL) rollout status deployment/postgres-orders -n $(NAMESPACE_PRD) --timeout=120s
	$(KUBECTL) rollout status deployment/service-users -n $(NAMESPACE_PRD) --timeout=120s
	$(KUBECTL) rollout status deployment/service-orders -n $(NAMESPACE_PRD) --timeout=120s
	@echo "===== [PRD] Workloads prontos ====="
	$(KUBECTL) get pods,svc,hpa -n $(NAMESPACE_PRD)

test-smoke-prd: install ## [PRD] Executa smoke tests contra o cluster (via port-forward 8201/8202)
	@echo "===== [PRD] A iniciar port-forward temporário para smoke tests ====="
	@$(KUBECTL) port-forward svc/service-users $(PRD_USERS_PORT):8002 -n $(NAMESPACE_PRD) > users_prd_pf.log 2>&1 & echo $$! > users_prd_pf.pid
	@$(KUBECTL) port-forward svc/service-orders $(PRD_ORDERS_PORT):8001 -n $(NAMESPACE_PRD) > orders_prd_pf.log 2>&1 & echo $$! > orders_prd_pf.pid
	@sleep 3
	@echo "===== [PRD] A executar smoke tests ====="
	@USERS_URL=$(PRD_USERS_URL) ORDERS_URL=$(PRD_ORDERS_URL) $(VENV_PY) -m pytest tests/smoke/ -v || \
		(kill `cat users_prd_pf.pid orders_prd_pf.pid 2>/dev/null` && rm -f users_prd_pf.pid orders_prd_pf.pid users_prd_pf.log orders_prd_pf.log && exit 1)
	@echo "===== [PRD] A terminar port-forward ====="
	@kill `cat users_prd_pf.pid` `cat orders_prd_pf.pid` 2>/dev/null || true
	@rm -f users_prd_pf.pid orders_prd_pf.pid users_prd_pf.log orders_prd_pf.log

monitor-prd: ## [PRD] Abre port-forward para ferramentas de monitorização
	@echo ">> A abrir port-forward para observabilidade de Produção (Ctrl+C para sair)..."
	@echo ">> Jaeger:     http://localhost:16686"
	@echo ">> Prometheus: http://localhost:9090"
	@echo ">> Grafana:    http://localhost:3000"
	@$(KUBECTL) port-forward -n $(NAMESPACE_OBS) svc/jaeger 16686:16686 & \
	$(KUBECTL) port-forward -n $(NAMESPACE_OBS) svc/prometheus 9090:9090 & \
	$(KUBECTL) port-forward -n $(NAMESPACE_OBS) svc/grafana 3000:3000 & \
	wait

validate-prd: helm-template-production helm-install-production wait-prd-healthy test-smoke-prd ## [PRD] Valida Produção (Helm + Rollout + Smoke Tests)
	@echo "===== [PRD] ✅ VALIDAÇÃO PASSOU ====="

# ════════════════════════════════════════════════════════════════════
# Autenticação e Observabilidade — Infraestrutura Base do Cluster (INICIAR ANTES DE VALIDAR STG/PRD)
# ════════════════════════════════════════════════════════════════════

k8s-auth-apply: ## [AUTH] Aplica o Keycloak e prepara o namespace auth
	@echo "===== [AUTH] A garantir namespace auth com labels corretas ====="
	@$(KUBECTL) create namespace auth --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(KUBECTL) label namespace auth kubernetes.io/metadata.name=auth --overwrite
	@echo "===== [AUTH] A aplicar manifests YAML do Keycloak ====="
	@for f in k8s/auth/*.yaml k8s/auth/*.yml; do \
		if [ -f "$$f" ]; then $(KUBECTL) apply -f "$$f"; fi; \
	done
	@echo "===== [AUTH] A aguardar que o Keycloak fique operacional (Timeout 180s) ====="
	$(KUBECTL) rollout status deployment/keycloak -n auth --timeout=180s
	@echo "===== [AUTH] ✅ Keycloak pronto ====="

k8s-observability-apply: ## [OBS] Aplica os manifests da stack de observabilidade no cluster
	@echo "===== [OBS] A garantir namespace observability ====="
	@$(KUBECTL) create namespace $(NAMESPACE_OBS) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(KUBECTL) label namespace $(NAMESPACE_OBS) kubernetes.io/metadata.name=$(NAMESPACE_OBS) --overwrite
	@echo "===== [OBS] A aplicar Prometheus, Grafana e Jaeger ====="
	$(KUBECTL) apply -f k8s/observability/grafana.yaml
	$(KUBECTL) apply -f k8s/observability/jaeger.yaml
	$(KUBECTL) apply -f k8s/observability/networkpolicy.yaml
	$(KUBECTL) apply -f k8s/observability/prometheus-local.yml
	$(KUBECTL) apply -f k8s/observability/prometheus.yaml
	@echo "===== [OBS] ✅ Stack de Observabilidade aplicada ====="

# ════════════════════════════════════════════════════════════════════
# Tudo (Pipeline Completo: DEV -> STG -> PRD)
# ════════════════════════════════════════════════════════════════════

validate-all: ## Executa a pipeline de validação completa nos 3 ambientes em sequência
	@echo "=========================================================="
	@echo "       INÍCIO DA VALIDAÇÃO DOS 3 AMBIENTES               "
	@echo "=========================================================="
	@echo ">> [1/3] A validar DEV..."
	$(MAKE) validate-dev
	@echo ">> [2/3] A validar STG..."
	$(MAKE) validate-stg
	@echo ">> [3/3] A validar PRD..."
	$(MAKE) validate-prd
	@echo "=========================================================="
	@echo "       ✅ TODAS AS VALIDAÇÕES PASSARAM COM SUCESSO        "
	@echo "=========================================================="


# ════════════════════════════════════════════════════════════════════
# TARGETS AUXILIARES
# ════════════════════════════════════════════════════════════════════

test-unit: install
	@echo ">> Testes unitários — service-users"
	cd service-users && ../$(VENV_PY) -m pytest tests/ -v
	@echo ">> Testes unitários — service-orders"
	cd service-orders && ../$(VENV_PY) -m pytest tests/ -v

helm-lint:
	helm lint ./helm
	helm lint ./helm -f ./helm/values-staging.yaml
	helm lint ./helm -f ./helm/values-production.yaml

clean:
	rm -rf $(VENV_DIR) *.pid *.log
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true

destroy: ## Remove containers Docker, releases Helm e Services antigos
	@echo ">> Removendo containers Docker do projeto..."
	-docker ps -a --filter "name=^projetofinal" --format "{{.ID}}" | xargs -r docker rm -f
	@echo ">> Derrubando Docker Compose..."
	-docker compose down -v --remove-orphans 2>/dev/null || true
	@echo ">> Removendo releases Helm..."
	-helm uninstall projeto-final -n $(NAMESPACE_PRD) 2>/dev/null || true
	-helm uninstall projeto-final -n $(NAMESPACE_STG) 2>/dev/null || true
	@echo ">> Removendo Services órfãos..."
	-$(KUBECTL) delete svc service-orders service-users postgres-orders -n $(NAMESPACE_PRD) 2>/dev/null || true
	-$(KUBECTL) delete svc service-orders service-users postgres-orders -n $(NAMESPACE_STG) 2>/dev/null || true
	@echo ">> Infraestrutura removida com sucesso. ✅"
