daniel-almeida@daniel-ubuntu:~/Transferências/ProjetoFinal$ make check
===== Pré-requisitos e permissões (cluster: microk8s) =====
  ✓ make
  ✓ git
  ✓ curl
  ✓ openssl
  ✓ /usr/bin/python3.12
  ✓ módulo venv do Python
  ✓ docker
  ✓ Docker acessível sem sudo
  ✓ Docker Compose (docker compose)
  ✓ helm
  ✓ fuser
  ✓ MicroK8s instalado
  … sudo (pode pedir a password do utilizador):
  ✓ permissões de sudo
  ✓ memória: 11 GB
===== Máquina pronta ✅ =====
daniel-almeida@daniel-ubuntu:~/Transferências/ProjetoFinal$ make build-dev
===== [PYTHON] A criar ambiente virtual em .venv =====
/usr/bin/python3.12 -m venv .venv
.venv/bin/python -m pip install --quiet --upgrade pip
===== [PYTHON] A instalar requirements-dev.txt =====
.venv/bin/python -m pip install --quiet -r requirements-dev.txt
===== [DEV] A construir imagens =====
docker compose build
[+] Building 24.2s (33/33) FINISHED                                                                                                                                                                                                                                                
 => [internal] load local bake definitions                                                                                                                                                                                                                                    0.0s
 => => reading from stdin 1.74kB                                                                                                                                                                                                                                              0.0s
 => [web internal] load build definition from Dockerfile                                                                                                                                                                                                                      0.0s
 => => transferring dockerfile: 545B                                                                                                                                                                                                                                          0.0s
 => [service-orders internal] load build definition from Dockerfile                                                                                                                                                                                                           0.0s
 => => transferring dockerfile: 1.32kB                                                                                                                                                                                                                                        0.0s
 => [service-users internal] load build definition from Dockerfile                                                                                                                                                                                                            0.0s
 => => transferring dockerfile: 1.32kB                                                                                                                                                                                                                                        0.0s
 => [service-orders internal] load metadata for docker.io/library/python:3.12-alpine3.24                                                                                                                                                                                      1.7s
 => [web internal] load metadata for docker.io/nginxinc/nginx-unprivileged:1.27-alpine                                                                                                                                                                                        1.7s
 => [service-users internal] load .dockerignore                                                                                                                                                                                                                               0.0s
 => => transferring context: 158B                                                                                                                                                                                                                                             0.0s
 => [web internal] load .dockerignore                                                                                                                                                                                                                                         0.0s
 => => transferring context: 57B                                                                                                                                                                                                                                              0.0s
 => [service-orders internal] load .dockerignore                                                                                                                                                                                                                              0.0s
 => => transferring context: 158B                                                                                                                                                                                                                                             0.0s
 => [web 1/4] FROM docker.io/nginxinc/nginx-unprivileged:1.27-alpine@sha256:65e3e85dbaed8ba248841d9d58a899b6197106c23cb0ff1a132b7bfe0547e4c0                                                                                                                                  2.3s
 => => resolve docker.io/nginxinc/nginx-unprivileged:1.27-alpine@sha256:65e3e85dbaed8ba248841d9d58a899b6197106c23cb0ff1a132b7bfe0547e4c0                                                                                                                                      0.0s
 => => sha256:f23a1d1674912e005f43dd93ab9fdca5c6bcda76013afa034d523a769de5551e 16.03MB / 16.03MB                                                                                                                                                                              1.4s
 => => sha256:edee89a8728beee0563123f811dd6596a07077f38b5bcd87791da05a7db60fde 1.40kB / 1.40kB                                                                                                                                                                                0.3s
 => => sha256:0ab5686976ac25d8ac38b59e4690f7a99dce9b343865d7def137b65e662e8c23 1.21kB / 1.21kB                                                                                                                                                                                0.3s
 => => sha256:04c5cf615192471cc36cb4405a2516eb6443c853c8179c9710575baa9acc39e7 404B / 404B                                                                                                                                                                                    0.2s
 => => sha256:8d683a284cf1e30b36a23c1dd71f49365d1d6bc348b100e6a0d32683f649ccf9 957B / 957B                                                                                                                                                                                    0.2s
 => => sha256:513bae533eb237e219e2d3412e0dbb9cd94c25b2b84530b5131fda9512c0e773 627B / 627B                                                                                                                                                                                    0.3s
 => => sha256:d51f1218ef72c44a300c138c2a1de9a8461ee6063060c1f670f32546b39a3ce7 2.80kB / 2.80kB                                                                                                                                                                                0.2s
 => => sha256:0a44daad67e98d09449e0547e0f72e69b317d0abe1e579a4f352307161ac8cc9 1.79MB / 1.79MB                                                                                                                                                                                0.3s
 => => sha256:6e771e15690e2fabf2332d3a3b744495411d6e0b00b2aea64419b58b0066cf81 3.99MB / 3.99MB                                                                                                                                                                                0.4s
 => => extracting sha256:6e771e15690e2fabf2332d3a3b744495411d6e0b00b2aea64419b58b0066cf81                                                                                                                                                                                     0.0s
 => => extracting sha256:0a44daad67e98d09449e0547e0f72e69b317d0abe1e579a4f352307161ac8cc9                                                                                                                                                                                     0.0s
 => => extracting sha256:d51f1218ef72c44a300c138c2a1de9a8461ee6063060c1f670f32546b39a3ce7                                                                                                                                                                                     0.0s
 => => extracting sha256:513bae533eb237e219e2d3412e0dbb9cd94c25b2b84530b5131fda9512c0e773                                                                                                                                                                                     0.0s
 => => extracting sha256:8d683a284cf1e30b36a23c1dd71f49365d1d6bc348b100e6a0d32683f649ccf9                                                                                                                                                                                     0.0s
 => => extracting sha256:04c5cf615192471cc36cb4405a2516eb6443c853c8179c9710575baa9acc39e7                                                                                                                                                                                     0.0s
 => => extracting sha256:0ab5686976ac25d8ac38b59e4690f7a99dce9b343865d7def137b65e662e8c23                                                                                                                                                                                     0.0s
 => => extracting sha256:edee89a8728beee0563123f811dd6596a07077f38b5bcd87791da05a7db60fde                                                                                                                                                                                     0.0s
 => => extracting sha256:f23a1d1674912e005f43dd93ab9fdca5c6bcda76013afa034d523a769de5551e                                                                                                                                                                                     0.1s
 => [web internal] load build context                                                                                                                                                                                                                                         0.0s
 => => transferring context: 19.58kB                                                                                                                                                                                                                                          0.0s
 => [service-orders 1/7] FROM docker.io/library/python:3.12-alpine3.24@sha256:b658b05ce9c4eb97ec6fc19424818a1f31993659c2b505a532f470e83807815d                                                                                                                                1.5s
 => => resolve docker.io/library/python:3.12-alpine3.24@sha256:b658b05ce9c4eb97ec6fc19424818a1f31993659c2b505a532f470e83807815d                                                                                                                                               0.0s
 => => sha256:2e0145d2e04ce88ed6ddc5bd437750e9c1b6285b98328a2110f526820cf07197 249B / 249B                                                                                                                                                                                    0.2s
 => => sha256:aeb1727fb8fbe0fe413f73e7857eb1de4b90e134c039daed4fe3bd524c93cc21 13.92MB / 13.92MB                                                                                                                                                                              1.0s
 => => sha256:c1b55611a4e007c236d30ff447cd9fd97bae2579b14b4e0063a2b6a325af4ba7 415.56kB / 415.56kB                                                                                                                                                                            0.9s
 => => sha256:d3531b7a4f217bdc3426c57bcff84c170f086f456a39689d4a615c6d026c4be0 4.19MB / 4.19MB                                                                                                                                                                                1.3s
 => => extracting sha256:d3531b7a4f217bdc3426c57bcff84c170f086f456a39689d4a615c6d026c4be0                                                                                                                                                                                     0.0s
 => => extracting sha256:c1b55611a4e007c236d30ff447cd9fd97bae2579b14b4e0063a2b6a325af4ba7                                                                                                                                                                                     0.0s
 => => extracting sha256:aeb1727fb8fbe0fe413f73e7857eb1de4b90e134c039daed4fe3bd524c93cc21                                                                                                                                                                                     0.2s
 => => extracting sha256:2e0145d2e04ce88ed6ddc5bd437750e9c1b6285b98328a2110f526820cf07197                                                                                                                                                                                     0.0s
 => [service-orders internal] load build context                                                                                                                                                                                                                              0.0s
 => => transferring context: 18.89kB                                                                                                                                                                                                                                          0.0s
 => [service-users internal] load build context                                                                                                                                                                                                                               0.0s
 => => transferring context: 13.87kB                                                                                                                                                                                                                                          0.0s
 => [service-orders 2/7] WORKDIR /app                                                                                                                                                                                                                                         0.1s
 => [service-orders 3/7] RUN apk upgrade --no-cache                                                                                                                                                                                                                           0.8s
 => [web 2/4] RUN apk upgrade --no-cache                                                                                                                                                                                                                                      2.1s
 => [service-orders 4/7] COPY requirements-prd.txt requirements-tracing.txt ./                                                                                                                                                                                                0.0s
 => [service-users 4/7] COPY requirements-prd.txt requirements-tracing.txt ./                                                                                                                                                                                                 0.0s
 => [service-users 5/7] RUN pip install --no-cache-dir -r requirements-prd.txt     && if [ "true" = "true" ]; then pip install --no-cache-dir -r requirements-tracing.txt; fi     && pip uninstall -y pip     && rm -rf /usr/local/lib/python3.12/ensurepip                  15.6s
 => [service-orders 5/7] RUN pip install --no-cache-dir -r requirements-prd.txt     && if [ "true" = "true" ]; then pip install --no-cache-dir -r requirements-tracing.txt; fi     && pip uninstall -y pip     && rm -rf /usr/local/lib/python3.12/ensurepip                 17.1s
 => [web 3/4] COPY nginx.conf.template /etc/nginx/templates/default.conf.template                                                                                                                                                                                             0.0s
 => [web 4/4] COPY static/ /usr/share/nginx/html/                                                                                                                                                                                                                             0.0s
 => [web] exporting to image                                                                                                                                                                                                                                                  0.4s
 => => exporting layers                                                                                                                                                                                                                                                       0.3s
 => => exporting manifest sha256:bcdab185da380a61e85dacf413eab5d5abd1a377fb3d2dd9c1422e59150d5d9b                                                                                                                                                                             0.0s
 => => exporting config sha256:ec85e981af9d562b214e29e42965ac5fc4fd657b3cbe8c76d737bba43712ba2f                                                                                                                                                                               0.0s
 => => exporting attestation manifest sha256:0c42cac3d9993a23369d7b95aa0e6ce78ce98e83432c5a80bb5790818dff7d15                                                                                                                                                                 0.0s
 => => exporting manifest list sha256:bc093ff5cb6318797080750f07f45f5c5c83694d4deb94054252f06128f80021                                                                                                                                                                        0.0s
 => => naming to docker.io/library/projetofinal-web:latest                                                                                                                                                                                                                    0.0s
 => => unpacking to docker.io/library/projetofinal-web:latest                                                                                                                                                                                                                 0.1s
 => [web] resolving provenance for metadata file                                                                                                                                                                                                                              0.0s
 => [service-users 6/7] COPY app/ ./app/                                                                                                                                                                                                                                      0.0s
 => [service-users 7/7] RUN addgroup -g 1000 app &&     adduser -u 1000 -G app -H -D -s /sbin/nologin app &&     chown -R app:app /app                                                                                                                                        0.1s
 => [service-users] exporting to image                                                                                                                                                                                                                                        2.6s
 => => exporting layers                                                                                                                                                                                                                                                       2.2s
 => => exporting manifest sha256:c1945411a504d1690eaeac9a8571404895946dbecf2eddf635f5836f4eba0d99                                                                                                                                                                             0.0s
 => => exporting config sha256:31cd735a4182a13163c10a3aee494b5568bc16644b103023859242caab0bd9a5                                                                                                                                                                               0.0s
 => => exporting attestation manifest sha256:ab9084bd2bc61fecfd22765974777d2e50c775b72e7285167ea2da72bbbeaf19                                                                                                                                                                 0.0s
 => => exporting manifest list sha256:d3f02a21268e7f030754d578f3e66e20a46345d45e71bf93c5f238398d68ed2a                                                                                                                                                                        0.0s
 => => naming to docker.io/library/projetofinal-service-users:latest                                                                                                                                                                                                          0.0s
 => => unpacking to docker.io/library/projetofinal-service-users:latest                                                                                                                                                                                                       0.4s
 => [service-orders 6/7] COPY app/ ./app/                                                                                                                                                                                                                                     0.0s
 => [service-orders 7/7] RUN addgroup -g 1000 app &&     adduser -u 1000 -G app -H -D -s /sbin/nologin app &&     chown -R app:app /app                                                                                                                                       0.1s
 => [service-orders] exporting to image                                                                                                                                                                                                                                       2.7s
 => => exporting layers                                                                                                                                                                                                                                                       2.2s
 => => exporting manifest sha256:85bad58e0d1f19939fb7a7124e03f52f06682a12ce1c3fba906850bdbe8781be                                                                                                                                                                             0.0s
 => => exporting config sha256:25db685f62b9a1931f30a9cf5b65e0b7683b2f5352347861f398d2493bbfaabc                                                                                                                                                                               0.0s
 => => exporting attestation manifest sha256:5d455cf13f131b8c8b51c1f7fc207e0c63a8e1d5e7aedad8f8e38e7ef983349a                                                                                                                                                                 0.0s
 => => exporting manifest list sha256:fffdb539d95e50770caed72cd112f48bd5e4e3026f01d8bd28406d93ff23d575                                                                                                                                                                        0.0s
 => => naming to docker.io/library/projetofinal-service-orders:latest                                                                                                                                                                                                         0.0s
 => => unpacking to docker.io/library/projetofinal-service-orders:latest                                                                                                                                                                                                      0.5s
 => [service-users] resolving provenance for metadata file                                                                                                                                                                                                                    0.0s
 => [service-orders] resolving provenance for metadata file                                                                                                                                                                                                                   0.0s
[+] build 3/3
 ✔ Image projetofinal-service-orders Built                                                                                                                                                                                                                                    24.3s
 ✔ Image projetofinal-service-users  Built                                                                                                                                                                                                                                    24.3s
 ✔ Image projetofinal-web            Built                                                                                                                                                                                                                                    24.3s
===== [DEV] Build concluído ✅  (seguinte: make run-dev) =====
daniel-almeida@daniel-ubuntu:~/Transferências/ProjetoFinal$ make run-dev
===== [DEV] A iniciar Docker Compose =====
docker compose up -d --wait
[+] up 64/64
 ✔ Image jaegertracing/all-in-one:1.60      Pulled                                                                                                                                                                                                                             9.2s
 ✔ Image grafana/grafana:11.3.0             Pulled                                                                                                                                                                                                                            13.8s
 ✔ Image quay.io/keycloak/keycloak:26.0     Pulled                                                                                                                                                                                                                            15.6s
 ✔ Image postgres:16-alpine                 Pulled                                                                                                                                                                                                                            14.0s
 ✔ Image prom/prometheus:v2.55.1            Pulled                                                                                                                                                                                                                            12.6s
 ✔ Network projetofinal_app-network         Created                                                                                                                                                                                                                            0.0s
 ✔ Volume projetofinal_grafana-data         Created                                                                                                                                                                                                                            0.0s
 ✔ Volume projetofinal_keycloak-data        Created                                                                                                                                                                                                                            0.0s
 ✔ Volume projetofinal_prometheus-data      Created                                                                                                                                                                                                                            0.0s
 ✔ Volume projetofinal_postgres-orders-data Created                                                                                                                                                                                                                            0.0s
 ✔ Container projetofinal-jaeger-1          Healthy                                                                                                                                                                                                                           32.7s
 ✔ Container projetofinal-postgres-orders-1 Healthy                                                                                                                                                                                                                           32.7s
 ✔ Container projetofinal-keycloak-1        Healthy                                                                                                                                                                                                                           32.7s
 ✔ Container projetofinal-service-users-1   Healthy                                                                                                                                                                                                                           32.5s
 ✔ Container projetofinal-service-orders-1  Healthy                                                                                                                                                                                                                           32.5s
 ✔ Container projetofinal-web-1             Healthy                                                                                                                                                                                                                           42.5s
 ... 2 more                                                                                                                                                                                                                                                                        

===== [DEV] Endereços e credenciais =====
  BACKOFFICE (aplicação)      http://localhost:8000       admin / admin
  API utilizadores (Swagger)  http://localhost:8002/docs  token: make token-dev
  API encomendas   (Swagger)  http://localhost:8001/docs  token: make token-dev
  Keycloak (consola admin)    http://localhost:8080       admin / admin
  Grafana                     http://localhost:3000       admin / admin
  Prometheus                  http://localhost:9090       sem login
  Jaeger (só em DEV)          http://localhost:16686      sem login
  SonarQube (make security)   http://localhost:9500       admin / ProjetoFinal.2026

  Criar/editar/apagar clientes e encomendas: no site, ou make demo-dev (README, secção 6)

daniel-almeida@daniel-ubuntu:~/Transferências/ProjetoFinal$ make token-dev
eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJ0dGZ1VV9GTnB1Tmk2dkpPcUdtQl8wUzR6a3ZYQ3lXazV3U2Z3eXlqVF80In0.eyJleHAiOjE3OTMwMjQwNDIsImlhdCI6MTc5MzAyMzc0MiwianRpIjoiYTA5ZjgwY2UtNTJjYy00OTAxLWJhYTMtNzI2MGE1M2VhOWQ1IiwiaXNzIjoiaHR0cDovL2tleWNsb2FrOjgwODAvcmVhbG1zL3Byb2pldG8tZmluYWwiLCJzdWIiOiJjMzQ5NTBjYi1jNmI2LTQ1OWMtOTk2NS01M2RhMzgzMzNmODYiLCJ0eXAiOiJCZWFyZXIiLCJhenAiOiJhcGktY2xpIiwic2lkIjoiNzlmODJlYTYtZjA5YS00ZTM1LWI1ZTktMjY5NTc4MmU4YmEzIiwic2NvcGUiOiJ1c2Vyczp3cml0ZSBvcmRlcnM6cmVhZCBvcmRlcnM6d3JpdGUgdXNlcnM6cmVhZCJ9.iPY9TVIaFqY1BlILeCVHFg4HD7KEjLPUuCDglI_s7cWqDTKauL7Ep7O3AQqdMemepJnV_5jJHAnv2nHNm8Y4hQgBapDE2jlclyKzO0SwjzIhY8QdSouk39k9T2WtZIkJhvaBqDfMGnHeYhVXdGQIoHYsJFWTyqrXyVCRURfqyezdlr58dig5ZrMoDJDiIM6xnCdcGgaInyuJcjek54TbQ3OpegHRFVutb9abQiH-hLctJ-g1g7mWAnqMuzy5EzSSlcHq37IPF-CcP5JP0RciD1GoqHpUkyjkhAD5Ba_8IeomvgXmaVt375FDVHNUMz_keQir8rKnnJ9XVnOLVBTOnw
daniel-almeida@daniel-ubuntu:~/Transferências/ProjetoFinal$ make test-dev
===== [DEV] A parar Docker Compose (inclui o SonarQube) =====
docker compose --profile sonar down
[+] down 9/9
 ✔ Container projetofinal-web-1             Removed                                                                                                                                                                                                                            0.1s
 ✔ Container projetofinal-grafana-1         Removed                                                                                                                                                                                                                            0.1s
 ✔ Container projetofinal-prometheus-1      Removed                                                                                                                                                                                                                            0.1s
 ✔ Container projetofinal-service-orders-1  Removed                                                                                                                                                                                                                            0.4s
 ✔ Container projetofinal-service-users-1   Removed                                                                                                                                                                                                                            0.3s
 ✔ Container projetofinal-postgres-orders-1 Removed                                                                                                                                                                                                                            0.1s
 ✔ Container projetofinal-keycloak-1        Removed                                                                                                                                                                                                                            0.3s
 ✔ Container projetofinal-jaeger-1          Removed                                                                                                                                                                                                                            0.1s
 ✔ Network projetofinal_app-network         Removed                                                                                                                                                                                                                            0.1s
===== [DEV] Testes unitários — service-users =====
cd service-users && ../.venv/bin/python -m pytest tests/ -v
=============================================================================================================================== test session starts ===============================================================================================================================
platform linux -- Python 3.12.13, pytest-9.1.1, pluggy-1.7.0 -- /home/daniel-almeida/Transferências/ProjetoFinal/service-users/../.venv/bin/python
cachedir: .pytest_cache
rootdir: /home/daniel-almeida/Transferências/ProjetoFinal
configfile: pytest.ini
plugins: anyio-4.15.1, platformdirs-4.13.5
collected 23 items                                                                                                                                                                                                                                                                

tests/test_users.py::test_health_does_not_require_auth PASSED                                                                                                                                                                                                               [  4%]
tests/test_users.py::test_metrics_endpoint_does_not_require_auth PASSED                                                                                                                                                                                                     [  8%]
tests/test_users.py::test_get_existing_user PASSED                                                                                                                                                                                                                          [ 13%]
tests/test_users.py::test_get_nonexistent_user_returns_404 PASSED                                                                                                                                                                                                           [ 17%]
tests/test_users.py::test_list_users_returns_all PASSED                                                                                                                                                                                                                     [ 21%]
tests/test_users.py::test_list_users_without_token_returns_401 PASSED                                                                                                                                                                                                       [ 26%]
tests/test_users.py::test_get_user_with_wrong_scope_returns_403 PASSED                                                                                                                                                                                                      [ 30%]
tests/test_users.py::test_get_user_with_expired_token_returns_401 PASSED                                                                                                                                                                                                    [ 34%]
tests/test_users.py::test_get_user_with_malformed_token_returns_401 PASSED                                                                                                                                                                                                  [ 39%]
tests/test_users.py::test_azp_allowlist_rejects_client_not_in_list PASSED                                                                                                                                                                                                   [ 43%]
tests/test_users.py::test_azp_allowlist_accepts_client_in_list PASSED                                                                                                                                                                                                       [ 47%]
tests/test_users.py::test_create_user PASSED                                                                                                                                                                                                                                [ 52%]
tests/test_users.py::test_create_user_with_duplicate_email_returns_409 PASSED                                                                                                                                                                                               [ 56%]
tests/test_users.py::test_create_user_with_invalid_email_returns_422 PASSED                                                                                                                                                                                                 [ 60%]
tests/test_users.py::test_create_user_with_read_only_scope_returns_403 PASSED                                                                                                                                                                                               [ 65%]
tests/test_users.py::test_create_user_without_token_returns_401 PASSED                                                                                                                                                                                                      [ 69%]
tests/test_users.py::test_delete_user PASSED                                                                                                                                                                                                                                [ 73%]
tests/test_users.py::test_delete_nonexistent_user_returns_404 PASSED                                                                                                                                                                                                        [ 78%]
tests/test_users.py::test_delete_user_with_read_only_scope_returns_403 PASSED                                                                                                                                                                                               [ 82%]
tests/test_users.py::test_update_user PASSED                                                                                                                                                                                                                                [ 86%]
tests/test_users.py::test_update_nonexistent_user_returns_404 PASSED                                                                                                                                                                                                        [ 91%]
tests/test_users.py::test_update_user_with_email_of_another_user_returns_409 PASSED                                                                                                                                                                                         [ 95%]
tests/test_users.py::test_update_user_with_read_only_scope_returns_403 PASSED                                                                                                                                                                                               [100%]

================================================================================================================================ warnings summary =================================================================================================================================
../.venv/lib/python3.12/site-packages/fastapi/testclient.py:1
  /home/daniel-almeida/Transferências/ProjetoFinal/.venv/lib/python3.12/site-packages/fastapi/testclient.py:1: StarletteDeprecationWarning: Using `httpx` with `starlette.testclient` is deprecated; install `httpx2` instead.
    from starlette.testclient import TestClient as TestClient  # noqa

-- Docs: https://docs.pytest.org/en/stable/how-to/capture-warnings.html
========================================================================================================================== 23 passed, 1 warning in 0.87s ==========================================================================================================================
===== [DEV] Testes unitários — service-orders =====
cd service-orders && ../.venv/bin/python -m pytest tests/ -v
=============================================================================================================================== test session starts ===============================================================================================================================
platform linux -- Python 3.12.13, pytest-9.1.1, pluggy-1.7.0 -- /home/daniel-almeida/Transferências/ProjetoFinal/service-orders/../.venv/bin/python
cachedir: .pytest_cache
rootdir: /home/daniel-almeida/Transferências/ProjetoFinal
configfile: pytest.ini
plugins: anyio-4.15.1, platformdirs-4.13.5
collected 19 items                                                                                                                                                                                                                                                                

tests/test_orders.py::test_health_does_not_require_auth PASSED                                                                                                                                                                                                              [  5%]
tests/test_orders.py::test_metrics_endpoint_does_not_require_auth PASSED                                                                                                                                                                                                    [ 10%]
tests/test_orders.py::test_create_order_success PASSED                                                                                                                                                                                                                      [ 15%]
tests/test_orders.py::test_create_order_user_not_found PASSED                                                                                                                                                                                                               [ 21%]
tests/test_orders.py::test_create_order_without_token_returns_401 PASSED                                                                                                                                                                                                    [ 26%]
tests/test_orders.py::test_create_order_with_read_only_scope_returns_403 PASSED                                                                                                                                                                                             [ 31%]
tests/test_orders.py::test_get_nonexistent_order_returns_404 PASSED                                                                                                                                                                                                         [ 36%]
tests/test_orders.py::test_list_orders_without_token_returns_401 PASSED                                                                                                                                                                                                     [ 42%]
tests/test_orders.py::test_create_order_rejects_zero_or_negative_quantity PASSED                                                                                                                                                                                            [ 47%]
tests/test_orders.py::test_created_order_is_persisted_and_listed PASSED                                                                                                                                                                                                     [ 52%]
tests/test_orders.py::test_azp_allowlist_rejects_client_not_in_list PASSED                                                                                                                                                                                                  [ 57%]
tests/test_orders.py::test_azp_allowlist_accepts_client_in_list PASSED                                                                                                                                                                                                      [ 63%]
tests/test_orders.py::test_delete_order PASSED                                                                                                                                                                                                                              [ 68%]
tests/test_orders.py::test_delete_nonexistent_order_returns_404 PASSED                                                                                                                                                                                                      [ 73%]
tests/test_orders.py::test_delete_order_with_read_only_scope_returns_403 PASSED                                                                                                                                                                                             [ 78%]
tests/test_orders.py::test_update_order PASSED                                                                                                                                                                                                                              [ 84%]
tests/test_orders.py::test_update_nonexistent_order_returns_404 PASSED                                                                                                                                                                                                      [ 89%]
tests/test_orders.py::test_update_order_rejects_invalid_quantity PASSED                                                                                                                                                                                                     [ 94%]
tests/test_orders.py::test_update_order_with_read_only_scope_returns_403 PASSED                                                                                                                                                                                             [100%]

================================================================================================================================ warnings summary =================================================================================================================================
../.venv/lib/python3.12/site-packages/fastapi/testclient.py:1
  /home/daniel-almeida/Transferências/ProjetoFinal/.venv/lib/python3.12/site-packages/fastapi/testclient.py:1: StarletteDeprecationWarning: Using `httpx` with `starlette.testclient` is deprecated; install `httpx2` instead.
    from starlette.testclient import TestClient as TestClient  # noqa

-- Docs: https://docs.pytest.org/en/stable/how-to/capture-warnings.html
========================================================================================================================== 19 passed, 1 warning in 0.77s ==========================================================================================================================
===== [PYTHON] A instalar requirements-stg.txt =====
.venv/bin/python -m pip install --quiet -r requirements-stg.txt
===== [SEGURANÇA] pip-audit e Trivy — dependências (relatórios em tests/security/reports) =====
TRIVY_IMAGE=aquasec/trivy:0.76.1 TRIVY_IMAGES= .venv/bin/python -m pytest tests/security -v
=============================================================================================================================== test session starts ===============================================================================================================================
platform linux -- Python 3.12.13, pytest-9.1.1, pluggy-1.7.0 -- /home/daniel-almeida/Transferências/ProjetoFinal/.venv/bin/python
cachedir: .pytest_cache
rootdir: /home/daniel-almeida/Transferências/ProjetoFinal
configfile: pytest.ini
plugins: anyio-4.15.1, platformdirs-4.13.5
collected 6 items                                                                                                                                                                                                                                                                 

tests/security/test_vulnerabilidades.py::test_pip_audit_dependencias[service-orders/requirements-prd.txt] PASSED                                                                                                                                                            [ 16%]
tests/security/test_vulnerabilidades.py::test_pip_audit_dependencias[service-orders/requirements-tracing.txt] PASSED                                                                                                                                                        [ 33%]
tests/security/test_vulnerabilidades.py::test_pip_audit_dependencias[service-users/requirements-prd.txt] PASSED                                                                                                                                                             [ 50%]
tests/security/test_vulnerabilidades.py::test_pip_audit_dependencias[service-users/requirements-tracing.txt] PASSED                                                                                                                                                         [ 66%]
tests/security/test_vulnerabilidades.py::test_trivy_dependencias PASSED                                                                                                                                                                                                     [ 83%]
tests/security/test_vulnerabilidades.py::test_trivy_imagem[NOTSET] SKIPPED (TRIVY_IMAGES não definido (análise de imagens só em STG))                                                                                                                                       [100%]

========================================================================================================================== 5 passed, 1 skipped in 27.04s ==========================================================================================================================
===== [SONARQUBE] A arrancar o servidor (http://localhost:9500) =====
[+] up 6/6
 ✔ Image sonarqube:26.9.0.129388-community  Pulled                                                                                                                                                                                                                            30.1s
 ✔ Network projetofinal_sonar-network       Created                                                                                                                                                                                                                            0.0s
 ✔ Volume projetofinal_sonarqube-data       Created                                                                                                                                                                                                                            0.0s
 ✔ Volume projetofinal_sonarqube-extensions Created                                                                                                                                                                                                                            0.0s
 ✔ Volume projetofinal_sonarqube-logs       Created                                                                                                                                                                                                                            0.0s
 ✔ Container projetofinal-sonarqube-1       Started                                                                                                                                                                                                                            0.3s
===== [SEGURANÇA] SonarQube — análise do código Python =====
INFO: Starting Pysonar 1.9.0.5762, the Sonar scanner CLI for Python
INFO: Enhance your workflow: Pair pysonar with SonarQube Server per your license or SonarQube Cloud for deeper analysis, and try SonarQube-IDE in your favourite IDE.
INFO: Starting the analysis...
INFO: Starting SonarScanner Engine...
INFO: Java 21.0.11 Eclipse Adoptium (64-bit)
INFO: Load global settings
INFO: Load global settings (done) | time=54ms
INFO: Server id: 147B411E-AaF4jVEu0zaQP9I1Wle3
INFO: Loading required plugins
INFO: Load plugins index
INFO: Load plugins index (done) | time=19ms
INFO: Load/download plugins
INFO: Load/download plugins (done) | time=18ms
INFO: Process project properties
INFO: Process project properties (done) | time=5ms
INFO: Project key: projeto-final
INFO: Base dir: /home/daniel-almeida/Transferências/ProjetoFinal
INFO: Working dir: /home/daniel-almeida/Transferências/ProjetoFinal/.scannerwork
INFO: Load project settings for component key: 'projeto-final'
INFO: Load quality profiles
INFO: Load quality profiles (done) | time=59ms
INFO: Load active rules
INFO: Load active rules (done) | time=172ms
INFO: Load analysis cache
INFO: Load analysis cache (404) | time=3ms
INFO: Preprocessing files...
INFO: 1 language detected in 23 preprocessed files (done) | time=28ms
INFO: 24 files ignored because of scm ignore settings
INFO: Loading plugins for detected languages
INFO: Load/download plugins
INFO: Load/download plugins (done) | time=5ms
INFO: Load project repositories
INFO: Load project repositories (done) | time=4ms
INFO: Indexing files...
INFO: Project configuration:
INFO: 23 files indexed (done) | time=4ms
INFO: Quality profile for py: Sonar way
INFO: ------------- Run sensors on module Projeto Final
INFO: Load metrics repository
INFO: Load metrics repository (done) | time=14ms
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
INFO: Finished step global symbols computation in 653ms
INFO: Starting rules execution
INFO: 22 source files to be analyzed
INFO: 22/22 source files have been analyzed
INFO: Finished step rules execution in 641ms
INFO: The Python analyzer was able to leverage cached data from previous analyses for 0 out of 22 files. These files were not parsed.
INFO: Sensor Python Sensor [python] (done) | time=1508ms
INFO: Sensor Cobertura Sensor for Python coverage [python]
INFO: Sensor Cobertura Sensor for Python coverage [python] (done) | time=38ms
INFO: Sensor PythonXUnitSensor [python]
INFO: Sensor PythonXUnitSensor [python] (done) | time=32ms
INFO: Sensor Python Dependency Sensor [python]
INFO: Sensor Python Dependency Sensor [python] (done) | time=3ms
INFO: Sensor TextAndSecretsSensor [text]
INFO: Available processors: 10
INFO: Using 10 threads for analysis.
INFO: Start fetching files for the text and secrets analysis
INFO: Using Git CLI to retrieve dirty files
INFO: Retrieving language associated files and files included via "sonar.text.inclusions" that are tracked by git
INFO: Starting the text and secrets analysis
INFO: 22 source files to be analyzed for the text and secrets analysis
INFO: 22/22 source files have been analyzed for the text and secrets analysis
INFO: Sensor TextAndSecretsSensor [text] (done) | time=213ms
INFO: ------------- Run sensors on project
INFO: Sensor IaC Project Sensor [iac]
INFO: Sensor IaC Project Sensor [iac] (done) | time=1ms
INFO: Sensor Zero Coverage Sensor
INFO: Sensor Zero Coverage Sensor (done) | time=5ms
INFO: ------------- Gather SCA dependencies on project
INFO: Dependency analysis skipped
INFO: SCM Publisher SCM provider for this project is: git
INFO: SCM Publisher 20 source files to be analyzed
INFO: SCM Publisher 10/20 source files have been analyzed (done) | time=183ms
WARNING: Missing blame information for the following files:
WARNING:   * service-users/app/logging_setup.py
WARNING:   * tests/integration/test_integration.py
WARNING:   * service-orders/app/oidc_client.py
WARNING:   * service-orders/app/main.py
WARNING:   * tests/security/test_vulnerabilidades.py
WARNING:   * service-orders/app/security.py
WARNING:   * service-users/app/security.py
WARNING:   * service-users/app/main.py
WARNING:   * scripts/demo.py
WARNING:   * service-orders/app/logging_setup.py
WARNING: This may lead to missing/broken features in SonarQube
INFO: CPD Executor 2 files had no CPD blocks
INFO: CPD Executor Calculating CPD for 13 files
INFO: CPD Executor CPD calculation finished (done) | time=7ms
INFO: SCM revision ID '8e6a0dc59fb1fba60e93147a438d6990e875ae90'
INFO: Analysis report generated in 74ms, dir size=470.5 kB
INFO: Analysis report compressed in 25ms, zip size=146.0 kB
INFO: Analysis report uploaded in 164ms
INFO: ------------- Check Quality Gate status
INFO: Waiting for the analysis report to be processed (max 300s)
INFO: QUALITY GATE STATUS: PASSED - View details on http://localhost:9500/dashboard?id=projeto-final
INFO: Analysis total time: 8.300 s
INFO: SonarScanner Engine completed successfully
# SonarQube — projeto-final (2026-10-26 14:11)
Quality gate: OK
Issues em aberto: 0
  (SonarQube parado para libertar memória; painel: make sonar-up e http://localhost:9500)
===== [DEV] Testes concluídos ✅  (o ambiente foi parado: make run-dev para o voltar a subir) =====
daniel-almeida@daniel-ubuntu:~/Transferências/ProjetoFinal$ make clean-dev
===== [CLEAN DEV] Docker Compose: contentores, volumes, imagens e órfãos =====
docker compose -f docker-compose.yml down -v --rmi all --remove-orphans
[+] down 12/12
 ✔ Image projetofinal-service-users:latest  Removed                                                                                                                                                                                                                            0.3s
 ✔ Image jaegertracing/all-in-one:1.60      Removed                                                                                                                                                                                                                            0.3s
 ✔ Image postgres:16-alpine                 Removed                                                                                                                                                                                                                            0.3s
 ✔ Image projetofinal-service-orders:latest Removed                                                                                                                                                                                                                            0.3s
 ✔ Image quay.io/keycloak/keycloak:26.0     Removed                                                                                                                                                                                                                            0.3s
 ✔ Image projetofinal-web:latest            Removed                                                                                                                                                                                                                            0.3s
 ✔ Image prom/prometheus:v2.55.1            Removed                                                                                                                                                                                                                            0.3s
 ✔ Image grafana/grafana:11.3.0             Removed                                                                                                                                                                                                                            0.3s
 ✔ Volume projetofinal_postgres-orders-data Removed                                                                                                                                                                                                                            0.0s
 ✔ Volume projetofinal_prometheus-data      Removed                                                                                                                                                                                                                            0.0s
 ✔ Volume projetofinal_keycloak-data        Removed                                                                                                                                                                                                                            0.0s
 ✔ Volume projetofinal_grafana-data         Removed                                                                                                                                                                                                                            0.0s
docker compose -p projeto-final-devops down -v --rmi all --remove-orphans
WARN[0000] Warning: No resource found to remove for project "projeto-final-devops". 
===== [CLEAN DEV] Parar todos os contentores =====
docker stop $(docker ps -qa) 2>/dev/null || true
accdececef69
===== [CLEAN DEV] Docker: imagens, contentores, volumes, redes e cache de build =====
docker system prune -af --volumes
Deleted Containers:
accdececef6950b31e34916c6b9868a52a293f47168666d7f85d302aaa950ee3

Deleted Networks:
projetofinal_sonar-network

Deleted Volumes:
d4cce8606072d2b7a6804e5f2e4da95469b92e780ef56367e53f6fc9ebdc6385
018d39f9b8375e589bc497db22e9d535c46676a7eb60f745004ff1a1feaea713

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
l74w2p8d40xxp57d96rni780b
k1zl88k0xhhesdpkyzvz5gwqo
n1ydiqus6t1dls7pqvnnokfcl
erroxz3bm6tw33ifwyas9mm5e
z6d7m6iqvx9iuo4826px13lhy
iena5ynrfuvpe6mmsozmzxye5
kos8w1z45kjuxzxfln4wbpj21
p0l89taemv3a3q8i3u79pee89
onk0zj6gsha2plcg3hjgy7wmh
aapo7dbp6k4bzrs6emos4wa4u
mefqhcykkdvhbtxrug5prm40a
6tk8uwsorihb1wv8iogagmzzn
cfppfm4v7jgyjm69b57yr8lg4
zeq5m1e9ddh5x6eshex9dvcq0
ezg3epno6i4ewznufv631e04e
arudiadxvc0v0mq6ha4hqcv36
tlngwtcst7yn86bp5t81bgn2s
dlxy6kyis215q14n1y8hefyeo
x8ma84w2od6c78k43237y3u6v
lrnvwi3718caecoha8jh7hvj2
urhsva3tqws0vfi1xc68pqbfi
mrlgmxjqf4dxzzyz3728twt6b
pd6delox0v61roslbz50flvgq
k2otvzjvfqdvpbv0hva7lj04k
2vb3kok8js03l3xphfnbu9zbd
wp5uqxb37b3bg763z6llbosno
ou4tw4pfuhrci39n5bxrizr75
igyif9kdx8ct9wg80cozcdinp
19puedxzwmedff0ktadx96f7h
ko36zuahsvv0cgks2fwfmsxpa
uvqxq9cjm9d993u6b3t3obrc7
talxmwi195zczjeeqydg9d5t1
95kyiveld252o1x8c1khccstz
s8mqxe0bflfnkz1s0eh8r62jk
wtmwezj71mt1uqac5sz1x4xp6

Total reclaimed space: 2.007GB
docker volume prune -af
Deleted Volumes:
projetofinal_sonarqube-extensions
trivy-cache
projetofinal_sonarqube-data
projetofinal_sonarqube-logs

Total reclaimed space: 2.03GB
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