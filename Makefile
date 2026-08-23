SHELL := /bin/bash
PYTHON := python3.12
VENV_DIR := venv
VENV_PY := $(VENV_DIR)/bin/python
VENV_PIP := $(VENV_DIR)/bin/pip
COMPOSE := docker compose

USERS_URL := http://localhost:8002
ORDERS_URL := http://localhost:8001

.DEFAULT_GOAL := help
.PHONY: help venv install \
        test test-unit test-integration test-smoke \
        build up down restart logs ps \
        run-local stop-local \
        lint clean destroy \
        helm-lint helm-template-staging helm-template-production \
        helm-install-staging helm-install-production \
        token k8s-observability-apply token-m2m k8s-auth-apply

venv: ## Cria o virtualenv local (venv/)
	$(PYTHON) -m venv $(VENV_DIR)

install: venv ## Instala as dependências do requirements.txt consolidado
	$(VENV_PIP) install --quiet --upgrade pip
	$(VENV_PIP) install --quiet -r requirements.txt


test-unit: install ## [DEV] Testes unitários isolados de cada microsserviço
	@echo ">> Testes unitários — service-users"
	cd service-users && ../$(VENV_PY) -m pytest tests/ -v
	@echo ">> Testes unitários — service-orders"
	cd service-orders && ../$(VENV_PY) -m pytest tests/ -v

test-integration: install ## [STG] Testes de integração contra os containers reais (requer 'make up')
	USERS_URL=$(USERS_URL) ORDERS_URL=$(ORDERS_URL) \
		$(VENV_PY) -m pytest tests/integration/ -v -m integration

test-smoke: install ## [PRD] Smoke tests pós-deploy (/health de cada serviço)
	USERS_URL=$(USERS_URL) ORDERS_URL=$(ORDERS_URL) \
		$(VENV_PY) -m pytest tests/smoke/ -v

test: test-unit ## Alias de conveniência para test-unit (usado localmente antes de qualquer commit)


build: ## Constrói as imagens Docker dos dois microsserviços
	$(COMPOSE) build

up: ## Sobe os dois microsserviços + PostgreSQL (orders) + Jaeger em background
	$(COMPOSE) up -d --build
	@echo "service-users   -> $(USERS_URL)/health"
	@echo "service-orders  -> $(ORDERS_URL)/health"
	@echo "postgres-orders -> localhost:5432 (db=orders, user=orders)"
	@echo "Jaeger UI       -> http://localhost:16686"

down: ## Para e remove os containers, redes e volumes (não apaga as imagens)
	$(COMPOSE) down -v

restart: down up ## Reinicia o ambiente local por completo

logs: ## Segue os logs de todos os containers em execução
	$(COMPOSE) logs -f

ps: ## Lista o estado dos containers do projeto
	$(COMPOSE) ps
	abort: ## Para e remove os containers, redes e volumes (não apaga as imagens) e sai do Makefile



run-local: install ## Arranca os dois serviços localmente via uvicorn (sem Docker para os serviços — Keycloak continua a precisar do docker-compose)
	# Pré-requisitos:
	#   1. `docker compose up -d keycloak` (Keycloak fica em localhost:8080)
	#   2. Uma entrada "127.0.0.1 keycloak" em /etc/hosts — o issuer dos
	#      tokens está fixado em "keycloak:8080" (KC_HOSTNAME no
	#      docker-compose.yml), e como estes processos correm fora da
	#      rede docker, "keycloak" só resolve com essa entrada manual.
	OIDC_ISSUER=http://keycloak:8080/realms/projeto-final \
	USERS_SERVICE_URL=$(USERS_URL) \
		$(VENV_PY) -m uvicorn app.main:app --app-dir service-users --host 0.0.0.0 --port 8002 & \
	OIDC_ISSUER=http://keycloak:8080/realms/projeto-final \
	OIDC_CLIENT_ID=service-orders-local \
	OIDC_CLIENT_SECRET=troque-este-segredo-service-orders-local \
	USERS_SERVICE_URL=$(USERS_URL) \
		$(VENV_PY) -m uvicorn app.main:app --app-dir service-orders --host 0.0.0.0 --port 8001 & \
	wait

stop-local: ## Termina quaisquer processos uvicorn locais lançados por run-local
	@sudo pkill -f "uvicorn app.main:app" || true



lint: install ## Verifica sintaxe/compilação dos módulos Python (checagem rápida)
	$(VENV_PY) -m py_compile service-users/app/main.py service-users/app/security.py \
		service-users/app/logging_setup.py \
		service-orders/app/main.py service-orders/app/db.py service-orders/app/models.py \
		service-orders/app/security.py service-orders/app/logging_setup.py service-orders/app/oidc_client.py \
		scripts/get_token.py

clean: ## Remove caches Python e o virtualenv local
	rm -rf $(VENV_DIR)
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true

destroy: down clean ## Limpeza total: containers, imagens, venv, caches
	@echo ">> Removendo imagens Docker do projeto..."
	-docker rmi $$(docker images -q "projeto-final-devops*") 2>/dev/null
	-docker stop jaeger 2>/dev/null
	-docker rm jaeger 2>/dev/null
	@echo ">> Infraestrutura completamente removida."



helm-lint: ## Valida a sintaxe e as boas práticas do chart
	helm lint ./helm
	helm lint ./helm -f ./helm/values-staging.yaml
	helm lint ./helm -f ./helm/values-production.yaml

helm-template-staging: ## Mostra o YAML que seria aplicado em staging (sem tocar no cluster)
	helm template projeto-final ./helm -f ./helm/values-staging.yaml

helm-template-production: ## Mostra o YAML que seria aplicado em produção (sem tocar no cluster)
	helm template projeto-final ./helm -f ./helm/values-production.yaml

helm-install-staging: ## Aplica o chart em staging (requer kubectl configurado para o cluster certo)
	helm upgrade --install projeto-final ./helm \
		-n staging --create-namespace \
		-f ./helm/values-staging.yaml

helm-install-production: ## Aplica o chart em produção (requer kubectl configurado para o cluster certo)
	helm upgrade --install projeto-final ./helm \
		-n production --create-namespace \
		-f ./helm/values-production.yaml

token: install ## Obtém um token real do Keycloak local (usa: make token USERNAME=daniel PASSWORD=...)
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
