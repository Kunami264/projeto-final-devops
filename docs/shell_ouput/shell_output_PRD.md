daniel-almeida@daniel-ubuntu:~/Transferências/ProjetoFinal$ make run-prd 
===== [K8S] Addons do cluster (DNS, armazenamento e métricas) =====
  ✓ addon dns já ativo
  ✓ addon hostpath-storage já ativo
  ✓ addon metrics-server já ativo
  ✓ coredns pronto
  ✓ hostpath-provisioner pronto
===== [PRD] Imagens main (locais: make build-prd ou make test-stg; senão, pull do registry) =====
  ✓ ghcr.io/kunami264/projeto-final-devops/service-users:main (local)
  ✓ ghcr.io/kunami264/projeto-final-devops/service-orders:main (local)
  ✓ ghcr.io/kunami264/projeto-final-devops/web:main (local)
! O namespace staging tem pods a ocupar memória e PRD não precisa deles: make stop-stg stop-infra
! O namespace observability tem pods a ocupar memória e PRD não precisa deles: make stop-stg stop-infra
===== [PRD] Ingress controller =====
Infer repository core for addon ingress
Enabling Ingress
ingressclass.networking.k8s.io/public created
ingressclass.networking.k8s.io/nginx created
namespace/ingress created
serviceaccount/nginx-ingress-microk8s-serviceaccount created
clusterrole.rbac.authorization.k8s.io/nginx-ingress-microk8s-clusterrole created
role.rbac.authorization.k8s.io/nginx-ingress-microk8s-role created
clusterrolebinding.rbac.authorization.k8s.io/nginx-ingress-microk8s created
rolebinding.rbac.authorization.k8s.io/nginx-ingress-microk8s created
configmap/nginx-load-balancer-microk8s-conf created
configmap/nginx-ingress-tcp-microk8s-conf created
configmap/nginx-ingress-udp-microk8s-conf created
daemonset.apps/nginx-ingress-microk8s-controller created
Ingress is enabled
===== [PRD] Certificado TLS (projeto-final.test) =====
  gerado em .certs
secret/projeto-final-tls created
===== [PRD] A carregar as imagens no cluster (microk8s) =====
sudo: preserving the entire environment is not supported, '-E' is ignored
unpacking ghcr.io/kunami264/projeto-final-devops/service-users:main (sha256:d6628b3f9be82cb407b2afc187d64d705f5a6c45f33b2842434f349da787162b)...done
sudo: preserving the entire environment is not supported, '-E' is ignored
unpacking ghcr.io/kunami264/projeto-final-devops/service-orders:main (sha256:5687b9278732b10523128dc57de8331509afe9dc1b124de1970f2e366ad1943a)...done
sudo: preserving the entire environment is not supported, '-E' is ignored
unpacking ghcr.io/kunami264/projeto-final-devops/web:main (sha256:ae2942f9137ab766a80943b3ff95c4e2a48831cc2295d6a37679eba73c3eec7d)...done
===== [PRD] Start via Helm =====
helm --kubeconfig kubeconfig-make.yaml upgrade --install projeto-final ./helm \
        -n production --create-namespace \
        -f ./helm/values-production.yaml \
        --set image.tag=main \
        --set ingress.host=projeto-final.test \
        --set ingress.className=public \
        --set ingress.controllerNamespace=ingress \
        --wait --timeout 10m || { echo "✗ O deploy em production não ficou pronto em 10m. Diagnóstico:"; microk8s kubectl get pods,pvc -n production -o wide || true; microk8s kubectl get events -n production --sort-by=.lastTimestamp | tail -30 || true; for d in postgres-orders service-users service-orders; do echo "----- logs $d -----"; microk8s kubectl logs -n production deployment/$d --all-containers --tail=30 || true; done; microk8s kubectl top nodes || true; exit 1; }
Release "projeto-final" does not exist. Installing it now.
NAME: projeto-final
LAST DEPLOYED: Fri Nov 27 11:33:38 2026
NAMESPACE: production
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
TEST SUITE: None
===== [PRD] A aguardar que o Ingress encaminhe para os serviços (até 2 min) =====
  ✓ Ingress a responder ( /users->401 /orders->401 )
microk8s kubectl get deploy,pods,hpa,pdb,ingress -n production
NAME                              READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/postgres-orders   1/1     1            1           17s
deployment.apps/service-orders    1/1     1            1           17s
deployment.apps/service-users     1/1     1            1           17s
deployment.apps/web               1/1     1            1           17s

NAME                                   READY   STATUS    RESTARTS   AGE
pod/postgres-orders-5bf486bc7f-8lkm4   1/1     Running   0          17s
pod/service-orders-7c999748c-g8pfl     1/1     Running   0          17s
pod/service-users-98f97f4b4-n4lk9      1/1     Running   0          17s
pod/web-58c44cc69d-7gw6c               1/1     Running   0          17s

NAME                                                 REFERENCE                   TARGETS              MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/service-orders   Deployment/service-orders   cpu: <unknown>/70%   1         3         1          17s
horizontalpodautoscaler.autoscaling/service-users    Deployment/service-users    cpu: <unknown>/70%   1         3         1          17s

NAME                                            MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
poddisruptionbudget.policy/service-orders-pdb   1               N/A               0                     18s
poddisruptionbudget.policy/service-users-pdb    1               N/A               0                     18s

NAME                                      CLASS    HOSTS                ADDRESS   PORTS     AGE
ingress.networking.k8s.io/projeto-final   public   projeto-final.test             80, 443   17s

===== [PRD] Produção disponível em https://projeto-final.test ✅ =====
  BACKOFFICE     https://projeto-final.test/          admin / admin
  API            https://projeto-final.test/users  ·  https://projeto-final.test/orders
  Token (login)  https://projeto-final.test/auth/token

  1) O host tem de resolver para a máquina do cluster (só uma vez):
       echo '127.0.0.1 projeto-final.test' | sudo tee -a /etc/hosts
  Certificado self-signed: o browser mostra um aviso na primeira visita.
  Como usar: README, secções 4.3 e 6.
