SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

PYTHON      := python3.12
VENV_DIR    := venv
VENV_PY     := $(VENV_DIR)/bin/python
VENV_PIP    := $(VENV_DIR)/bin/pip
STAMP       := $(VENV_DIR)/.installed
COMPOSE     := docker compose
KUBECTL     := kubectl
NAMESPACE   := prd

# URLs locais para testes
USERS_URL  := http://localhost:8002
ORDERS_URL := http://localhost:8001

.DEFAULT_GOAL := help
.PHONY: help venv install \
        test test-unit test-integration test-smoke \
        validate-dev validate-staging validate-production \
        build up down restart logs ps \
        build up down restart logs ps abort \
        run-local stop-local \
        lint clean destroy \
        helm-lint helm-template-staging helm-template-production \
        helm-install-staging helm-install-production \
        token k8s-observability-apply token-m2m k8s-auth-apply \
        validate-dev validate-stg validate-prd validate-all monitor-prd

help: ## Lista todos os targets disponíveis com a respetiva descrição
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-28s\033[0m %s\n", $$1, $$2}'

# ════════════════════════════════════════════════════════════════════
# INTERFACE OFICIAL — os 3 ambientes + validação agregada.
# ════════════════════════════════════════════════════════════════════

validate-dev: test-unit ## [DEV] Instala dependências e corre os testes unitários
	@echo "===== [DEV] ✅ VALIDAÇÃO PASSOU ====="

validate-stg: helm-lint helm-template-staging up wait-healthy test-integration ## [STG] Valida Helm, sobe containers locais e corre testes de integração
	@echo "===== [STG] ✅ VALIDAÇÃO PASSOU ====="

validate-prd: helm-template-production helm-install-production wait-prd-healthy test-smoke-prd ## [PRD] Deploy Helm e Testes em Produção
	@echo "===== [PRD] ✅ VALIDAÇÃO PASSOU ====="

validate-all: ## Corre a validação nos 3 ambientes em sequência (dev -> stg -> prd)
	@echo "========================================"
	@echo "     VALIDAÇÃO DOS 3 AMBIENTES"
	@echo "========================================"
	$(MAKE) validate-dev
	$(MAKE) validate-stg
	$(MAKE) validate-prd
	@echo "========================================"
	@echo "     ✅ TODAS AS VALIDAÇÕES PASSARAM"
	@echo "========================================"

# ────────────────────────────────────────────────────────────────────
# Targets Auxiliares e Testes
# ────────────────────────────────────────────────────────────────────

venv: 
	$(PYTHON) -m venv $(VENV_DIR)

$(STAMP): requirements.txt | venv 
	$(VENV_PIP) install --quiet --upgrade pip
	$(VENV_PIP) install --quiet -r requirements.txt
	touch $(STAMP)

install: $(STAMP)

test-unit: install 
	@echo ">> Testes unitários — service-users"
	cd service-users && ../$(VENV_PY) -m pytest tests/ -v
	@echo ">> Testes unitários — service-orders"
	cd service-orders && ../$(VENV_PY) -m pytest tests/ -v

test-integration: install 
	@echo ">> A correr testes de integração usando código fonte local..."
	USERS_URL=$(USERS_URL) ORDERS_URL=$(ORDERS_URL) \
		$(VENV_PY) -m pytest tests/integration/ -v -m integration

# Novo Teste Smoke Seguro para K8s com port-forward automático
test-smoke-prd: install
	@echo "===== [PRD] A iniciar port-forward temporário para testes locais ====="
	@$(KUBECTL) port-forward svc/service-users 8002:8002 -n $(NAMESPACE) > /dev/null 2>&1 & echo $$! > users_pf.pid
	@$(KUBECTL) port-forward svc/service-orders 8001:8001 -n $(NAMESPACE) > /dev/null 2>&1 & echo $$! > orders_pf.pid
	@sleep 3 # Aguarda abertura das portas
	@echo "===== [PRD] A executar testes locais (Smoke Tests) contra Kubernetes ====="
	@USERS_URL=$(USERS_URL) ORDERS_URL=$(ORDERS_URL) $(VENV_PY) -m pytest tests/smoke/ -v || (kill `cat users_pf.pid orders_pf.pid 2>/dev/null` && exit 1)
	@echo "===== [PRD] A terminar port-forward ====="
	@kill `cat users_pf.pid` `cat orders_pf.pid` 2>/dev/null || true
	@rm -f users_pf.pid orders_pf.pid

test: test-unit 

# ────────────────────────────────────────────────────────────────────
# Gestão de Ambientes Locais (STG/DEV)
# ────────────────────────────────────────────────────────────────────

build: 
	$(COMPOSE) build

up: 
	$(COMPOSE) up -d --build
	@echo ">> Serviços e Monitorização em STG subiram."
	@echo "service-users   -> $(USERS_URL)/health"
	@echo "service-orders  -> $(ORDERS_URL)/health"
	@echo "postgres-orders -> localhost:5432"
	@echo "Jaeger UI       -> http://localhost:16686"
	@echo "Prometheus      -> http://localhost:9090"
	@echo "Grafana         -> http://localhost:3000"

wait-healthy: 
	@echo ">> A aguardar service-users (Timeout de 60s)..."
	@timeout 60 bash -c 'until curl -sf $(USERS_URL)/health > /dev/null; do sleep 2; done' || (echo "ERRO: service-users não subiu" && exit 1)
	@echo ">> A aguardar service-orders (Timeout de 60s)..."
	@timeout 60 bash -c 'until curl -sf $(ORDERS_URL)/health > /dev/null; do sleep 2; done' || (echo "ERRO: service-orders não subiu" && exit 1)
	@echo ">> Serviços prontos."

down: 
	$(COMPOSE) down -v

restart: down up 
logs: 
	$(COMPOSE) logs -f
ps: 
	$(COMPOSE) ps
abort: down 

# ────────────────────────────────────────────────────────────────────
# Gestão do Kubernetes e Deploy (PRD)
# ────────────────────────────────────────────────────────────────────

helm-lint: 
	helm lint ./helm
	helm lint ./helm -f ./helm/values-staging.yaml
	helm lint ./helm -f ./helm/values-production.yaml

helm-template-production: 
	helm template projeto-final ./helm -n $(NAMESPACE) -f ./helm/values-production.yaml

helm-install-production: 
	@echo "===== [PRD] Criar namespace (idempotente) ====="
	$(KUBECTL) create namespace $(NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@echo "===== [PRD] A instalar/atualizar Helm Chart ====="
	helm upgrade --install projeto-final ./helm -n $(NAMESPACE) --create-namespace -f ./helm/values-production.yaml

wait-prd-healthy:
	@echo "===== [PRD] A aguardar Rollout (Timeout automático pelo Helm/K8s) ====="
	$(KUBECTL) rollout status deployment/postgres-orders -n $(NAMESPACE) --timeout=120s
	$(KUBECTL) rollout status deployment/service-users -n $(NAMESPACE) --timeout=120s
	$(KUBECTL) rollout status deployment/service-orders -n $(NAMESPACE) --timeout=120s
	@echo "===== [PRD] Workloads em execução ====="
	$(KUBECTL) get pods,svc,hpa -n $(NAMESPACE)

destroy: down clean 
	@echo ">> Removendo imagens Docker do projeto..."
	-docker rmi $$(docker images -q "projeto-final-devops*") 2>/dev/null || true
	@echo ">> Removendo release do Kubernetes PRD..."
	-helm uninstall projeto-final -n $(NAMESPACE) 2>/dev/null || true
	@echo ">> Infraestrutura completamente removida. ✅"

# ────────────────────────────────────────────────────────────────────
# Monitorização (Observability)
# ────────────────────────────────────────────────────────────────────

k8s-observability-apply: ## Aplica o stack de monitorização no k8s
	$(KUBECTL) apply -f k8s/observability/

monitor-prd: ## Abre port-forward para aceder à monitorização no K8s
	@echo ">> A abrir port-forward para monitorização de Produção. Prime Ctrl+C para sair."
	@echo ">> Jaeger: http://localhost:16686"
	@echo ">> Prometheus: http://localhost:9090"
	@echo ">> Grafana: http://localhost:3000 (assumindo que o Grafana existe na porta 3000)"
	@$(KUBECTL) port-forward -n observability svc/jaeger 16686:16686 & \
	$(KUBECTL) port-forward -n observability svc/prometheus 9090:9090 & \
	$(KUBECTL) port-forward -n observability svc/grafana 3000:80 & \
	wait

# ────────────────────────────────────────────────────────────────────
# Ferramentas Python, Limpeza e Auth
# ────────────────────────────────────────────────────────────────────

clean: 
	rm -rf $(VENV_DIR) users_pf.pid orders_pf.pid
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true

lint: install 
	$(VENV_PY) -m py_compile service-users/app/main.py service-users/app/security.py \
		service-users/app/logging_setup.py \
		service-orders/app/main.py service-orders/app/db.py service-orders/app/models.py \
		service-orders/app/security.py service-orders/app/logging_setup.py service-orders/app/oidc_client.py \
		scripts/get_token.py

token: install 
	$(VENV_PY) scripts/get_token.py --grant password \
		--username $${USERNAME:-daniel} \
		--password "$${PASSWORD:-MudaEstaPassword123!}"

token-m2m: install ## Obtém um token M2M (client_credentials) — usa: make token-m2m CLIENT_ID=service-orders-local CLIENT_SECRET=...
	$(VENV_PY) scripts/get_token.py --grant client_credentials \
		--client-id "$${CLIENT_ID:-service-orders-local}" \
		--client-secret "$${CLIENT_SECRET:-troque-este-segredo-service-orders-local}"

k8s-observability-apply: ## Aplica Jaeger + Prometheus + Grafana (namespace observability) — requer kubectl configurado
	kubectl apply -f k8s/observability/

k8s-auth-apply: ## Aplica o Keycloak (namespace auth) — requer kubectl configurado
	kubectl apply -f k8s/auth/
