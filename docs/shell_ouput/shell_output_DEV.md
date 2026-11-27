daniel-almeida@daniel-ubuntu:~/Transferências/ProjetoFinal$ make build-dev
===== [PYTHON] A criar ambiente virtual em .venv =====
/usr/bin/python3.12 -m venv --clear .venv
.venv/bin/python -m pip install --quiet --upgrade pip
===== [PYTHON] A instalar requirements-dev.txt =====
.venv/bin/python -m pip install --quiet -r requirements-dev.txt
===== [DEV] A construir imagens =====
docker compose build
[+] Building 21.5s (33/33) FINISHED                                                                                                             
 => [internal] load local bake definitions                                                                                                 0.0s
 => => reading from stdin 1.74kB                                                                                                           0.0s
 => [service-orders internal] load build definition from Dockerfile                                                                        0.0s
 => => transferring dockerfile: 1.32kB                                                                                                     0.0s
 => [service-users internal] load build definition from Dockerfile                                                                         0.0s
 => => transferring dockerfile: 1.32kB                                                                                                     0.0s
 => [web internal] load build definition from Dockerfile                                                                                   0.0s
 => => transferring dockerfile: 505B                                                                                                       0.0s
 => [service-orders internal] load metadata for docker.io/library/python:3.12-alpine3.24                                                   1.4s 
 => [web internal] load metadata for docker.io/nginxinc/nginx-unprivileged:1.27-alpine                                                     1.4s 
 => [service-orders internal] load .dockerignore                                                                                           0.0s 
 => => transferring context: 158B                                                                                                          0.0s 
 => [service-users internal] load .dockerignore                                                                                            0.0s 
 => => transferring context: 158B                                                                                                          0.0s 
 => [web internal] load .dockerignore                                                                                                      0.0s
 => => transferring context: 57B                                                                                                           0.0s
 => [service-orders 1/7] FROM docker.io/library/python:3.12-alpine3.24@sha256:c5ba3deef00c7758561a0f03c26f44f10589263d40e732b8748e0d1f38f  2.4s
 => => resolve docker.io/library/python:3.12-alpine3.24@sha256:c5ba3deef00c7758561a0f03c26f44f10589263d40e732b8748e0d1f38f6dd89            0.0s
 => => sha256:8ab1992027dfd42035e1028c42f93c50180a2b01b89a2645899d7c9299fcdd5c 251B / 251B                                                 0.2s
 => => sha256:9cee687b648e8e2f38b10079e58e752f383ebe19bea21c5a6657a29703a336f8 13.92MB / 13.92MB                                           1.2s
 => => sha256:6d356b48c1c56cccd22e48f043c1e8ac8d79ef86f9e625b548c82014803b7830 415.54kB / 415.54kB                                         0.7s
 => => sha256:b90627b8f4292fd3cb63f0f27f0b11c37f04ba88ef3b78d4948ea0ace18c85e9 4.19MB / 4.19MB                                             2.1s
 => => extracting sha256:b90627b8f4292fd3cb63f0f27f0b11c37f04ba88ef3b78d4948ea0ace18c85e9                                                  0.0s
 => => extracting sha256:6d356b48c1c56cccd22e48f043c1e8ac8d79ef86f9e625b548c82014803b7830                                                  0.0s
 => => extracting sha256:9cee687b648e8e2f38b10079e58e752f383ebe19bea21c5a6657a29703a336f8                                                  0.2s
 => => extracting sha256:8ab1992027dfd42035e1028c42f93c50180a2b01b89a2645899d7c9299fcdd5c                                                  0.0s
 => [service-orders internal] load build context                                                                                           0.0s
 => => transferring context: 14.60kB                                                                                                       0.0s
 => [service-users internal] load build context                                                                                            0.0s
 => => transferring context: 14.54kB                                                                                                       0.0s
 => [web 1/4] FROM docker.io/nginxinc/nginx-unprivileged:1.27-alpine@sha256:65e3e85dbaed8ba248841d9d58a899b6197106c23cb0ff1a132b7bfe0547e  2.4s
 => => resolve docker.io/nginxinc/nginx-unprivileged:1.27-alpine@sha256:65e3e85dbaed8ba248841d9d58a899b6197106c23cb0ff1a132b7bfe0547e4c0   0.0s
 => => sha256:f23a1d1674912e005f43dd93ab9fdca5c6bcda76013afa034d523a769de5551e 16.03MB / 16.03MB                                           1.1s
 => => sha256:edee89a8728beee0563123f811dd6596a07077f38b5bcd87791da05a7db60fde 1.40kB / 1.40kB                                             0.5s
 => => sha256:0ab5686976ac25d8ac38b59e4690f7a99dce9b343865d7def137b65e662e8c23 1.21kB / 1.21kB                                             0.2s
 => => sha256:04c5cf615192471cc36cb4405a2516eb6443c853c8179c9710575baa9acc39e7 404B / 404B                                                 0.3s
 => => sha256:8d683a284cf1e30b36a23c1dd71f49365d1d6bc348b100e6a0d32683f649ccf9 957B / 957B                                                 0.4s
 => => sha256:513bae533eb237e219e2d3412e0dbb9cd94c25b2b84530b5131fda9512c0e773 627B / 627B                                                 0.3s
 => => sha256:d51f1218ef72c44a300c138c2a1de9a8461ee6063060c1f670f32546b39a3ce7 2.80kB / 2.80kB                                             0.2s
 => => sha256:0a44daad67e98d09449e0547e0f72e69b317d0abe1e579a4f352307161ac8cc9 1.79MB / 1.79MB                                             0.5s
 => => sha256:6e771e15690e2fabf2332d3a3b744495411d6e0b00b2aea64419b58b0066cf81 3.99MB / 3.99MB                                             0.4s
 => => extracting sha256:6e771e15690e2fabf2332d3a3b744495411d6e0b00b2aea64419b58b0066cf81                                                  0.0s
 => => extracting sha256:0a44daad67e98d09449e0547e0f72e69b317d0abe1e579a4f352307161ac8cc9                                                  0.0s
 => => extracting sha256:d51f1218ef72c44a300c138c2a1de9a8461ee6063060c1f670f32546b39a3ce7                                                  0.0s
 => => extracting sha256:513bae533eb237e219e2d3412e0dbb9cd94c25b2b84530b5131fda9512c0e773                                                  0.0s
 => => extracting sha256:8d683a284cf1e30b36a23c1dd71f49365d1d6bc348b100e6a0d32683f649ccf9                                                  0.0s
 => => extracting sha256:04c5cf615192471cc36cb4405a2516eb6443c853c8179c9710575baa9acc39e7                                                  0.0s
 => => extracting sha256:0ab5686976ac25d8ac38b59e4690f7a99dce9b343865d7def137b65e662e8c23                                                  0.0s
 => => extracting sha256:edee89a8728beee0563123f811dd6596a07077f38b5bcd87791da05a7db60fde                                                  0.0s
 => => extracting sha256:f23a1d1674912e005f43dd93ab9fdca5c6bcda76013afa034d523a769de5551e                                                  0.2s
 => [web internal] load build context                                                                                                      0.0s
 => => transferring context: 41.59kB                                                                                                       0.0s
 => [web 2/4] RUN apk upgrade --no-cache                                                                                                   2.5s
 => [service-orders 2/7] WORKDIR /app                                                                                                      0.1s
 => [service-orders 3/7] RUN apk upgrade --no-cache                                                                                        1.2s
 => [service-orders 4/7] COPY requirements-prd.txt requirements-tracing.txt ./                                                             0.0s
 => [service-users 4/7] COPY requirements-prd.txt requirements-tracing.txt ./                                                              0.0s
 => [service-users 5/7] RUN pip install --no-cache-dir -r requirements-prd.txt     && if [ "true" = "true" ]; then pip install --no-cach  12.8s
 => [service-orders 5/7] RUN pip install --no-cache-dir -r requirements-prd.txt     && if [ "true" = "true" ]; then pip install --no-cac  13.7s
 => [web 3/4] COPY nginx.conf.template /etc/nginx/templates/default.conf.template                                                          0.0s
 => [web 4/4] COPY static/ /usr/share/nginx/html/                                                                                          0.0s
 => [web] exporting to image                                                                                                               0.4s
 => => exporting layers                                                                                                                    0.3s
 => => exporting manifest sha256:c63c79434fc24685f9e47febdb4a33561c78d465cac2c20c049582b94373ac88                                          0.0s
 => => exporting config sha256:c18e19e97a3be6507fecadec73ba9438668def17ff1efafcbdcd512d73abb948                                            0.0s
 => => exporting attestation manifest sha256:1504b8cbaf44d1a2d1df7d1f6637a8fc7de0b3c93b786e5e1492066bbd8fa700                              0.0s
 => => exporting manifest list sha256:f33c49f0b355c004ad76aa2384ea47a1b64d0fcaa9ee823bb6221bfba476e9c9                                     0.0s
 => => naming to docker.io/library/projetofinal-web:latest                                                                                 0.0s
 => => unpacking to docker.io/library/projetofinal-web:latest                                                                              0.1s
 => [web] resolving provenance for metadata file                                                                                           0.0s
 => [service-users 6/7] COPY app/ ./app/                                                                                                   0.0s
 => [service-users 7/7] RUN addgroup -g 1000 app &&     adduser -u 1000 -G app -H -D -s /sbin/nologin app &&     chown -R app:app /app     0.1s
 => [service-users] exporting to image                                                                                                     2.4s
 => => exporting layers                                                                                                                    2.0s
 => => exporting manifest sha256:92fed539421465dcca6867806ece9f28ba99773ec078996cecb822e3b377af86                                          0.0s
 => => exporting config sha256:037005738c89f7e800a817cd9f75e87d0cb29718583bb9e39b7dc03bc7e5c8fb                                            0.0s
 => => exporting attestation manifest sha256:265a235b255d52e8423953077bf27094ec04329f089dcc02fcf35180c5b72da5                              0.0s
 => => exporting manifest list sha256:ae49eb3931b841f67b411e2989e7ba79c6e6017679e3d64a044b13400064cd66                                     0.0s
 => => naming to docker.io/library/projetofinal-service-users:latest                                                                       0.0s
 => => unpacking to docker.io/library/projetofinal-service-users:latest                                                                    0.4s
 => [service-orders 6/7] COPY app/ ./app/                                                                                                  0.0s
 => [service-orders 7/7] RUN addgroup -g 1000 app &&     adduser -u 1000 -G app -H -D -s /sbin/nologin app &&     chown -R app:app /app    0.1s
 => [service-orders] exporting to image                                                                                                    2.4s
 => => exporting layers                                                                                                                    2.0s
 => => exporting manifest sha256:38bd7db35a3e322fab82817a3b61d4691f29627dfaf86ca9548ecc60ff02689d                                          0.0s
 => => exporting config sha256:664c5e6ba9b1944e66e9554da3669b507023281f1a940bf9c2fcb57cc6cfab1c                                            0.0s
 => => exporting attestation manifest sha256:6ca67a8dea988a3cc35eddc87e4976d3b78b1f3bcb63c0f34da423d469ce581c                              0.0s
 => => exporting manifest list sha256:f9b849415b3cf39d74e85375f45e07fa78d6e97ae604e6ccb19fb18934e06ef3                                     0.0s
 => => naming to docker.io/library/projetofinal-service-orders:latest                                                                      0.0s
 => => unpacking to docker.io/library/projetofinal-service-orders:latest                                                                   0.4s
 => [service-users] resolving provenance for metadata file                                                                                 0.0s
 => [service-orders] resolving provenance for metadata file                                                                                0.0s
[+] build 3/3
 ✔ Image projetofinal-service-orders Built                                                                                                 21.5s
 ✔ Image projetofinal-service-users  Built                                                                                                 21.5s
 ✔ Image projetofinal-web            Built                                                                                                 21.5s
===== [DEV] Build concluído ✅  (seguinte: make run-dev) =====
daniel-almeida@daniel-ubuntu:~/Transferências/ProjetoFinal$ make run-dev
===== [DEV] A iniciar Docker Compose =====
docker compose up -d --wait
[+] up 54/54
 ✔ Image grafana/grafana:11.3.0             Pulled                                                                                         11.4s
 ✔ Image postgres:16-alpine                 Pulled                                                                                          8.9s
 ✔ Image prom/prometheus:v2.55.1            Pulled                                                                                         11.9s
 ✔ Image jaegertracing/all-in-one:1.60      Pulled                                                                                          5.7s
 ✔ Network projetofinal_app-network         Created                                                                                         0.0s
 ✔ Volume projetofinal_prometheus-data      Created                                                                                         0.0s
 ✔ Volume projetofinal_grafana-data         Created                                                                                         0.0s
 ✔ Volume projetofinal_postgres-orders-data Created                                                                                         0.0s
 ✔ Container projetofinal-postgres-orders-1 Healthy                                                                                        27.8s
 ✔ Container projetofinal-jaeger-1          Healthy                                                                                        27.8s
 ✔ Container projetofinal-service-users-1   Healthy                                                                                        27.6s
 ✔ Container projetofinal-service-orders-1  Healthy                                                                                        27.5s
 ✔ Container projetofinal-prometheus-1      Healthy                                                                                        27.5s
 ... 2 more                                                                                                                                     

===== [DEV] Endereços e credenciais =====
  BACKOFFICE (aplicação)      http://localhost:8000       admin / admin
  API utilizadores (Swagger)  http://localhost:8002/docs  token: make token-dev
  API encomendas   (Swagger)  http://localhost:8001/docs  token: make token-dev
  Grafana                     http://localhost:3000       admin / admin
  Prometheus                  http://localhost:9090       sem login
  Jaeger (só em DEV)          http://localhost:16686      sem login
  SonarQube (make security)   http://localhost:9500       admin / ProjetoFinal.2026

  Criar/editar/apagar clientes e encomendas: no site, ou make demo-dev (README, secção 6)

daniel-almeida@daniel-ubuntu:~/Transferências/ProjetoFinal$ make test-dev
===== [DEV] A parar Docker Compose (inclui o SonarQube) =====
docker compose --profile sonar down
[+] down 2/2
 ✔ Container projetofinal-sonarqube-1 Removed                                                                                               0.0s
 ✔ Network projetofinal_sonar-network Removed                                                                                               0.1s
===== [DEV] Testes unitários — service-users =====
cd service-users && ../.venv/bin/python -m pytest tests/ -v
============================================================= test session starts ==============================================================
platform linux -- Python 3.12.13, pytest-9.1.1, pluggy-1.7.0 -- /home/daniel-almeida/Transferências/ProjetoFinal/service-users/../.venv/bin/python
cachedir: .pytest_cache
rootdir: /home/daniel-almeida/Transferências/ProjetoFinal
configfile: pytest.ini
plugins: platformdirs-4.14.8, anyio-4.16.0
collected 27 items                                                                                                                             

tests/test_users.py::test_health_does_not_require_auth PASSED                                                                            [  3%]
tests/test_users.py::test_metrics_endpoint_does_not_require_auth PASSED                                                                  [  7%]
tests/test_users.py::test_get_existing_user PASSED                                                                                       [ 11%]
tests/test_users.py::test_get_nonexistent_user_returns_404 PASSED                                                                        [ 14%]
tests/test_users.py::test_list_users_returns_all PASSED                                                                                  [ 18%]
tests/test_users.py::test_list_users_without_token_returns_401 PASSED                                                                    [ 22%]
tests/test_users.py::test_get_user_with_wrong_scope_returns_403 PASSED                                                                   [ 25%]
tests/test_users.py::test_get_user_with_expired_token_returns_401 PASSED                                                                 [ 29%]
tests/test_users.py::test_get_user_with_malformed_token_returns_401 PASSED                                                               [ 33%]
tests/test_users.py::test_token_signed_with_another_secret_returns_401 PASSED                                                            [ 37%]
tests/test_users.py::test_token_from_another_issuer_returns_401 PASSED                                                                   [ 40%]
tests/test_users.py::test_login_returns_token_with_all_scopes PASSED                                                                     [ 44%]
tests/test_users.py::test_login_with_wrong_password_returns_401 PASSED                                                                   [ 48%]
tests/test_users.py::test_login_with_unknown_user_returns_401 PASSED                                                                     [ 51%]
tests/test_users.py::test_login_without_fields_returns_422 PASSED                                                                        [ 55%]
tests/test_users.py::test_create_user PASSED                                                                                             [ 59%]
tests/test_users.py::test_create_user_with_duplicate_email_returns_409 PASSED                                                            [ 62%]
tests/test_users.py::test_create_user_with_invalid_email_returns_422 PASSED                                                              [ 66%]
tests/test_users.py::test_create_user_with_read_only_scope_returns_403 PASSED                                                            [ 70%]
tests/test_users.py::test_create_user_without_token_returns_401 PASSED                                                                   [ 74%]
tests/test_users.py::test_delete_user PASSED                                                                                             [ 77%]
tests/test_users.py::test_delete_nonexistent_user_returns_404 PASSED                                                                     [ 81%]
tests/test_users.py::test_delete_user_with_read_only_scope_returns_403 PASSED                                                            [ 85%]
tests/test_users.py::test_update_user PASSED                                                                                             [ 88%]
tests/test_users.py::test_update_nonexistent_user_returns_404 PASSED                                                                     [ 92%]
tests/test_users.py::test_update_user_with_email_of_another_user_returns_409 PASSED                                                      [ 96%]
tests/test_users.py::test_update_user_with_read_only_scope_returns_403 PASSED                                                            [100%]

=============================================================== warnings summary ===============================================================
../.venv/lib/python3.12/site-packages/fastapi/testclient.py:1
  /home/daniel-almeida/Transferências/ProjetoFinal/.venv/lib/python3.12/site-packages/fastapi/testclient.py:1: StarletteDeprecationWarning: Using `httpx` with `starlette.testclient` is deprecated; install `httpx2` instead.
    from starlette.testclient import TestClient as TestClient  # noqa

-- Docs: https://docs.pytest.org/en/stable/how-to/capture-warnings.html
======================================================== 27 passed, 1 warning in 0.41s =========================================================
===== [DEV] Testes unitários — service-orders =====
cd service-orders && ../.venv/bin/python -m pytest tests/ -v
============================================================= test session starts ==============================================================
platform linux -- Python 3.12.13, pytest-9.1.1, pluggy-1.7.0 -- /home/daniel-almeida/Transferências/ProjetoFinal/service-orders/../.venv/bin/python
cachedir: .pytest_cache
rootdir: /home/daniel-almeida/Transferências/ProjetoFinal
configfile: pytest.ini
plugins: platformdirs-4.14.8, anyio-4.16.0
collected 19 items                                                                                                                             

tests/test_orders.py::test_health_does_not_require_auth PASSED                                                                           [  5%]
tests/test_orders.py::test_metrics_endpoint_does_not_require_auth PASSED                                                                 [ 10%]
tests/test_orders.py::test_create_order_success PASSED                                                                                   [ 15%]
tests/test_orders.py::test_create_order_user_not_found PASSED                                                                            [ 21%]
tests/test_orders.py::test_create_order_without_token_returns_401 PASSED                                                                 [ 26%]
tests/test_orders.py::test_create_order_with_read_only_scope_returns_403 PASSED                                                          [ 31%]
tests/test_orders.py::test_get_nonexistent_order_returns_404 PASSED                                                                      [ 36%]
tests/test_orders.py::test_list_orders_without_token_returns_401 PASSED                                                                  [ 42%]
tests/test_orders.py::test_create_order_rejects_zero_or_negative_quantity PASSED                                                         [ 47%]
tests/test_orders.py::test_created_order_is_persisted_and_listed PASSED                                                                  [ 52%]
tests/test_orders.py::test_create_order_calls_users_with_service_token PASSED                                                            [ 57%]
tests/test_orders.py::test_token_signed_with_another_secret_returns_401 PASSED                                                           [ 63%]
tests/test_orders.py::test_delete_order PASSED                                                                                           [ 68%]
tests/test_orders.py::test_delete_nonexistent_order_returns_404 PASSED                                                                   [ 73%]
tests/test_orders.py::test_delete_order_with_read_only_scope_returns_403 PASSED                                                          [ 78%]
tests/test_orders.py::test_update_order PASSED                                                                                           [ 84%]
tests/test_orders.py::test_update_nonexistent_order_returns_404 PASSED                                                                   [ 89%]
tests/test_orders.py::test_update_order_rejects_invalid_quantity PASSED                                                                  [ 94%]
tests/test_orders.py::test_update_order_with_read_only_scope_returns_403 PASSED                                                          [100%]

=============================================================== warnings summary ===============================================================
../.venv/lib/python3.12/site-packages/fastapi/testclient.py:1
  /home/daniel-almeida/Transferências/ProjetoFinal/.venv/lib/python3.12/site-packages/fastapi/testclient.py:1: StarletteDeprecationWarning: Using `httpx` with `starlette.testclient` is deprecated; install `httpx2` instead.
    from starlette.testclient import TestClient as TestClient  # noqa

-- Docs: https://docs.pytest.org/en/stable/how-to/capture-warnings.html
======================================================== 19 passed, 1 warning in 0.34s =========================================================
===== [SEGURANÇA] pip-audit e Trivy — dependências (relatórios em tests/security/reports) =====
TRIVY_IMAGE=aquasec/trivy:0.76.1 TRIVY_IMAGES= .venv/bin/python -m pytest tests/security -v
============================================================= test session starts ==============================================================
platform linux -- Python 3.12.13, pytest-9.1.1, pluggy-1.7.0 -- /home/daniel-almeida/Transferências/ProjetoFinal/.venv/bin/python
cachedir: .pytest_cache
rootdir: /home/daniel-almeida/Transferências/ProjetoFinal
configfile: pytest.ini
plugins: platformdirs-4.14.8, anyio-4.16.0
collected 6 items                                                                                                                              

tests/security/test_vulnerabilidades.py::test_pip_audit_dependencias[service-orders/requirements-prd.txt] PASSED                         [ 16%]
tests/security/test_vulnerabilidades.py::test_pip_audit_dependencias[service-orders/requirements-tracing.txt] PASSED                     [ 33%]
tests/security/test_vulnerabilidades.py::test_pip_audit_dependencias[service-users/requirements-prd.txt] PASSED                          [ 50%]
tests/security/test_vulnerabilidades.py::test_pip_audit_dependencias[service-users/requirements-tracing.txt] PASSED                      [ 66%]
tests/security/test_vulnerabilidades.py::test_trivy_dependencias PASSED                                                                  [ 83%]
tests/security/test_vulnerabilidades.py::test_trivy_imagem[NOTSET] SKIPPED (TRIVY_IMAGES não definido (análise de imagens só em STG))    [100%]

======================================================== 5 passed, 1 skipped in 11.29s =========================================================
===== [SONARQUBE] A arrancar o servidor (http://localhost:9500) =====
[+] up 2/2
 ✔ Network projetofinal_sonar-network Created                                                                                               0.0s
 ✔ Container projetofinal-sonarqube-1 Started                                                                                               0.1s
===== [SEGURANÇA] SonarQube — análise do código Python =====
INFO: Starting Pysonar 1.9.0.5762, the Sonar scanner CLI for Python
INFO: Enhance your workflow: Pair pysonar with SonarQube Server per your license or SonarQube Cloud for deeper analysis, and try SonarQube-IDE in your favourite IDE.
INFO: Starting the analysis...
INFO: Starting SonarScanner Engine...
INFO: Java 21.0.11 Eclipse Adoptium (64-bit)
INFO: Load global settings
INFO: Load global settings (done) | time=74ms
INFO: Server id: 147B411E-AaIcuq7qx4gQ7D0OMVnt
INFO: Loading required plugins
INFO: Load plugins index
INFO: Load plugins index (done) | time=18ms
INFO: Load/download plugins
INFO: Load/download plugins (done) | time=13ms
INFO: Process project properties
INFO: Process project properties (done) | time=7ms
INFO: Project key: projeto-final
INFO: Base dir: /home/daniel-almeida/Transferências/ProjetoFinal
INFO: Working dir: /home/daniel-almeida/Transferências/ProjetoFinal/.scannerwork
INFO: Load project settings for component key: 'projeto-final'
INFO: Load project settings for component key: 'projeto-final' (done) | time=23ms
INFO: Load quality profiles
INFO: Load quality profiles (done) | time=93ms
INFO: Load active rules
INFO: Load active rules (done) | time=260ms
INFO: Load analysis cache
INFO: Load analysis cache | time=16ms
INFO: Preprocessing files...
INFO: 1 language detected in 23 preprocessed files (done) | time=31ms
INFO: 30 files ignored because of scm ignore settings
INFO: Loading plugins for detected languages
INFO: Load/download plugins
INFO: Load/download plugins (done) | time=3ms
INFO: Load project repositories
INFO: Load project repositories (done) | time=55ms
INFO: Indexing files...
INFO: Project configuration:
INFO: 23 files indexed (done) | time=4ms
INFO: Quality profile for py: Sonar way
INFO: ------------- Run sensors on module Projeto Final
INFO: Load metrics repository
INFO: Load metrics repository (done) | time=18ms
INFO: Sensor IaC YAML File Type Classification Sensor [iac]
INFO: Sensor IaC YAML File Type Classification Sensor [iac] (done) | time=1ms
INFO: Sensor IaC hadolint report Sensor [iac]
INFO: Sensor IaC hadolint report Sensor [iac] (done) | time=0ms
INFO: Sensor Java Config Sensor [iac]
INFO: There are no files to be analyzed for the Java language
INFO: Sensor Java Config Sensor [iac] (done) | time=0ms
INFO: Sensor IaC Docker Sensor [iac]
INFO: There are no files to be analyzed for the Docker language
INFO: Sensor IaC Docker Sensor [iac] (done) | time=0ms
INFO: Sensor Python Sensor [python]
INFO: Starting global symbols computation
INFO: 22 source files to be analyzed
INFO: 22/22 source files have been analyzed
INFO: Finished step global symbols computation in 591ms
INFO: Starting rules execution
INFO: 22 source files to be analyzed
INFO: 22/22 source files have been analyzed
INFO: Finished step rules execution in 565ms
INFO: The Python analyzer was able to leverage cached data from previous analyses for 0 out of 22 files. These files were not parsed.
INFO: Sensor Python Sensor [python] (done) | time=1340ms
INFO: Sensor Cobertura Sensor for Python coverage [python]
INFO: Sensor Cobertura Sensor for Python coverage [python] (done) | time=44ms
INFO: Sensor PythonXUnitSensor [python]
INFO: Sensor PythonXUnitSensor [python] (done) | time=24ms
INFO: Sensor Python Dependency Sensor [python]
INFO: Sensor Python Dependency Sensor [python] (done) | time=1ms
INFO: Sensor TextAndSecretsSensor [text]
INFO: Available processors: 10
INFO: Using 10 threads for analysis.
INFO: Start fetching files for the text and secrets analysis
INFO: Using Git CLI to retrieve dirty files
INFO: Retrieving language associated files and files included via "sonar.text.inclusions" that are tracked by git
INFO: Starting the text and secrets analysis
INFO: 22 source files to be analyzed for the text and secrets analysis
INFO: 22/22 source files have been analyzed for the text and secrets analysis
INFO: Sensor TextAndSecretsSensor [text] (done) | time=164ms
INFO: ------------- Run sensors on project
INFO: Sensor IaC Project Sensor [iac]
INFO: Sensor IaC Project Sensor [iac] (done) | time=0ms
INFO: Sensor Zero Coverage Sensor
INFO: Sensor Zero Coverage Sensor (done) | time=4ms
INFO: ------------- Gather SCA dependencies on project
INFO: Dependency analysis skipped
INFO: CPD Executor 2 files had no CPD blocks
INFO: CPD Executor Calculating CPD for 12 files
INFO: CPD Executor CPD calculation finished (done) | time=7ms
INFO: SCM revision ID 'a90925d387e1b5413e374abdd419ad0cde8c334c'
INFO: Analysis report generated in 38ms, dir size=459.8 kB
INFO: Analysis report compressed in 28ms, zip size=140.0 kB
INFO: Analysis report uploaded in 104ms
INFO: ------------- Check Quality Gate status
INFO: Waiting for the analysis report to be processed (max 300s)
INFO: QUALITY GATE STATUS: PASSED - View details on http://localhost:9500/dashboard?id=projeto-final
INFO: Analysis total time: 8.003 s
INFO: SonarScanner Engine completed successfully
# SonarQube — projeto-final (2026-11-27 11:23)
Quality gate: OK
Issues em aberto: 0
  (SonarQube parado para libertar memória; painel: make sonar-up e http://localhost:9500)
===== [SEGURANÇA] Trivy — imagens: nenhuma construída (make build-prd ou make build-stg), passo saltado =====
===== [DEV] Testes concluídos ✅  (o ambiente foi parado: make run-dev para o voltar a subir) =====

daniel-almeida@daniel-ubuntu:~/Transferências/ProjetoFinal$ make clean-dev
===== [CLEAN DEV] Docker Compose: contentores, volumes, imagens e órfãos =====
docker compose -f docker-compose.yml down -v --rmi all --remove-orphans
[+] down 10/10
 ✔ Image projetofinal-service-users:latest  Removed                                                                                         0.4s
 ✔ Image projetofinal-web:latest            Removed                                                                                         0.4s
 ✔ Image jaegertracing/all-in-one:1.60      Removed                                                                                         0.4s
 ✔ Image prom/prometheus:v2.55.1            Removed                                                                                         0.4s
 ✔ Image postgres:16-alpine                 Removed                                                                                         0.4s
 ✔ Image grafana/grafana:11.3.0             Removed                                                                                         0.4s
 ✔ Image projetofinal-service-orders:latest Removed                                                                                         0.4s
 ✔ Volume projetofinal_grafana-data         Removed                                                                                         0.0s
 ✔ Volume projetofinal_prometheus-data      Removed                                                                                         0.0s
 ✔ Volume projetofinal_postgres-orders-data Removed                                                                                         0.0s
docker compose -p projeto-final-devops down -v --rmi all --remove-orphans
WARN[0000] Warning: No resource found to remove for project "projeto-final-devops". 
===== [CLEAN DEV] Parar todos os contentores =====
docker stop $(docker ps -qa) 2>/dev/null || true
d3cf7964c9e5
===== [CLEAN DEV] Docker: imagens, contentores, volumes, redes e cache de build =====
docker system prune -af --volumes
Deleted Containers:
d3cf7964c9e530f651be293412a544eeadd74b0b5b1fc266c122752287cfba78

Deleted Networks:
projetofinal_sonar-network

Deleted Volumes:
e42b7b5ef39f91b347228a6e927fefed8b5ac1dec1445b26fa70ab741856aa5c
a21a1d1c3d54c2fc46f52dac894d916cf12752a9a0f0984025ef2fdd500b2487
d67df3e8011350e6703c23505e886c235859671f5fbffcc65252dd78b4187804
5dbbfcd56ab60ceb0843c20de4e2fa4c11e518f7f48fe8882ceb784ed4ae8b5f
e2920b0c42cda969dd9154727137ef025a04d9924ec50621243641048b8c22eb

Deleted Images:
untagged: aquasec/trivy:0.76.1
deleted: sha256:790fd66d1697395d8693d1acaa1ea702406a20f109b6fc7bac8db623eca6c06c
deleted: sha256:fc223b6f033406fd0c5efe59b566295e90cff76ccd2af696bd0d66d53ad83a2d
deleted: sha256:50a0c4df556bfb26b78681b816f64a2bff6be9538e1db0e9d0663f32f9bea136
untagged: sonarqube:26.9.0.129388-community
deleted: sha256:c0f1160bccfa435db4168c2d7df69af3c3ea7bfeb87395613014048fb33a68c1
deleted: sha256:e25587ab8a90d49692d43a088fefeb42e07ae922ab5f132f3a52e1f96545e1b7
deleted: sha256:eb21c097cab7f3d3e5b6e1a78535c2ab1424fc1b77d9aad045e0f0b87d221044

Deleted build cache objects:
lr60n69pbw1uyfmlo5oftpitx
l0kyz63dnz09zcccyjv8ypbu4
coia372kkw5gmaqsfn2npp9qy
xtcdcr95x5tftk5t7pv1iiyjp
22sgcqon6xxq16c4exgyse2b4
l2eafywpvjmlv0pglv9m36pht
69chjuztj5yy1pm5qkivjs8sk
hkyef6hvpdvroxupa6lxog7yu
fdnn2as2qjcz8ktnup10fsneg
keugi94b4ygj862h5c2gw6i7p
msuk6aldnepe33xgp1vtecjvl
i3vxhf0zjgloan1hrjhkxv7i4
gu1x0f2kbjt0o7i0r2d6m5ypu
5ekj0c0igv4krihzt8juzo48j
vyncgnak85f7f0va8lf0g1blj
4cfezruk9e88e5itrdem32ml5
aajrxqdany5zx79nm03ckkb1o
sz6qttfv895n8tnj4tol66td2
on4gzqc1lwdohir3jw3izgiiw
zlk05aj6zy73qz2s3kpxpg8tt
dw369vgwrh84cqd3b4qhip0w2
dgjpsl2p3ogvuaypeemxkbws0
ubf244rb566nhvtmjxm5vxs53
1kf4d9kqxkmew2yrs9fggyah6
y2820snj8kp4t56izri5rnkug
oku5zpikbn1avkoj0v1vsuezu
nybgolg51pbrlpxyhg645i664
nd3npu02o03zaktql6jyln6b4
2dl154uwfhsld51qzq51zt3ye
9z8lyk2h12msiygv0hw3qve99
6hhqkuijhx6s73keyxnzkkbvk
ullop5pxjc5ncu2i0nzfk4hnq
1pr62ym4b832yzd1ihodr506x
sw2o82c7lub0bg03oaka3eggr
z8534zme3rwbhg0a55ni08bqo

Total reclaimed space: 2.965GB
docker volume prune -af
Deleted Volumes:
trivy-cache
projetofinal_sonarqube-logs
projetofinal_sonarqube-data
projetofinal_sonarqube-extensions

Total reclaimed space: 2.289GB
docker network prune -f
docker builder prune -af
Total:  0B
===== [CLEAN DEV] Ambiente virtual e ficheiros temporários =====
rm -rf .venv venv .pytest_cache .coverage htmlcov
find . -type d \( -name "__pycache__" -o -name ".pytest_cache" \) -prune -exec rm -rf {} +
find . -type f \( -name "*.pyc" -o -name "*.pid" -o -name "*.log" -o -name "*.db" \) -not -path "./.git/*" -delete
===== [CLEAN DEV] Espaço ocupado pelo Docker após a limpeza =====
docker system df
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          0         0         0B        0B
Containers      0         0         0B        0B
Local Volumes   0         0         0B        0B
Build Cache     0         0         0B        0B
daniel-almeida@daniel-ubuntu:~/Transferências/ProjetoFinal$ 