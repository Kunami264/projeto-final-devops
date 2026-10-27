daniel-almeida@daniel-ubuntu:~/Transferências/ProjetoFinal$ make clean
===== [CLEAN PRD] Parar e remover a aplicação (Helm) =====
helm --kubeconfig kubeconfig-make.yaml uninstall projeto-final -n production --wait
These resources were kept due to the resource policy:
[PersistentVolumeClaim] postgres-orders-pvc

release "projeto-final" uninstalled
===== [CLEAN PRD] Namespace production: pods, services, volumes (PVC), secrets, Ingress, HPA =====
sudo snap run microk8s kubectl delete namespace production --ignore-not-found --wait=true --timeout=180s
namespace "production" deleted
===== [CLEAN PRD] Volumes persistentes órfãos =====
===== [CLEAN PRD] Ingress do token e Secret TLS no namespace auth =====
sudo snap run microk8s kubectl delete ingress keycloak-token -n auth --ignore-not-found
ingress.networking.k8s.io "keycloak-token" deleted from auth namespace
sudo snap run microk8s kubectl delete secret projeto-final-tls -n auth --ignore-not-found
secret "projeto-final-tls" deleted from auth namespace
===== [CLEAN PRD] Imagens promovidas para PRD (main) no cluster e no Docker =====
  removida do cluster: ghcr.io/kunami264/projeto-final-devops/service-orders:main
  removida do cluster: ghcr.io/kunami264/projeto-final-devops/service-users:main
  removida do cluster: ghcr.io/kunami264/projeto-final-devops/web:main
  removida do Docker: ghcr.io/kunami264/projeto-final-devops/web:main
  removida do Docker: ghcr.io/kunami264/projeto-final-devops/service-orders:main
  removida do Docker: ghcr.io/kunami264/projeto-final-devops/service-users:main
docker system prune -af --volumes
Deleted Images:
untagged: aquasec/trivy:0.76.1
deleted: sha256:790fd66d1697395d8693d1acaa1ea702406a20f109b6fc7bac8db623eca6c06c
deleted: sha256:fc223b6f033406fd0c5efe59b566295e90cff76ccd2af696bd0d66d53ad83a2d
deleted: sha256:50a0c4df556bfb26b78681b816f64a2bff6be9538e1db0e9d0663f32f9bea136
untagged: ghcr.io/kunami264/projeto-final-devops/service-orders:stg
deleted: sha256:02d6fef6267638f6bc9248f85b0f3597a219ce7bfd19833ccd5641fbef8b638a
deleted: sha256:f4edb89eb5b49cfb6003c0c30b8c80e58c9c239ffb56e7470b91dde1e96bfce9
deleted: sha256:bf0e4b7baabfcce5f8cae9397b32290fab595bca57edd1f774c53967596dd0a9
untagged: ghcr.io/kunami264/projeto-final-devops/service-users:stg
deleted: sha256:c99e462d9ce953ded78f77c531ecbcfdfdfa0e46131c207db9c066f82c96a0d4
deleted: sha256:f3fb9e8dca21ae771231daa58b3bd59f3393d739e4356418f833439cc9c36462
deleted: sha256:0e14a95d86db86c6a920250d6929703766b68a2a28b94847086296064fa0732b
untagged: ghcr.io/kunami264/projeto-final-devops/web:stg
deleted: sha256:875e4c99883991e6697e888ed24997f7aaecd8611f14c25ecbcad09d77d45e65
deleted: sha256:beb7eed25f9f6f217a244ec2d210cfb4e367f3897f01688bd0a91cd732a6f8b1
deleted: sha256:01c1820d642d226691b90c96832fff68217c9cd3ba125d534788b008aad6a0a5

Deleted build cache objects:
f7y8qo4ksmnq340345hqwe2v9
ntd51sjlttbig4zmg2xdns5bz
tqym5ycp9vs7y8tcljxsxo6hy
nonm6h3ihk49ehbt2ofylpt23
539eqas8smfva78lfril5r3s2
3olalc19tsefdevh38kmrii1q
ypfd1kgrvknywtq27niyqzze2
whc83dev3bf3l7zjdftsn9049
jqb1a74nhrtffup2w8w4wcbiw
1jbjv1grc7byeb615iry7l3zf
xdqluo39igz8r3q4vakbqga0i
y6e33tkdzh81kcgvnk17gkood
4u8gytc2cqf81ksptys21uqek
n0enpja0fvmb54w2x67iu14yc
n59601zndvlqh2u4vonb49gah
zbj0ta0e467jcobgbpbdbbxvo
n8hpri4eenfzm0ppb9dmkxgcr
g53s63a6as1zei5k4uinjwur2
1q7ahk0kwpno1z9jn10yewkde
nypkzmhpli1o8fhm7a1z6jg9b
i8ukg9zd49nbdnxsemyd44rmb
cya6yyobm0yj7hx0shz7p8ub4
7bqdn2g6jw0j0pr99mys65h59
tdhnsjdsfo1h9fugkrayka3dy
uu3hxe8quxvynzk3o9b8adn3z
2txukanh61ixq9qra6eggqzqg
wvwh5ixbs0fj5ox5tlqkx5h1b
ozz2koyrlqy7tl5pmhyygblf4
gx66oj7bzn542xtalvcbi7s1c
pywyke1ss5mzqdcnnupioek08
puigiuuppepxd1gfzyoasf6ad
lfeknxm34b1w33sna7u7sdk3j
qyufrlp1lrhb452i5vmgepl2z
y9i5og2512ovm783f2f6cj1cm
a4qluptcg1u00w4tuvcy9r8rr

Total reclaimed space: 493.6MB
docker network prune -f
docker builder prune -af
Total:  0B
===== [CLEAN PRD] Entrada projeto-final.test no /etc/hosts e port-forwards =====
  não existe
===== Estado após a limpeza =====
No resources found in production namespace.
  imagens do projeto no cluster: 9
docker system df
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          0         0         0B        0B
Containers      0         0         0B        0B
Local Volumes   1         0         1.638GB   1.638GB (100%)
Build Cache     0         0         0B        0B
===== [CLEAN STG] Parar e remover a aplicação (Helm) =====
helm --kubeconfig kubeconfig-make.yaml uninstall projeto-final -n staging --wait
These resources were kept due to the resource policy:
[PersistentVolumeClaim] postgres-orders-pvc

release "projeto-final" uninstalled
===== [CLEAN STG] Namespace staging: pods, services, volumes (PVC), secrets, network policies =====
sudo snap run microk8s kubectl delete namespace staging --ignore-not-found --wait=true --timeout=180s
namespace "staging" deleted
===== [CLEAN STG] Volumes persistentes órfãos =====
===== [CLEAN STG] Imagens do projeto no cluster (todas as tags) =====
  removida do cluster: ghcr.io/kunami264/projeto-final-devops/service-orders:sha-8e6a0dc59fb1fba60e93147a438d6990e875ae90
  removida do cluster: ghcr.io/kunami264/projeto-final-devops/service-orders:stg
  removida do cluster: ghcr.io/kunami264/projeto-final-devops/service-orders@sha256:03dc5c9be2b5399686fdce80b2ec82e088bb6f4c0cc854c038e03e636bd2134c
  removida do cluster: ghcr.io/kunami264/projeto-final-devops/service-users:sha-8e6a0dc59fb1fba60e93147a438d6990e875ae90
  removida do cluster: ghcr.io/kunami264/projeto-final-devops/service-users:stg
  removida do cluster: ghcr.io/kunami264/projeto-final-devops/service-users@sha256:63f3d18d9c76b643039807e864f8d71dab5aed383c4187176b22218ce84b6030
  removida do cluster: ghcr.io/kunami264/projeto-final-devops/web:sha-8e6a0dc59fb1fba60e93147a438d6990e875ae90
  removida do cluster: ghcr.io/kunami264/projeto-final-devops/web:stg
  removida do cluster: ghcr.io/kunami264/projeto-final-devops/web@sha256:6be57079ef804562a8ef74a85137327f522fd1885d1eeda8013b248f0201352a
===== [CLEAN STG] Docker: imagens construídas em STG, contentores parados, redes e cache de build =====
docker system prune -af --volumes
Total reclaimed space: 0B
docker network prune -f
docker builder prune -af
Total:  0B
===== [CLEAN STG] Certificado TLS de PRD (gerado em STG) e port-forwards =====
rm -rf .certs
===== Estado após a limpeza =====
No resources found in staging namespace.
  imagens do projeto no cluster: 0
docker system df
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          0         0         0B        0B
Containers      0         0         0B        0B
Local Volumes   1         0         1.638GB   1.638GB (100%)
Build Cache     0         0         0B        0B
===== [CLEAN K8S] Namespaces auth e observability (inclui PVCs e Secrets) =====
sudo snap run microk8s kubectl delete namespace auth observability --ignore-not-found --wait=true --timeout=180s
namespace "auth" deleted
namespace "observability" deleted
===== [CLEAN K8S] Recursos de cluster do Prometheus =====
sudo snap run microk8s kubectl delete clusterrolebinding prometheus-scraper --ignore-not-found
clusterrolebinding.rbac.authorization.k8s.io "prometheus-scraper" deleted
sudo snap run microk8s kubectl delete clusterrole prometheus-scraper --ignore-not-found
clusterrole.rbac.authorization.k8s.io "prometheus-scraper" deleted
===== [CLEAN K8S] Ingress controller =====
sudo snap run microk8s disable ingress
Infer repository core for addon ingress
Disabling Ingress
ingressclass.networking.k8s.io "public" deleted
ingressclass.networking.k8s.io "nginx" deleted
namespace "ingress" deleted
serviceaccount "nginx-ingress-microk8s-serviceaccount" deleted from ingress namespace
clusterrole.rbac.authorization.k8s.io "nginx-ingress-microk8s-clusterrole" deleted
role.rbac.authorization.k8s.io "nginx-ingress-microk8s-role" deleted from ingress namespace
clusterrolebinding.rbac.authorization.k8s.io "nginx-ingress-microk8s" deleted
rolebinding.rbac.authorization.k8s.io "nginx-ingress-microk8s" deleted from ingress namespace
configmap "nginx-load-balancer-microk8s-conf" deleted from ingress namespace
configmap "nginx-ingress-tcp-microk8s-conf" deleted from ingress namespace
configmap "nginx-ingress-udp-microk8s-conf" deleted from ingress namespace
daemonset.apps "nginx-ingress-microk8s-controller" deleted from ingress namespace
Ingress is disabled
===== [CLEAN K8S] Imagens de terceiros carregadas no cluster =====
  removida docker.io/grafana/grafana:11.3.0
  removida docker.io/grafana/grafana@sha256:a0f881232a6fb71a0554a47d0fe2203b6888fe77f4cefb7ea62bed7eb54e13c3
  removida docker.io/library/busybox:1.28.4
  removida docker.io/library/busybox:1.36
  removida docker.io/library/busybox@sha256:141c253bc4c3fd0a201d32dc1f493bcf3fff003b6df416dea4f41046e0f37d47
  removida docker.io/library/busybox@sha256:73aaf090f3d85aa34ee199857f03fa3a95c8ede2ffd4cc2cdb5b94e566b11662
  removida docker.io/library/postgres:16-alpine
  removida docker.io/library/postgres@sha256:f4610795587492cd4fb887c2dc3de301b813278bb6f616992061141b5f15ac36
  removida docker.io/prom/prometheus:v2.55.1
  removida docker.io/prom/prometheus@sha256:2659f4c2ebb718e7695cb9b25ffa7d6be64db013daba13e05c875451cf51b0d3
  removida quay.io/keycloak/keycloak:26.0
  removida quay.io/keycloak/keycloak@sha256:09a381c715ab0b111835b70f2905955274843a219c6f27efb348e4d9f4086858
  removida registry.k8s.io/ingress-nginx/controller:v1.13.8
  removida registry.k8s.io/ingress-nginx/controller@sha256:0e7fad5de70f55c7f5fb61858be5ba6794d61091ad0874e963a61851e43edf99
===== [CLEAN DEV] Docker Compose: contentores, volumes, imagens e órfãos =====
docker compose -f docker-compose.yml down -v --rmi all --remove-orphans
docker compose -p projeto-final-devops down -v --rmi all --remove-orphans
WARN[0000] Warning: No resource found to remove for project "projeto-final-devops". 
===== [CLEAN DEV] Parar todos os contentores =====
docker stop $(docker ps -qa) 2>/dev/null || true
===== [CLEAN DEV] Docker: imagens, contentores, volumes, redes e cache de build =====
docker system prune -af --volumes
Total reclaimed space: 0B
docker volume prune -af
Deleted Volumes:
trivy-cache

Total reclaimed space: 1.638GB
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
docker compose --profile sonar rm -fsv sonarqube
No stopped containers
for v in sonarqube-data sonarqube-extensions sonarqube-logs; do \
        docker volume ls -q --filter label=com.docker.compose.volume=$v | xargs -r docker volume rm; \
done
docker image ls -q sonarqube | xargs -r docker image rm
rm -rf .scannerwork

===== [CLEAN] Tudo removido ✅ =====
  Cluster: releases Helm, namespaces production/staging/auth/observability,
           PVCs, Secrets, Ingress e Ingress controller, ClusterRole/Binding,
           imagens do projeto e imagens de terceiros carregadas no cluster.
  Docker:  todos os contentores parados; imagens, volumes, redes e cache de build removidos
           (docker system prune -af --volumes, volume/network/builder prune).
  Local:   .venv, .certs, ficheiros kubeconfig-*.yaml, caches, *.db, port-forwards e a entrada no /etc/hosts.
  (O cluster microk8s continua instalado.)
daniel-almeida@daniel-ubuntu:~/Transferências/ProjetoFinal$ 