daniel-almeida@daniel-ubuntu:~/Transferências/ProjetoFinal$ make run-prd
===== [PRD] Pré-requisitos preparados e validados em STG =====
  ✓ imagens, certificado e Keycloak presentes
===== [PRD] Endpoint de token do Keycloak atrás do Ingress HTTPS =====
sed -e 's/__PRD_HOST__/projeto-final.test/g' -e 's/__INGRESS_CLASS__/public/g' \
        k8s/ingress/keycloak-token-prd.yaml | sudo snap run microk8s kubectl apply -f -
ingress.networking.k8s.io/keycloak-token created
===== [PRD] Start via Helm =====
helm --kubeconfig kubeconfig-make.yaml upgrade --install projeto-final ./helm \
        -n production --create-namespace \
        -f ./helm/values-production.yaml \
        --set image.tag=main \
        --set ingress.host=projeto-final.test \
        --set ingress.className=public \
        --set ingress.controllerNamespace=ingress \
        --wait --timeout 5m
Release "projeto-final" does not exist. Installing it now.
NAME: projeto-final
LAST DEPLOYED: Mon Oct 26 14:27:12 2026
NAMESPACE: production
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
TEST SUITE: None
sudo snap run microk8s kubectl get deploy,pods,hpa,pdb,ingress -n production
NAME                              READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/postgres-orders   1/1     1            1           29s
deployment.apps/service-orders    2/2     2            2           29s
deployment.apps/service-users     2/2     2            2           29s
deployment.apps/web               2/2     2            2           29s

NAME                                   READY   STATUS    RESTARTS   AGE
pod/postgres-orders-5bb687bc98-b292r   1/1     Running   0          29s
pod/service-orders-85b8478d8-fpb2n     1/1     Running   0          14s
pod/service-orders-85b8478d8-xz4sn     1/1     Running   0          29s
pod/service-users-7fbb986bdb-2bmdx     1/1     Running   0          29s
pod/service-users-7fbb986bdb-t6wlm     1/1     Running   0          14s
pod/web-bc74bf564-7ht6k                1/1     Running   0          29s
pod/web-bc74bf564-qtdk8                1/1     Running   0          29s

NAME                                                 REFERENCE                   TARGETS                                     MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/service-orders   Deployment/service-orders   cpu: <unknown>/70%, memory: <unknown>/80%   2         8         1          29s
horizontalpodautoscaler.autoscaling/service-users    Deployment/service-users    cpu: <unknown>/70%, memory: <unknown>/80%   2         6         1          29s

NAME                                            MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
poddisruptionbudget.policy/service-orders-pdb   1               N/A               1                     29s
poddisruptionbudget.policy/service-users-pdb    1               N/A               1                     29s

NAME                                      CLASS    HOSTS                ADDRESS   PORTS     AGE
ingress.networking.k8s.io/projeto-final   public   projeto-final.test             80, 443   29s

===== [PRD] Produção disponível em https://projeto-final.test ✅ =====
  BACKOFFICE     https://projeto-final.test/          admin / admin
  API            https://projeto-final.test/users  ·  https://projeto-final.test/orders
  Token          https://projeto-final.test/realms/projeto-final/protocol/openid-connect/token

  1) O host tem de resolver para a máquina do cluster (só uma vez):
       echo '127.0.0.1 projeto-final.test' | sudo tee -a /etc/hosts
  Certificado self-signed: o browser mostra um aviso na primeira visita.
  Como usar: README, secções 4.3 e 6.
