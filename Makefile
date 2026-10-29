SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

# ════════════════════════════════════════════════════════════════════
# VARIÁVEIS DE CONFIGURAÇÃO  (todas podem ser sobrepostas: make X VAR=valor)
# ════════════════════════════════════════════════════════════════════

PYTHON          ?= $(shell command -v python3.12 2>/dev/null || echo python3)
VENV_DIR        ?= .venv
VENV_PY         := $(VENV_DIR)/bin/python
STAMP_DEV       := $(VENV_DIR)/.installed-dev
STAMP_STG       := $(VENV_DIR)/.installed-stg

DOCKER          ?= docker
COMPOSE         ?= $(shell docker compose version >/dev/null 2>&1 && echo "docker compose" || echo "docker-compose")

CLUSTER         ?= $(shell if command -v snap >/dev/null 2>&1 || command -v microk8s >/dev/null 2>&1; then echo microk8s; elif command -v kind >/dev/null 2>&1; then echo kind; else echo microk8s; fi)
KIND_CLUSTER    ?= dev
MICROK8S        ?= sudo snap run microk8s

ifeq ($(CLUSTER),kind)
KUBECTL         ?= kubectl --context kind-$(KIND_CLUSTER)
KUBECONFIG_CMD  ?= kind get kubeconfig --name $(KIND_CLUSTER)
INGRESS_CLASS   ?= nginx
INGRESS_NS      ?= ingress-nginx
PRD_PORT        ?= 8443
PRD_PORT_SUFFIX := :$(PRD_PORT)
CLUSTER_HINT    := Criar o cluster: kind create cluster --name $(KIND_CLUSTER)
cluster_up       = kind get clusters 2>/dev/null | grep -qx $(KIND_CLUSTER) || { echo "✗ Cluster kind '$(KIND_CLUSTER)' não existe. $(CLUSTER_HINT)"; exit 1; };
cluster_images   = $(DOCKER) exec $(KIND_CLUSTER)-control-plane ctr -n k8s.io images ls -q
docker_containers = $(DOCKER) ps -a --format '{{.ID}} {{.Names}}' | grep -v ' $(KIND_CLUSTER)-control-plane$$' | cut -d' ' -f1
load_image       = kind load docker-image $(1) --name $(KIND_CLUSTER)
unload_image     = $(DOCKER) exec $(KIND_CLUSTER)-control-plane ctr -n k8s.io images rm $(1)
enable_ingress   = $(HELM) upgrade --install ingress-nginx ingress-nginx --repo https://kubernetes.github.io/ingress-nginx -n $(INGRESS_NS) --create-namespace --set controller.service.type=NodePort --wait --timeout 5m
disable_ingress  = $(HELM) uninstall ingress-nginx -n $(INGRESS_NS) --wait; $(KUBECTL) delete namespace $(INGRESS_NS) --ignore-not-found
# O kind já traz DNS e armazenamento por omissão
enable_addons    = true
sudo_refresh     = true
kill_ports       = { for p in $(1); do lsof -ti tcp:$$p | xargs kill; done; } >/dev/null 2>&1 || true
else
KUBECTL         ?= $(MICROK8S) kubectl
INGRESS_CLASS   ?= public
INGRESS_NS      ?= ingress
PRD_PORT        ?= 443
PRD_PORT_SUFFIX :=
CLUSTER_HINT    := Ver o estado com: sudo microk8s status --wait-ready
cluster_up       = if ! snap list microk8s >/dev/null 2>&1; then echo "✗ MicroK8s não está instalado: sudo snap install microk8s --classic"; exit 1; fi; \
                   if ! $(MICROK8S) status --wait-ready --timeout 15 >/dev/null 2>&1; then \
                     echo "===== [K8S] MicroK8s parado: a arrancar (pode demorar 1-2 minutos) ====="; \
                     sudo snap start microk8s; $(MICROK8S) status --wait-ready --timeout 300 >/dev/null; \
                   fi;
cluster_images   = $(MICROK8S) ctr image ls -q
docker_containers = $(DOCKER) ps -qa
load_image       = $(DOCKER) save $(1) | $(MICROK8S) ctr image import -
unload_image     = $(MICROK8S) ctr image rm $(1)
enable_ingress   = $(MICROK8S) enable ingress
disable_ingress  = $(MICROK8S) disable ingress
# DNS e armazenamento são necessários ao Keycloak, Prometheus e Grafana (volumes persistentes)
enable_addons    = $(MICROK8S) enable dns hostpath-storage metrics-server
# Os port-forwards correm em segundo plano com sudo: pede-se a password antes, em primeiro plano
# (só quando o kubectl usa sudo; o pipeline passa KUBECTL="microk8s kubectl", sem sudo)
sudo_refresh     = case "$(KUBECTL)" in sudo*) sudo -v ;; esac
kill_ports       = { fuser -k $(foreach p,$(1),$(p)/tcp); sudo fuser -k $(foreach p,$(1),$(p)/tcp); } >/dev/null 2>&1 || true
endif

KUBECONFIG_FILE ?= kubeconfig-make.yaml
KUBECONFIG_CMD  ?= $(MICROK8S) config
HELM            ?= helm --kubeconfig $(KUBECONFIG_FILE)

RELEASE         := projeto-final
SERVICES        := service-users service-orders web

IMAGE_REPO      ?= ghcr.io/kunami264/projeto-final-devops
STG_TAG         ?= stg
PRD_TAG         ?= main

NAMESPACE_STG   := staging
NAMESPACE_PRD   := production
NAMESPACE_AUTH  := auth
NAMESPACE_OBS   := observability

# PRD — ponto de entrada HTTPS (Ingress)
PRD_HOST        ?= projeto-final.test
PRD_URL         := https://$(PRD_HOST)$(PRD_PORT_SUFFIX)
TLS_SECRET      := projeto-final-tls
CERT_DIR        := .certs

SONAR_COMPOSE   := $(COMPOSE) --profile sonar
SONAR_URL       ?= http://localhost:9500
SONAR_USER      ?= admin
SONAR_PASSWORD  ?= ProjetoFinal.2026
SONAR_GATE      := Segurança
SONAR_ARCH      := $(shell case "$$(uname -m)" in (aarch64|arm64) echo aarch64 ;; (*) echo x64 ;; esac)

# Testes de vulnerabilidades (tests/security): pip-audit e Trivy (num contentor, sem instalação)
TRIVY_IMAGE     ?= aquasec/trivy:0.76.1
SECURITY_REPORTS := tests/security/reports

THIRD_PARTY_RE  := keycloak|postgres|prometheus|grafana|busybox|ingress
PIPELINE_COMPOSE_PROJECT := projeto-final-devops

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

STG_WEB_URL             := http://127.0.0.1:$(STG_WEB_PORT)
STG_USERS_URL           := http://127.0.0.1:$(STG_USERS_PORT)
STG_ORDERS_URL          := http://127.0.0.1:$(STG_ORDERS_PORT)
STG_KEYCLOAK_URL        := http://127.0.0.1:$(STG_KEYCLOAK_PORT)
STG_KEYCLOAK_MGMT_URL   := http://127.0.0.1:$(STG_KEYCLOAK_MGMT_PORT)

# Keycloak no cluster (partilhado por STG e PRD) e observabilidade (só STG: sem Jaeger e sem métricas de PRD)
OBS_PROMETHEUS_PORT   := 9190
OBS_GRAFANA_PORT      := 3100
OBS_KEYCLOAK_PORT     := 8280
OBS_PORTS             := $(OBS_PROMETHEUS_PORT) $(OBS_GRAFANA_PORT) $(OBS_KEYCLOAK_PORT)

# ════════════════════════════════════════════════════════════════════
# FUNÇÕES AUXILIARES
# ════════════════════════════════════════════════════════════════════

forward = $(KUBECTL) port-forward -n $(1) svc/$(2) $(3):$(4) >/dev/null 2>&1 &
wait_ports = for p in $(1); do \
		for i in $$(seq 1 60); do (exec 3<>/dev/tcp/127.0.0.1/$$p) 2>/dev/null && break; \
			[ $$i -eq 60 ] && { echo "✗ O port-forward da porta $$p não ficou ativo em 60 s"; exit 1; }; sleep 1; done; \
	done
helm_unstick = if $(HELM) status $(RELEASE) -n $(1) >/dev/null 2>&1 && ! $(HELM) history $(RELEASE) -n $(1) 2>/dev/null | grep -qw deployed; then echo "Release presa de uma tentativa anterior: a remover antes de instalar."; $(HELM) uninstall $(RELEASE) -n $(1) --wait; fi
define docker_prune
	-$(DOCKER) system prune -af --volumes
	-$(DOCKER) network prune -f
	-$(DOCKER) builder prune -af
endef

cluster_clean_images = for img in $$($(cluster_images) 2>/dev/null | grep -E '$(1)' | grep -v '^sha256:'); do \
		$(call unload_image,$$img) >/dev/null 2>&1 && echo "  removida do cluster: $$img" || true; \
	done

orphan_pvs = for pv in $$($(KUBECTL) get pv --no-headers 2>/dev/null | awk '$$6 ~ /^$(1)\// {print $$1}'); do \
		$(KUBECTL) delete pv $$pv --wait=false && echo "  removido PV órfão: $$pv"; \
	done

define k8s_state
	@echo "===== Estado após a limpeza ====="
	-@$(KUBECTL) get all,pvc,secret,ingress -n $(1) 2>&1 | head -3
	-@echo "  imagens do projeto no cluster: $$($(cluster_images) 2>/dev/null | grep -c '$(IMAGE_REPO)/' || true)"
	-$(DOCKER) system df
endef


# O Prometheus só lê a configuração (ConfigMap prometheus-config) quando arranca: compara-se o
# conteúdo antes e depois do apply e, se mudou, o run-infra reinicia-o.
prometheus_config_sum = { $(KUBECTL) get configmap prometheus-config -n $(NAMESPACE_OBS) -o jsonpath='{.data}' 2>/dev/null || true; } | cksum

rollout = echo "$(KUBECTL) rollout status deployment/$(1) -n $(2) --timeout=$(3)"; \
	$(KUBECTL) rollout status deployment/$(1) -n $(2) --timeout=$(3) || { \
		echo "✗ $(1) não ficou pronto em $(3). Diagnóstico:"; \
		$(KUBECTL) get pods,pvc -n $(2) -o wide; \
		$(KUBECTL) describe pods -n $(2) -l app=$(1) | sed -n '/^Events:/,$$p'; \
		$(KUBECTL) logs -n $(2) deployment/$(1) --tail=30; \
		exit 1; }

image = $(IMAGE_REPO)/$(1):$(2)

.DEFAULT_GOAL := help

.PHONY: help check \
	build-dev run-dev test-dev demo-dev token-dev info-dev logs-dev stop-dev clean-dev \
	build-stg run-stg test-stg integration-stg prepare-prd demo-stg forward-stg info-stg stop-stg clean-stg \
	push-prd run-prd forward-prd status-prd info-prd stop-prd clean-prd \
	kubeconfig run-infra reset-keycloak forward-infra clean-infra \
	security security-deps security-images sonar sonar-up sonar-down clean-sonar \
	lint zip clean

# ════════════════════════════════════════════════════════════════════
# HELP
# ════════════════════════════════════════════════════════════════════

help: ## Lista todos os comandos disponíveis
	@echo ""
	@echo "Fluxo:  build-dev → run-dev → test-dev   |   build-stg → run-stg → test-stg   |   run-prd"
	@echo "        (PRD não constrói nem gera nada: usa as imagens e o certificado preparados e validados em STG)"
	@echo ""
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-16s\033[0m %s\n", $$1, $$2}'

# Verifica, antes do primeiro build, os programas, as permissões e a memória da máquina.
check: ## Verifica pré-requisitos e permissões da máquina (correr antes do primeiro build)
	@echo "===== Pré-requisitos e permissões (cluster: $(CLUSTER)) ====="
	@ok=1; \
	need() { if command -v "$$1" >/dev/null 2>&1; then echo "  ✓ $$1"; else echo "  ✗ $$1 em falta — $$2"; ok=0; fi; }; \
	need make "sudo apt install make"; \
	need git "sudo apt install git"; \
	need curl "sudo apt install curl"; \
	need openssl "sudo apt install openssl"; \
	need $(PYTHON) "sudo apt install python3"; \
	if $(PYTHON) -c 'import venv, ensurepip' >/dev/null 2>&1; then echo "  ✓ módulo venv do Python"; \
	else echo "  ✗ módulo venv do Python em falta — sudo apt install python3-venv"; ok=0; fi; \
	need docker "instalar o Docker Engine: https://docs.docker.com/engine/install/ubuntu/"; \
	if docker info >/dev/null 2>&1; then echo "  ✓ Docker acessível sem sudo"; \
	else echo "  ✗ o utilizador $$USER não acede ao Docker — sudo usermod -aG docker $$USER e voltar a iniciar sessão"; ok=0; fi; \
	if $(COMPOSE) version >/dev/null 2>&1; then echo "  ✓ Docker Compose ($(COMPOSE))"; \
	else echo "  ✗ Docker Compose em falta — sudo apt install docker-compose-plugin"; ok=0; fi; \
	need helm "sudo snap install helm --classic"; \
	if [ "$(CLUSTER)" = microk8s ]; then \
		need fuser "sudo apt install psmisc"; \
		if snap list microk8s >/dev/null 2>&1; then echo "  ✓ MicroK8s instalado"; \
		else echo "  ✗ MicroK8s em falta — sudo snap install microk8s --classic"; ok=0; fi; \
		echo "  … sudo (pode pedir a password do utilizador):"; \
		if sudo -v; then echo "  ✓ permissões de sudo"; \
		else echo "  ✗ o utilizador $$USER não tem sudo — necessário para o MicroK8s e o /etc/hosts"; ok=0; fi; \
	else need kind "https://kind.sigs.k8s.io/"; need kubectl "https://kubernetes.io/docs/tasks/tools/"; fi; \
	if [ -r /proc/meminfo ]; then \
		mem=$$(awk '/MemTotal/ {printf "%d", $$2/1024/1024 + 0.5}' /proc/meminfo); \
		if [ $$mem -ge 8 ]; then echo "  ✓ memória: $$mem GB"; \
		else echo "  ! memória: $$mem GB — recomendam-se 8 GB (DEV e STG não correm em simultâneo; ver README)"; fi; \
	fi; \
	if [ $$ok = 1 ]; then echo "===== Máquina pronta ✅ ====="; else echo "===== Corrigir os pontos assinalados com ✗ e voltar a correr make check ====="; exit 1; fi

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

kubeconfig: ## [K8S] Gera o kubeconfig que o Helm usa (arranca o MicroK8s se estiver parado)
	@$(cluster_up) \
	umask 077; \
	if $(KUBECONFIG_CMD) > $(KUBECONFIG_FILE).tmp 2> $(KUBECONFIG_FILE).err && [ -s $(KUBECONFIG_FILE).tmp ]; then \
		mv $(KUBECONFIG_FILE).tmp $(KUBECONFIG_FILE); rm -f $(KUBECONFIG_FILE).err; \
	else \
		echo "✗ Não foi possível obter o kubeconfig do cluster ($(KUBECONFIG_CMD)):"; \
		sed 's/^/    /' $(KUBECONFIG_FILE).err; \
		rm -f $(KUBECONFIG_FILE).tmp $(KUBECONFIG_FILE).err; \
		echo "  $(CLUSTER_HINT)"; \
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
	@echo "  Jaeger (só em DEV)          $(DEV_JAEGER_URL)      sem login"
	@echo "  SonarQube (make security)   $(SONAR_URL)       $(SONAR_USER) / $(SONAR_PASSWORD)"
	@echo ""
	@echo "  Criar/editar/apagar clientes e encomendas: no site, ou make demo-dev (README, secção 6)"
	@echo ""

test-dev: $(STAMP_DEV) ## [DEV] Para o ambiente DEV e corre os testes unitários e de vulnerabilidades (pip-audit, Trivy, SonarQube)
	@$(MAKE) --no-print-directory stop-dev
	@echo "===== [DEV] Testes unitários — service-users ====="
	cd service-users && ../$(VENV_PY) -m pytest tests/ -v
	@echo "===== [DEV] Testes unitários — service-orders ====="
	cd service-orders && ../$(VENV_PY) -m pytest tests/ -v
	@$(MAKE) --no-print-directory security
	@echo "===== [DEV] Testes concluídos ✅  (o ambiente foi parado: make run-dev para o voltar a subir) ====="

security: security-deps sonar ## [DEV] Testes de vulnerabilidades: dependências (pip-audit, Trivy) e código (SonarQube)

security-deps: $(STAMP_STG) ## [DEV/STG] Vulnerabilidades das dependências Python (pip-audit e Trivy) — tests/security
	@echo "===== [SEGURANÇA] pip-audit e Trivy — dependências (relatórios em $(SECURITY_REPORTS)) ====="
	TRIVY_IMAGE=$(TRIVY_IMAGE) TRIVY_IMAGES= $(VENV_PY) -m pytest tests/security -v

security-images: $(STAMP_STG) ## [STG] Vulnerabilidades das imagens que seguem para PRD (Trivy)
	@echo "===== [SEGURANÇA] Trivy — imagens $(STG_TAG) (relatórios em $(SECURITY_REPORTS)) ====="
	TRIVY_IMAGE=$(TRIVY_IMAGE) TRIVY_IMAGES="$(foreach s,$(SERVICES),$(IMAGE_REPO)/$(s):$(STG_TAG))" \
		$(VENV_PY) -m pytest tests/security -v -k trivy_imagem

sonar: sonar-up $(STAMP_STG) ## [DEV] Vulnerabilidades e qualidade do código Python (SonarQube)
	@echo "===== [SEGURANÇA] SonarQube — análise do código Python ====="
	@mkdir -p $(SECURITY_REPORTS)
	@TOKEN_NAME=make-$$(date +%s); \
	TOKEN=$$(curl -fsS -u $(SONAR_USER):$(SONAR_PASSWORD) -X POST $(SONAR_URL)/api/user_tokens/generate -d name=$$TOKEN_NAME \
		| $(VENV_PY) -c 'import json, sys; print(json.load(sys.stdin)["token"])'); \
	trap "curl -fsS -u $(SONAR_USER):$(SONAR_PASSWORD) -X POST $(SONAR_URL)/api/user_tokens/revoke -d name=$$TOKEN_NAME >/dev/null; $(SONAR_COMPOSE) stop sonarqube >/dev/null 2>&1" EXIT; \
	$(VENV_DIR)/bin/pysonar --sonar-host-url $(SONAR_URL) --sonar-token "$$TOKEN" \
		-Dsonar.scanner.arch=$(SONAR_ARCH) -Dsonar.qualitygate.wait=true && rc=0 || rc=$$?; \
	{ echo "# SonarQube — projeto-final ($$(date '+%Y-%m-%d %H:%M'))"; \
	  curl -fsS -u $(SONAR_USER):$(SONAR_PASSWORD) "$(SONAR_URL)/api/qualitygates/project_status?projectKey=projeto-final" \
		| $(VENV_PY) -c 'import json,sys; print("Quality gate:", json.load(sys.stdin)["projectStatus"]["status"])'; \
	  curl -fsS -u $(SONAR_USER):$(SONAR_PASSWORD) "$(SONAR_URL)/api/issues/search?componentKeys=projeto-final&resolved=false&ps=500" \
		| $(VENV_PY) -c 'import json,sys; d=json.load(sys.stdin); print("Issues em aberto:", d["total"]); [print("-", i["component"].split(":",1)[-1], "L%s" % i.get("line","-"), i["message"]) for i in d["issues"]]'; \
	} > $(SECURITY_REPORTS)/sonarqube.txt 2>&1 || true; \
	cat $(SECURITY_REPORTS)/sonarqube.txt; \
	echo "  (SonarQube parado para libertar memória; painel: make sonar-up e $(SONAR_URL))"; \
	exit $$rc

sonar-up: ## [DEV/STG] Arranca o SonarQube local e configura o quality gate de segurança
	@echo "===== [SONARQUBE] A arrancar o servidor ($(SONAR_URL)) ====="
	@$(SONAR_COMPOSE) up -d --quiet-pull sonarqube
	@for i in $$(seq 1 60); do \
		curl -fsS $(SONAR_URL)/api/system/status 2>/dev/null | grep -q '"status":"UP"' && break; \
		if [ $$i -eq 60 ]; then echo "✗ O SonarQube não ficou pronto em $(SONAR_URL)"; exit 1; fi; \
		sleep 5; \
	done
	@if [ "$$(curl -s -o /dev/null -w '%{http_code}' -u admin:admin $(SONAR_URL)/api/user_tokens/search)" = 200 ] \
		&& [ "$(SONAR_USER):$(SONAR_PASSWORD)" != "admin:admin" ]; then \
		curl -fsS -u admin:admin -X POST $(SONAR_URL)/api/users/change_password \
			-d login=admin -d previousPassword=admin --data-urlencode "password=$(SONAR_PASSWORD)"; \
	fi
	@if [ "$$(curl -s -o /dev/null -w '%{http_code}' -u $(SONAR_USER):$(SONAR_PASSWORD) $(SONAR_URL)/api/user_tokens/search)" != 200 ]; then \
		echo "✗ Credenciais do SonarQube recusadas para '$(SONAR_USER)'. Indicar a password atual: make <target> SONAR_PASSWORD=..."; \
		exit 1; \
	fi
	@# Quality gate "Segurança": falha só com problemas de segurança. O SonarQube junta condições
	@# de "código novo" (cobertura, duplicação) a cada gate criado; são retiradas aqui, em cada execução.
	@curl -fsS -o /dev/null -u $(SONAR_USER):$(SONAR_PASSWORD) -G $(SONAR_URL)/api/qualitygates/show \
		--data-urlencode "name=$(SONAR_GATE)" 2>/dev/null \
		|| curl -fsS -o /dev/null -u $(SONAR_USER):$(SONAR_PASSWORD) -X POST $(SONAR_URL)/api/qualitygates/create \
			--data-urlencode "name=$(SONAR_GATE)"
	@for id in $$(curl -fsS -u $(SONAR_USER):$(SONAR_PASSWORD) -G $(SONAR_URL)/api/qualitygates/show --data-urlencode "name=$(SONAR_GATE)" \
		| $(PYTHON) -c 'import json,sys; [print(c["id"]) for c in json.load(sys.stdin).get("conditions", []) if c["metric"] != "software_quality_security_issues"]'); do \
		curl -fsS -o /dev/null -u $(SONAR_USER):$(SONAR_PASSWORD) -X POST $(SONAR_URL)/api/qualitygates/delete_condition -d id=$$id; \
	done
	@curl -fsS -u $(SONAR_USER):$(SONAR_PASSWORD) -G $(SONAR_URL)/api/qualitygates/show --data-urlencode "name=$(SONAR_GATE)" \
		| grep -q software_quality_security_issues \
		|| curl -fsS -o /dev/null -u $(SONAR_USER):$(SONAR_PASSWORD) -X POST $(SONAR_URL)/api/qualitygates/create_condition \
			--data-urlencode "gateName=$(SONAR_GATE)" -d metric=software_quality_security_issues -d op=GT -d error=0
	@curl -fsS -o /dev/null -u $(SONAR_USER):$(SONAR_PASSWORD) -X POST $(SONAR_URL)/api/qualitygates/set_as_default \
		--data-urlencode "name=$(SONAR_GATE)"

sonar-down: ## [DEV/STG] Para o SonarQube (mantém as análises anteriores)
	$(SONAR_COMPOSE) stop sonarqube

clean-sonar: ## Remove o SonarQube: contentor, volumes (análises) e imagem
	-$(SONAR_COMPOSE) rm -fsv sonarqube
	-for v in sonarqube-data sonarqube-extensions sonarqube-logs; do \
		$(DOCKER) volume ls -q --filter label=com.docker.compose.volume=$$v | xargs -r $(DOCKER) volume rm; \
	done
	-$(DOCKER) image ls -q sonarqube | xargs -r $(DOCKER) image rm
	rm -rf .scannerwork

demo-dev: ## [DEV] Cria, edita e apaga um utilizador e uma encomenda (ciclo completo)
	@USERS_URL=$(DEV_USERS_URL) ORDERS_URL=$(DEV_ORDERS_URL) KEYCLOAK_BASE_URL=$(DEV_KEYCLOAK_URL) \
		$(PYTHON) scripts/demo.py --username '$(DEMO_USERNAME)' --password '$(DEMO_PASSWORD)'

token-dev: $(STAMP_DEV) ## [DEV]  Imprime um token de acesso (para o Swagger ou curl)
	@$(VENV_PY) scripts/get_token.py --grant password \
		--token-url $(DEV_KEYCLOAK_URL)$(TOKEN_PATH) \
		--username '$(DEMO_USERNAME)' --password '$(DEMO_PASSWORD)'

logs-dev: ## [DEV] Acompanha os logs dos containers
	$(COMPOSE) logs -f

stop-dev: ## [DEV] Para os containers, incluindo o SonarQube (mantém dados e imagens)
	@echo "===== [DEV] A parar Docker Compose (inclui o SonarQube) ====="
	$(SONAR_COMPOSE) down

clean-dev: ## [DEV] Limpeza Docker completa: compose down, stop, system/volume/network/builder prune, .venv e temporários
	@echo "===== [CLEAN DEV] Docker Compose: contentores, volumes, imagens e órfãos ====="
	-$(COMPOSE) -f docker-compose.yml down -v --rmi all --remove-orphans
	-$(COMPOSE) -p $(PIPELINE_COMPOSE_PROJECT) down -v --rmi all --remove-orphans
	@echo "===== [CLEAN DEV] Parar todos os contentores ====="
	-$(DOCKER) stop $$($(docker_containers)) 2>/dev/null || true
	@echo "===== [CLEAN DEV] Docker: imagens, contentores, volumes, redes e cache de build ====="
	-$(DOCKER) system prune -af --volumes
	-$(DOCKER) volume prune -af
	-$(DOCKER) network prune -f
	-$(DOCKER) builder prune -af
	@echo "===== [CLEAN DEV] Ambiente virtual e ficheiros temporários ====="
	rm -rf $(VENV_DIR) venv .pytest_cache .coverage htmlcov
	find . -type d \( -name "__pycache__" -o -name ".pytest_cache" \) -prune -exec rm -rf {} +
	find . -type f \( -name "*.pyc" -o -name "*.pid" -o -name "*.log" -o -name "*.db" \) -not -path "./.git/*" -delete
	@echo "===== [CLEAN DEV] Espaço ocupado pelo Docker após a limpeza ====="
	-$(DOCKER) system df

# ════════════════════════════════════════════════════════════════════
# INFRAESTRUTURA PARTILHADA NO CLUSTER — Keycloak + Observabilidade
# (aplicada por run-stg. O Keycloak serve STG e PRD; Prometheus e Grafana monitorizam só STG)
# ════════════════════════════════════════════════════════════════════

run-infra: ## [K8S] Aplica Keycloak, Prometheus e Grafana no cluster
	@echo "===== [K8S] Addons do cluster (DNS e armazenamento) ====="
	$(enable_addons)
	@echo "===== [K8S] Keycloak (namespace $(NAMESPACE_AUTH)) ====="
	$(KUBECTL) apply -f k8s/auth/keycloak.yaml -f k8s/auth/networkpolicy.yaml
	@echo "===== [K8S] Observabilidade (namespace $(NAMESPACE_OBS)) ====="
	@antes=$$($(prometheus_config_sum)); \
	$(KUBECTL) apply \
		-f k8s/observability/namespace.yaml \
		-f k8s/observability/networkpolicy.yaml \
		-f k8s/observability/prometheus.yaml \
		-f k8s/observability/grafana.yaml; \
	depois=$$($(prometheus_config_sum)); \
	if [ "$$antes" != "$$(printf '' | cksum)" ] && [ "$$antes" != "$$depois" ]; then \
		echo "===== [K8S] Configuração do Prometheus alterada: a reiniciar para a carregar ====="; \
		$(KUBECTL) rollout restart deployment/prometheus -n $(NAMESPACE_OBS); \
	fi
	@echo "===== [K8S] A aguardar que fiquem prontos ====="
	@$(call rollout,keycloak,$(NAMESPACE_AUTH),600s)
	@$(call rollout,prometheus,$(NAMESPACE_OBS),180s)
	@$(call rollout,grafana,$(NAMESPACE_OBS),180s)

reset-keycloak: ## [K8S] Repõe o Keycloak a partir de realm-export.json (apaga contas criadas à mão)
	@echo "===== [K8S] A apagar os dados do Keycloak para reimportar o realm ====="
	-$(KUBECTL) delete deployment keycloak -n $(NAMESPACE_AUTH) --ignore-not-found --wait=true
	-$(KUBECTL) delete pvc keycloak-data-pvc -n $(NAMESPACE_AUTH) --ignore-not-found --wait=true
	$(KUBECTL) apply -f k8s/auth/keycloak.yaml -f k8s/auth/networkpolicy.yaml
	@$(call rollout,keycloak,$(NAMESPACE_AUTH),600s)
	@echo "===== [K8S] Keycloak reposto: login admin / admin ====="

forward-infra: ## [K8S] Port-forward de Grafana e Prometheus (STG) e da consola do Keycloak
	@echo ""
	@echo "===== [K8S] Observabilidade de STG (não há em PRD) e consola do Keycloak ====="
	@echo "  Grafana                   http://localhost:$(OBS_GRAFANA_PORT)      admin / admin"
	@echo "  Prometheus                http://localhost:$(OBS_PROMETHEUS_PORT)      sem login"
	@echo "  Keycloak (consola admin)  http://localhost:$(OBS_KEYCLOAK_PORT)      admin / admin"
	@echo "  Ctrl+C para sair."
	@echo ""
	@$(sudo_refresh)
	@$(call kill_ports,$(OBS_PORTS)); \
	trap '$(call kill_ports,$(OBS_PORTS))' EXIT INT TERM; \
	$(call forward,$(NAMESPACE_OBS),grafana,$(OBS_GRAFANA_PORT),3000) \
	$(call forward,$(NAMESPACE_OBS),prometheus,$(OBS_PROMETHEUS_PORT),9090) \
	$(call forward,$(NAMESPACE_AUTH),keycloak,$(OBS_KEYCLOAK_PORT),8080) \
	wait

clean-infra: ## [K8S] Remove Keycloak, monitorização, Ingress controller, RBAC de cluster e imagens de terceiros
	@echo "===== [CLEAN K8S] Namespaces $(NAMESPACE_AUTH) e $(NAMESPACE_OBS) (inclui PVCs e Secrets) ====="
	-@$(MAKE) --no-print-directory kubeconfig
	-$(KUBECTL) delete namespace $(NAMESPACE_AUTH) $(NAMESPACE_OBS) --ignore-not-found --wait=true --timeout=180s
	@echo "===== [CLEAN K8S] Recursos de cluster do Prometheus ====="
	-$(KUBECTL) delete clusterrolebinding prometheus-scraper --ignore-not-found
	-$(KUBECTL) delete clusterrole prometheus-scraper --ignore-not-found
	@echo "===== [CLEAN K8S] Ingress controller ====="
	-$(disable_ingress)
	@echo "===== [CLEAN K8S] Imagens de terceiros carregadas no cluster ====="
	-@for img in $$($(cluster_images) 2>/dev/null | grep -E '$(THIRD_PARTY_RE)' | grep -v '^sha256:'); do \
		$(call unload_image,$$img) >/dev/null 2>&1 && echo "  removida $$img" || true; \
	done

# ════════════════════════════════════════════════════════════════════
# STG — MicroK8s + Helm  (ambiente onde se testa antes de promover para PRD)
# ════════════════════════════════════════════════════════════════════

build-stg: ## [STG] Limpa DEV (clean-dev), constrói as imagens (com os pacotes de PRD) e o certificado TLS de PRD
	@$(MAKE) --no-print-directory clean-dev
	@$(MAKE) --no-print-directory $(STAMP_STG)
	@for svc in $(SERVICES); do \
		echo "===== [STG] A construir $(IMAGE_REPO)/$$svc:$(STG_TAG) ====="; \
		$(DOCKER) build -t $(IMAGE_REPO)/$$svc:$(STG_TAG) ./$$svc; \
		echo "===== [STG] A carregar a imagem no cluster ($(CLUSTER)) ====="; \
		$(call load_image,$(IMAGE_REPO)/$$svc:$(STG_TAG)); \
	done
	@mkdir -p $(CERT_DIR)
	@if [ ! -f $(CERT_DIR)/tls.crt ]; then \
		echo "===== [STG] A gerar o certificado TLS de PRD ($(PRD_HOST)) ====="; \
		openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
			-keyout $(CERT_DIR)/tls.key -out $(CERT_DIR)/tls.crt \
			-subj "/CN=$(PRD_HOST)" -addext "subjectAltName=DNS:$(PRD_HOST)" 2>/dev/null; \
		chmod 600 $(CERT_DIR)/tls.key; \
	fi
	$(HELM) lint ./helm -f ./helm/values-staging.yaml
	$(HELM) lint ./helm -f ./helm/values-production.yaml
	@echo "===== [STG] Build concluído ✅  (seguinte: make run-stg) ====="

run-stg: kubeconfig run-infra ## [STG] Faz o deploy em Staging (Helm) e prepara o Ingress controller de PRD
	@echo "===== [STG] Ingress controller (usado por PRD) ====="
	$(enable_ingress)
	@echo "===== [STG] Deploy via Helm ====="
	@$(call helm_unstick,$(NAMESPACE_STG))
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
	@echo "  Grafana / Prometheus / Keycloak         make forward-infra"
	@echo ""

test-stg: integration-stg ## [STG] Testes de integração, smoke e de vulnerabilidades (pip-audit, Trivy às imagens); se passarem, prepara PRD
	@$(MAKE) --no-print-directory security-deps
	@$(MAKE) --no-print-directory security-images
	@echo "===== [STG] ✅ Staging validado — a preparar PRD ====="
	@$(MAKE) --no-print-directory prepare-prd

integration-stg: $(STAMP_STG) ## [STG] Apenas os testes de integração e smoke contra Staging (sem preparar PRD)
	@echo "===== [STG] A abrir port-forwards e a executar os testes ====="
	@$(sudo_refresh)
	@$(call kill_ports,$(STG_PORTS)); \
	trap '$(call kill_ports,$(STG_PORTS))' EXIT; \
	$(call forward,$(NAMESPACE_STG),service-users,$(STG_USERS_PORT),8002) \
	$(call forward,$(NAMESPACE_STG),service-orders,$(STG_ORDERS_PORT),8001) \
	$(call forward,$(NAMESPACE_AUTH),keycloak,$(STG_KEYCLOAK_PORT),8080) \
	$(call forward,$(NAMESPACE_AUTH),keycloak,$(STG_KEYCLOAK_MGMT_PORT),9000) \
	$(call forward,$(NAMESPACE_STG),web,$(STG_WEB_PORT),8080) \
	$(call wait_ports,$(STG_PORTS)); \
	WEB_URL=$(STG_WEB_URL) \
	USERS_URL=$(STG_USERS_URL) \
	ORDERS_URL=$(STG_ORDERS_URL) \
	KEYCLOAK_BASE_URL=$(STG_KEYCLOAK_URL) \
	KEYCLOAK_MGMT_URL=$(STG_KEYCLOAK_MGMT_URL) \
	$(VENV_PY) -m pytest tests/integration/ tests/smoke/ -v

prepare-prd: kubeconfig
	@echo "===== [STG→PRD] Promoção das imagens validadas ($(STG_TAG) → $(PRD_TAG), sem novo build) ====="
	@for svc in $(SERVICES); do \
		$(DOCKER) image inspect $(IMAGE_REPO)/$$svc:$(STG_TAG) >/dev/null 2>&1 || { echo "✗ Falta a imagem $$svc:$(STG_TAG): make build-stg"; exit 1; }; \
		$(DOCKER) tag $(IMAGE_REPO)/$$svc:$(STG_TAG) $(IMAGE_REPO)/$$svc:$(PRD_TAG); \
		$(call load_image,$(IMAGE_REPO)/$$svc:$(PRD_TAG)); \
	done
	@echo "===== [STG→PRD] Certificado TLS de PRD no cluster ====="
	@[ -f $(CERT_DIR)/tls.crt ] || { echo "✗ Falta o certificado em $(CERT_DIR): make build-stg"; exit 1; }
	@for ns in $(NAMESPACE_PRD) $(NAMESPACE_AUTH); do \
		$(KUBECTL) create namespace $$ns --dry-run=client -o yaml | $(KUBECTL) apply -f - >/dev/null; \
		$(KUBECTL) create secret tls $(TLS_SECRET) -n $$ns \
			--cert=$(CERT_DIR)/tls.crt --key=$(CERT_DIR)/tls.key \
			--dry-run=client -o yaml | $(KUBECTL) apply -f -; \
	done
	@echo "===== [STG] ✅ PRD está pronto a subir: make run-prd ====="

demo-stg: ## [STG] Cria, edita e apaga um utilizador e uma encomenda em Staging
	@$(sudo_refresh)
	@$(call kill_ports,$(STG_PORTS)); \
	trap '$(call kill_ports,$(STG_PORTS))' EXIT; \
	$(call forward,$(NAMESPACE_STG),service-users,$(STG_USERS_PORT),8002) \
	$(call forward,$(NAMESPACE_STG),service-orders,$(STG_ORDERS_PORT),8001) \
	$(call forward,$(NAMESPACE_AUTH),keycloak,$(STG_KEYCLOAK_PORT),8080) \
	$(call wait_ports,$(STG_USERS_PORT) $(STG_ORDERS_PORT) $(STG_KEYCLOAK_PORT)); \
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
	@$(sudo_refresh)
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

clean-stg: ## [STG] Limpeza completa de STG (lógica das aulas): release, namespace, PVs órfãos, imagens e cache Docker, certificado
	@echo "===== [CLEAN STG] Parar e remover a aplicação (Helm) ====="
	-@$(MAKE) --no-print-directory kubeconfig
	-$(HELM) uninstall $(RELEASE) -n $(NAMESPACE_STG) --wait
	@echo "===== [CLEAN STG] Namespace $(NAMESPACE_STG): pods, services, volumes (PVC), secrets, network policies ====="
	-$(KUBECTL) delete namespace $(NAMESPACE_STG) --ignore-not-found --wait=true --timeout=180s
	@echo "===== [CLEAN STG] Volumes persistentes órfãos ====="
	-@$(call orphan_pvs,$(NAMESPACE_STG))
	@echo "===== [CLEAN STG] Imagens do projeto no cluster (todas as tags) ====="
	-@$(call cluster_clean_images,$(IMAGE_REPO)/)
	@echo "===== [CLEAN STG] Docker: imagens construídas em STG, contentores parados, redes e cache de build ====="
	-@for img in $$($(DOCKER) images --format '{{.Repository}}:{{.Tag}}' | grep '^$(IMAGE_REPO)/'); do \
		$(DOCKER) image rm -f $$img >/dev/null 2>&1 && echo "  removida do Docker: $$img" || true; \
	done
	$(docker_prune)
	@echo "===== [CLEAN STG] Certificado TLS de PRD (gerado em STG) e port-forwards ====="
	rm -rf $(CERT_DIR)
	@$(call kill_ports,$(STG_PORTS))
	$(call k8s_state,$(NAMESPACE_STG))

# ════════════════════════════════════════════════════════════════════
# PRD — MicroK8s + Helm + Ingress HTTPS
# ════════════════════════════════════════════════════════════════════

push-prd: ## [PRD] (opcional) Publica no registry as imagens promovidas por STG (requer docker login ghcr.io)
	@for svc in $(SERVICES); do \
		$(DOCKER) push $(IMAGE_REPO)/$$svc:$(PRD_TAG); \
	done

run-prd: kubeconfig ## [PRD] Sobe Produção (Helm + Ingress HTTPS) com o que STG preparou
	@echo "===== [PRD] Pré-requisitos preparados e validados em STG ====="
	@ok=1; \
	for svc in $(SERVICES); do \
		$(DOCKER) image inspect $(IMAGE_REPO)/$$svc:$(PRD_TAG) >/dev/null 2>&1 || { echo "  ✗ imagem $$svc:$(PRD_TAG) em falta"; ok=0; }; \
	done; \
	for ns in $(NAMESPACE_PRD) $(NAMESPACE_AUTH); do \
		$(KUBECTL) get secret $(TLS_SECRET) -n $$ns >/dev/null 2>&1 || { echo "  ✗ certificado TLS em falta no namespace $$ns"; ok=0; }; \
	done; \
	$(KUBECTL) get deployment keycloak -n $(NAMESPACE_AUTH) >/dev/null 2>&1 || { echo "  ✗ Keycloak não instalado"; ok=0; }; \
	if [ $$ok = 0 ]; then echo "PRD não está preparado. Executar primeiro: make build-stg run-stg test-stg"; exit 1; fi; \
	echo "  ✓ imagens, certificado e Keycloak presentes"
	@echo "===== [PRD] Endpoint de token do Keycloak atrás do Ingress HTTPS ====="
	sed -e 's/__PRD_HOST__/$(PRD_HOST)/g' -e 's/__INGRESS_CLASS__/$(INGRESS_CLASS)/g' \
		k8s/ingress/keycloak-token-prd.yaml | $(KUBECTL) apply -f -
	@echo "===== [PRD] Start via Helm ====="
	@$(call helm_unstick,$(NAMESPACE_PRD))
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
	@echo "  BACKOFFICE     $(PRD_URL)/          $(DEMO_USERNAME) / $(DEMO_PASSWORD)"
	@echo "  API            $(PRD_URL)/users  ·  $(PRD_URL)/orders"
	@echo "  Token          $(PRD_URL)$(TOKEN_PATH)"
	@echo ""
	@echo "  1) O host tem de resolver para a máquina do cluster (só uma vez):"
	@echo "       echo '127.0.0.1 $(PRD_HOST)' | sudo tee -a /etc/hosts"
ifeq ($(CLUSTER),kind)
	@echo "  2) Cluster kind: deixar a correr noutro terminal   make forward-prd"
endif
	@echo "  Certificado self-signed: o browser mostra um aviso na primeira visita."
	@echo "  Como usar: README, secções 4.3 e 6."
	@echo ""

forward-prd: ## [PRD] Abre o acesso HTTPS ao Ingress (só necessário em cluster kind)
ifeq ($(CLUSTER),kind)
	@echo ""
	@echo "===== [PRD] Acesso HTTPS ativo: $(PRD_URL)/ ====="
	@echo "  Ctrl+C para sair."
	@echo ""
	@$(sudo_refresh)
	@$(call kill_ports,$(PRD_PORT)); \
	trap '$(call kill_ports,$(PRD_PORT))' EXIT INT TERM; \
	$(call forward,$(INGRESS_NS),ingress-nginx-controller,$(PRD_PORT),443) \
	wait
else
	@echo "No MicroK8s não é necessário: o Ingress já responde em $(PRD_URL)/"
endif

stop-prd: ## [PRD] Remove a release de Produção (mantém namespace, imagens e infraestrutura)
	-@$(MAKE) --no-print-directory kubeconfig
	-$(HELM) uninstall $(RELEASE) -n $(NAMESPACE_PRD) --wait

clean-prd: ## [PRD] Limpeza completa de PRD (lógica das aulas): release, namespace, PVs órfãos, Ingress, TLS, imagens, /etc/hosts
	@echo "===== [CLEAN PRD] Parar e remover a aplicação (Helm) ====="
	-@$(MAKE) --no-print-directory kubeconfig
	-$(HELM) uninstall $(RELEASE) -n $(NAMESPACE_PRD) --wait
	@echo "===== [CLEAN PRD] Namespace $(NAMESPACE_PRD): pods, services, volumes (PVC), secrets, Ingress, HPA ====="
	-$(KUBECTL) delete namespace $(NAMESPACE_PRD) --ignore-not-found --wait=true --timeout=180s
	@echo "===== [CLEAN PRD] Volumes persistentes órfãos ====="
	-@$(call orphan_pvs,$(NAMESPACE_PRD))
	@echo "===== [CLEAN PRD] Ingress do token e Secret TLS no namespace $(NAMESPACE_AUTH) ====="
	-$(KUBECTL) delete ingress keycloak-token -n $(NAMESPACE_AUTH) --ignore-not-found
	-$(KUBECTL) delete secret $(TLS_SECRET) -n $(NAMESPACE_AUTH) --ignore-not-found
	@echo "===== [CLEAN PRD] Imagens promovidas para PRD ($(PRD_TAG)) no cluster e no Docker ====="
	-@$(call cluster_clean_images,$(IMAGE_REPO)/.*:$(PRD_TAG)$$)
	-@for img in $$($(DOCKER) images --format '{{.Repository}}:{{.Tag}}' | grep -E '^$(IMAGE_REPO)/.*:$(PRD_TAG)$$'); do \
		$(DOCKER) image rm -f $$img >/dev/null 2>&1 && echo "  removida do Docker: $$img" || true; \
	done
	$(docker_prune)
	@echo "===== [CLEAN PRD] Entrada $(PRD_HOST) no /etc/hosts e port-forwards ====="
	-@if grep -qE '[[:space:]]$(PRD_HOST)([[:space:]]|$$)' /etc/hosts; then \
		sudo sed -i.bak -E '/[[:space:]]$(PRD_HOST)([[:space:]]|$$)/d' /etc/hosts && sudo rm -f /etc/hosts.bak && echo "  removida"; \
	else echo "  não existe"; fi
	@$(call kill_ports,$(PRD_PORT))
	$(call k8s_state,$(NAMESPACE_PRD))

# ════════════════════════════════════════════════════════════════════
# GERAL
# ════════════════════════════════════════════════════════════════════

lint: ## Valida o Helm chart com os values de cada ambiente
	$(HELM) lint ./helm
	$(HELM) lint ./helm -f ./helm/values-staging.yaml
	$(HELM) lint ./helm -f ./helm/values-production.yaml

zip: ## Gera ProjetoFinal.zip para entrega (só ficheiros do Git; pasta ProjetoFinal/ na raiz do zip)
	@[ -z "$$(git status --porcelain)" ] || { echo "✗ Há alterações por fazer commit: o zip só leva o que está no Git (git status)"; exit 1; }
	@rm -f ProjetoFinal.zip
	git archive --format=zip --prefix=ProjetoFinal/ -o ProjetoFinal.zip HEAD
	@echo "===== ProjetoFinal.zip criado ✅  ($$(du -h ProjetoFinal.zip | cut -f1)) — primeiro nível: ProjetoFinal/ ====="

clean: clean-prd clean-stg clean-infra clean-dev clean-sonar ## Limpa TUDO: PRD, STG, infraestrutura do cluster, DEV e SonarQube
	@rm -f $(KUBECONFIG_FILE).tmp $(KUBECONFIG_FILE).err kubeconfig-*.yaml
	@$(call kill_ports,$(OBS_PORTS))
	@echo ""
	@echo "===== [CLEAN] Tudo removido ✅ ====="
	@echo "  Cluster: releases Helm, namespaces $(NAMESPACE_PRD)/$(NAMESPACE_STG)/$(NAMESPACE_AUTH)/$(NAMESPACE_OBS),"
	@echo "           PVCs, Secrets, Ingress e Ingress controller, ClusterRole/Binding,"
	@echo "           imagens do projeto e imagens de terceiros carregadas no cluster."
	@echo "  Docker:  todos os contentores parados; imagens, volumes, redes e cache de build removidos"
	@echo "           (docker system prune -af --volumes, volume/network/builder prune)."
	@echo "  Local:   $(VENV_DIR), $(CERT_DIR), ficheiros kubeconfig-*.yaml, caches, *.db, port-forwards e a entrada no /etc/hosts."
	@echo "  (O cluster $(CLUSTER) continua instalado.)"
