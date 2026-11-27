daniel-almeida@daniel-ubuntu:~/Transferências/ProjetoFinal$ sudo snap start microk8s
Começou.
daniel-almeida@daniel-ubuntu:~/Transferências/ProjetoFinal$ make build-stg
===== [PYTHON] A criar ambiente virtual em .venv =====
/usr/bin/python3.12 -m venv --clear .venv
.venv/bin/python -m pip install --quiet --upgrade pip
===== [PYTHON] A instalar requirements-stg.txt =====
.venv/bin/python -m pip install --quiet -r requirements-stg.txt
===== [STG] A construir ghcr.io/kunami264/projeto-final-devops/service-users:stg =====
[+] Building 14.6s (12/12) FINISHED                                                                                              docker:default
 => [internal] load build definition from Dockerfile                                                                                       0.0s
 => => transferring dockerfile: 1.32kB                                                                                                     0.0s
 => [internal] load metadata for docker.io/library/python:3.12-alpine3.24                                                                  1.6s
 => [internal] load .dockerignore                                                                                                          0.0s
 => => transferring context: 158B                                                                                                          0.0s
 => [1/7] FROM docker.io/library/python:3.12-alpine3.24@sha256:c5ba3deef00c7758561a0f03c26f44f10589263d40e732b8748e0d1f38f6dd89            2.1s
 => => resolve docker.io/library/python:3.12-alpine3.24@sha256:c5ba3deef00c7758561a0f03c26f44f10589263d40e732b8748e0d1f38f6dd89            0.0s
 => => sha256:8ab1992027dfd42035e1028c42f93c50180a2b01b89a2645899d7c9299fcdd5c 251B / 251B                                                 0.2s
 => => sha256:9cee687b648e8e2f38b10079e58e752f383ebe19bea21c5a6657a29703a336f8 13.92MB / 13.92MB                                           0.7s
 => => sha256:6d356b48c1c56cccd22e48f043c1e8ac8d79ef86f9e625b548c82014803b7830 415.54kB / 415.54kB                                         0.7s
 => => sha256:b90627b8f4292fd3cb63f0f27f0b11c37f04ba88ef3b78d4948ea0ace18c85e9 4.19MB / 4.19MB                                             1.8s
 => => extracting sha256:b90627b8f4292fd3cb63f0f27f0b11c37f04ba88ef3b78d4948ea0ace18c85e9                                                  0.1s
 => => extracting sha256:6d356b48c1c56cccd22e48f043c1e8ac8d79ef86f9e625b548c82014803b7830                                                  0.0s
 => => extracting sha256:9cee687b648e8e2f38b10079e58e752f383ebe19bea21c5a6657a29703a336f8                                                  0.2s
 => => extracting sha256:8ab1992027dfd42035e1028c42f93c50180a2b01b89a2645899d7c9299fcdd5c                                                  0.0s
 => [internal] load build context                                                                                                          0.0s
 => => transferring context: 14.54kB                                                                                                       0.0s
 => [2/7] WORKDIR /app                                                                                                                     0.1s
 => [3/7] RUN apk upgrade --no-cache                                                                                                       1.2s
 => [4/7] COPY requirements-prd.txt requirements-tracing.txt ./                                                                            0.0s
 => [5/7] RUN pip install --no-cache-dir -r requirements-prd.txt     && if [ "false" = "true" ]; then pip install --no-cache-dir -r requi  7.8s
 => [6/7] COPY app/ ./app/                                                                                                                 0.0s
 => [7/7] RUN addgroup -g 1000 app &&     adduser -u 1000 -G app -H -D -s /sbin/nologin app &&     chown -R app:app /app                   0.1s
 => exporting to image                                                                                                                     1.7s
 => => exporting layers                                                                                                                    1.4s
 => => exporting manifest sha256:e3b2e3fa703f8fb248085106b1d4c7b722d8fbb796addf34a59fb23f1ab62b5d                                          0.0s
 => => exporting config sha256:2860cd59ea774f763e9f6c769ad0f9a3e07733d94f5dfc1367ebf5b672c64de9                                            0.0s
 => => exporting attestation manifest sha256:e1f88c69e2b28d66f8c75362c8b4c0269721bd6298a2588f79687f127f95e5ea                              0.0s
 => => exporting manifest list sha256:d6628b3f9be82cb407b2afc187d64d705f5a6c45f33b2842434f349da787162b                                     0.0s
 => => naming to ghcr.io/kunami264/projeto-final-devops/service-users:stg                                                                  0.0s
 => => unpacking to ghcr.io/kunami264/projeto-final-devops/service-users:stg                                                               0.3s
===== [STG] A construir ghcr.io/kunami264/projeto-final-devops/service-orders:stg =====
[+] Building 10.8s (12/12) FINISHED                                                                                              docker:default
 => [internal] load build definition from Dockerfile                                                                                       0.0s
 => => transferring dockerfile: 1.32kB                                                                                                     0.0s
 => [internal] load metadata for docker.io/library/python:3.12-alpine3.24                                                                  0.2s
 => [internal] load .dockerignore                                                                                                          0.0s
 => => transferring context: 158B                                                                                                          0.0s
 => [1/7] FROM docker.io/library/python:3.12-alpine3.24@sha256:c5ba3deef00c7758561a0f03c26f44f10589263d40e732b8748e0d1f38f6dd89            0.0s
 => => resolve docker.io/library/python:3.12-alpine3.24@sha256:c5ba3deef00c7758561a0f03c26f44f10589263d40e732b8748e0d1f38f6dd89            0.0s
 => [internal] load build context                                                                                                          0.0s
 => => transferring context: 14.60kB                                                                                                       0.0s
 => CACHED [2/7] WORKDIR /app                                                                                                              0.0s
 => CACHED [3/7] RUN apk upgrade --no-cache                                                                                                0.0s
 => [4/7] COPY requirements-prd.txt requirements-tracing.txt ./                                                                            0.0s
 => [5/7] RUN pip install --no-cache-dir -r requirements-prd.txt     && if [ "false" = "true" ]; then pip install --no-cache-dir -r requi  8.7s
 => [6/7] COPY app/ ./app/                                                                                                                 0.0s 
 => [7/7] RUN addgroup -g 1000 app &&     adduser -u 1000 -G app -H -D -s /sbin/nologin app &&     chown -R app:app /app                   0.1s
 => exporting to image                                                                                                                     1.7s
 => => exporting layers                                                                                                                    1.4s
 => => exporting manifest sha256:9431d8189debb4d061d0f7ec9d923af55ce3964fe056689b4afe0d9e6e213a08                                          0.0s
 => => exporting config sha256:18edff9b2399d3a98becd936890fd7139ef9dcbadf11c17ec28831c9c6ae4af5                                            0.0s
 => => exporting attestation manifest sha256:a5e1b61444b20a67cd6fd6c133619983c0a7a11558ba9159cf37f949ef53500a                              0.0s
 => => exporting manifest list sha256:5687b9278732b10523128dc57de8331509afe9dc1b124de1970f2e366ad1943a                                     0.0s
 => => naming to ghcr.io/kunami264/projeto-final-devops/service-orders:stg                                                                 0.0s
 => => unpacking to ghcr.io/kunami264/projeto-final-devops/service-orders:stg                                                              0.3s
===== [STG] A construir ghcr.io/kunami264/projeto-final-devops/web:stg =====
[+] Building 5.6s (9/9) FINISHED                                                                                                 docker:default
 => [internal] load build definition from Dockerfile                                                                                       0.0s
 => => transferring dockerfile: 505B                                                                                                       0.0s
 => [internal] load metadata for docker.io/nginxinc/nginx-unprivileged:1.27-alpine                                                         1.4s
 => [internal] load .dockerignore                                                                                                          0.0s
 => => transferring context: 57B                                                                                                           0.0s
 => [1/4] FROM docker.io/nginxinc/nginx-unprivileged:1.27-alpine@sha256:65e3e85dbaed8ba248841d9d58a899b6197106c23cb0ff1a132b7bfe0547e4c0   1.5s
 => => resolve docker.io/nginxinc/nginx-unprivileged:1.27-alpine@sha256:65e3e85dbaed8ba248841d9d58a899b6197106c23cb0ff1a132b7bfe0547e4c0   0.0s
 => => sha256:edee89a8728beee0563123f811dd6596a07077f38b5bcd87791da05a7db60fde 1.40kB / 1.40kB                                             0.2s
 => => sha256:f23a1d1674912e005f43dd93ab9fdca5c6bcda76013afa034d523a769de5551e 16.03MB / 16.03MB                                           0.8s
 => => sha256:04c5cf615192471cc36cb4405a2516eb6443c853c8179c9710575baa9acc39e7 404B / 404B                                                 0.5s
 => => sha256:0ab5686976ac25d8ac38b59e4690f7a99dce9b343865d7def137b65e662e8c23 1.21kB / 1.21kB                                             0.5s
 => => sha256:8d683a284cf1e30b36a23c1dd71f49365d1d6bc348b100e6a0d32683f649ccf9 957B / 957B                                                 0.3s
 => => sha256:513bae533eb237e219e2d3412e0dbb9cd94c25b2b84530b5131fda9512c0e773 627B / 627B                                                 0.2s
 => => sha256:d51f1218ef72c44a300c138c2a1de9a8461ee6063060c1f670f32546b39a3ce7 2.80kB / 2.80kB                                             0.3s
 => => sha256:0a44daad67e98d09449e0547e0f72e69b317d0abe1e579a4f352307161ac8cc9 1.79MB / 1.79MB                                             0.6s
 => => sha256:6e771e15690e2fabf2332d3a3b744495411d6e0b00b2aea64419b58b0066cf81 3.99MB / 3.99MB                                             0.5s
 => => extracting sha256:6e771e15690e2fabf2332d3a3b744495411d6e0b00b2aea64419b58b0066cf81                                                  0.0s
 => => extracting sha256:0a44daad67e98d09449e0547e0f72e69b317d0abe1e579a4f352307161ac8cc9                                                  0.0s
 => => extracting sha256:d51f1218ef72c44a300c138c2a1de9a8461ee6063060c1f670f32546b39a3ce7                                                  0.0s
 => => extracting sha256:513bae533eb237e219e2d3412e0dbb9cd94c25b2b84530b5131fda9512c0e773                                                  0.0s
 => => extracting sha256:8d683a284cf1e30b36a23c1dd71f49365d1d6bc348b100e6a0d32683f649ccf9                                                  0.0s
 => => extracting sha256:04c5cf615192471cc36cb4405a2516eb6443c853c8179c9710575baa9acc39e7                                                  0.0s
 => => extracting sha256:0ab5686976ac25d8ac38b59e4690f7a99dce9b343865d7def137b65e662e8c23                                                  0.0s
 => => extracting sha256:edee89a8728beee0563123f811dd6596a07077f38b5bcd87791da05a7db60fde                                                  0.0s
 => => extracting sha256:f23a1d1674912e005f43dd93ab9fdca5c6bcda76013afa034d523a769de5551e                                                  0.1s
 => [internal] load build context                                                                                                          0.0s
 => => transferring context: 41.59kB                                                                                                       0.0s
 => [2/4] RUN apk upgrade --no-cache                                                                                                       2.2s
 => [3/4] COPY nginx.conf.template /etc/nginx/templates/default.conf.template                                                              0.0s
 => [4/4] COPY static/ /usr/share/nginx/html/                                                                                              0.0s
 => exporting to image                                                                                                                     0.4s
 => => exporting layers                                                                                                                    0.3s
 => => exporting manifest sha256:bf5e22367495f9ebebc8e86c38e7279ede25af1848322c5f88da23be8129d75e                                          0.0s
 => => exporting config sha256:651ed8863867d25fb0bdbe502bdea74a030bbfe0208beb6c97e208e462d0d4fe                                            0.0s
 => => exporting attestation manifest sha256:ede7bc9efb1fbc07cf0e8752d738b1c46cd5ef3bffb5cc0f52f1767216f61670                              0.0s
 => => exporting manifest list sha256:ae2942f9137ab766a80943b3ff95c4e2a48831cc2295d6a37679eba73c3eec7d                                     0.0s
 => => naming to ghcr.io/kunami264/projeto-final-devops/web:stg                                                                            0.0s
 => => unpacking to ghcr.io/kunami264/projeto-final-devops/web:stg                                                                         0.1s
helm lint ./helm -f ./helm/values-staging.yaml
==> Linting ./helm
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed
===== [STG] Build concluído ✅  (seguinte: make run-stg) =====
daniel-almeida@daniel-ubuntu:~/Transferências/ProjetoFinal$ make run-stg
===== [K8S] Addons do cluster (DNS, armazenamento e métricas) =====
! Rede do cluster (Calico) com credenciais inválidas: a reiniciar o calico-node para as renovar
daemonset.apps/calico-node restarted
Waiting for daemon set spec update to be observed...
Waiting for daemon set "calico-node" rollout to finish: 0 out of 1 new pods have been updated...
Waiting for daemon set "calico-node" rollout to finish: 0 out of 1 new pods have been updated...
Waiting for daemon set "calico-node" rollout to finish: 0 of 1 updated pods are available...
daemon set "calico-node" successfully rolled out
No resources found
  ✓ addon dns já ativo
  ✓ addon hostpath-storage já ativo
  ✓ addon metrics-server já ativo
  ✓ coredns pronto
  ✓ hostpath-provisioner pronto
===== [K8S] Observabilidade (namespace observability) =====
namespace/observability created
networkpolicy.networking.k8s.io/default-deny-all created
networkpolicy.networking.k8s.io/allow-dns created
networkpolicy.networking.k8s.io/allow-prometheus-scrape-egress created
networkpolicy.networking.k8s.io/allow-prometheus-ingress-from-grafana created
networkpolicy.networking.k8s.io/allow-grafana-egress-to-prometheus created
serviceaccount/prometheus created
clusterrole.rbac.authorization.k8s.io/prometheus-scraper created
clusterrolebinding.rbac.authorization.k8s.io/prometheus-scraper created
configmap/prometheus-config created
deployment.apps/prometheus created
persistentvolumeclaim/prometheus-pvc created
service/prometheus created
secret/grafana-admin created
configmap/grafana-datasources created
configmap/grafana-dashboard-provider created
configmap/grafana-dashboard-services created
configmap/grafana-alerting created
persistentvolumeclaim/grafana-pvc created
deployment.apps/grafana created
service/grafana created
===== [K8S] A aguardar que fiquem prontos =====
microk8s kubectl rollout status deployment/prometheus -n observability --timeout=300s
Waiting for deployment "prometheus" rollout to finish: 0 of 1 updated replicas are available...
deployment "prometheus" successfully rolled out
microk8s kubectl rollout status deployment/grafana -n observability --timeout=300s
Waiting for deployment "grafana" rollout to finish: 0 of 1 updated replicas are available...
deployment "grafana" successfully rolled out
===== [STG] A carregar as imagens no cluster (microk8s) =====
sudo: preserving the entire environment is not supported, '-E' is ignored
[sudo: authenticate] Password:     
unpacking ghcr.io/kunami264/projeto-final-devops/service-users:stg (sha256:d6628b3f9be82cb407b2afc187d64d705f5a6c45f33b2842434f349da787162b)...done
sudo: preserving the entire environment is not supported, '-E' is ignored
unpacking ghcr.io/kunami264/projeto-final-devops/service-orders:stg (sha256:5687b9278732b10523128dc57de8331509afe9dc1b124de1970f2e366ad1943a)...done
sudo: preserving the entire environment is not supported, '-E' is ignored
unpacking ghcr.io/kunami264/projeto-final-devops/web:stg (sha256:ae2942f9137ab766a80943b3ff95c4e2a48831cc2295d6a37679eba73c3eec7d)...done
===== [STG] Deploy via Helm =====
helm --kubeconfig kubeconfig-make.yaml upgrade --install projeto-final ./helm \
        -n staging --create-namespace \
        -f ./helm/values-staging.yaml \
        --set image.tag=stg \
        --wait --timeout 10m || { echo "✗ O deploy em staging não ficou pronto em 10m. Diagnóstico:"; microk8s kubectl get pods,pvc -n staging -o wide || true; microk8s kubectl get events -n staging --sort-by=.lastTimestamp | tail -30 || true; for d in postgres-orders service-users service-orders; do echo "----- logs $d -----"; microk8s kubectl logs -n staging deployment/$d --all-containers --tail=30 || true; done; microk8s kubectl top nodes || true; exit 1; }
Release "projeto-final" does not exist. Installing it now.
NAME: projeto-final
LAST DEPLOYED: Fri Nov 27 11:30:54 2026
NAMESPACE: staging
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
TEST SUITE: None
microk8s kubectl get pods,svc -n staging
NAME                                   READY   STATUS    RESTARTS   AGE
pod/postgres-orders-5bf486bc7f-6tq8r   1/1     Running   0          21s
pod/service-orders-6fc4b764c-vsk4f     1/1     Running   0          21s
pod/service-users-cd45b545c-6hrq4      1/1     Running   0          21s
pod/web-5b5c56759c-5qwf7               1/1     Running   0          21s

NAME                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/postgres-orders   ClusterIP   10.152.183.75    <none>        5432/TCP   21s
service/service-orders    ClusterIP   10.152.183.35    <none>        8001/TCP   21s
service/service-users     ClusterIP   10.152.183.168   <none>        8002/TCP   21s
service/web               ClusterIP   10.152.183.93    <none>        8080/TCP   21s

===== [STG] Staging pronto ✅ =====
  Validar o ambiente (integração + smoke)   make test-stg
  Criar/editar/apagar utilizadores e encomendas    make demo-stg
  Backoffice e APIs (port-forward)          make forward-stg
  Grafana / Prometheus                      make forward-infra

daniel-almeida@daniel-ubuntu:~/Transferências/ProjetoFinal$ make test-stg
===== [STG] A abrir port-forwards e a executar os testes =====
============================================================= test session starts ==============================================================
platform linux -- Python 3.12.13, pytest-9.1.1, pluggy-1.7.0 -- /home/daniel-almeida/Transferências/ProjetoFinal/.venv/bin/python
cachedir: .pytest_cache
rootdir: /home/daniel-almeida/Transferências/ProjetoFinal
configfile: pytest.ini
plugins: platformdirs-4.14.8, anyio-4.16.0
collected 15 items                                                                                                                             

tests/integration/test_integration.py::test_login_with_wrong_password_is_rejected PASSED                                                 [  6%]
tests/integration/test_integration.py::test_users_service_is_healthy PASSED                                                              [ 13%]
tests/integration/test_integration.py::test_orders_service_is_healthy PASSED                                                             [ 20%]
tests/integration/test_integration.py::test_users_metrics_endpoint_is_exposed PASSED                                                     [ 26%]
tests/integration/test_integration.py::test_orders_endpoint_requires_authentication PASSED                                               [ 33%]
tests/integration/test_integration.py::test_order_creation_calls_users_service_end_to_end PASSED                                         [ 40%]
tests/integration/test_integration.py::test_order_creation_with_invalid_user_returns_404 PASSED                                          [ 46%]
tests/integration/test_integration.py::test_create_edit_and_delete_user_and_order_end_to_end PASSED                                      [ 53%]
tests/integration/test_integration.py::test_create_user_requires_authentication PASSED                                                   [ 60%]
tests/integration/test_integration.py::test_backoffice_serves_the_application PASSED                                                     [ 66%]
tests/integration/test_integration.py::test_backoffice_login_and_crud_through_its_own_address PASSED                                     [ 73%]
tests/integration/test_integration.py::test_backoffice_only_proxies_the_login_endpoint PASSED                                            [ 80%]
tests/smoke/test_smoke.py::test_users_service_responds PASSED                                                                            [ 86%]
tests/smoke/test_smoke.py::test_orders_service_responds PASSED                                                                           [ 93%]
tests/smoke/test_smoke.py::test_backoffice_responds PASSED                                                                               [100%]

============================================================== 15 passed in 0.32s ==============================================================
===== [STG] ✅ Staging validado — a promover as imagens para PRD =====
===== [STG→PRD] Promoção das imagens validadas (stg → main, sem novo build) =====
===== [STG] ✅ Imagens promovidas. STG já não é necessário: make stop-stg stop-infra (liberta memória) e make run-prd =====