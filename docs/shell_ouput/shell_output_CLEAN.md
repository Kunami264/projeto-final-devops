daniel-almeida@daniel-ubuntu:~/Transferências/ProjetoFinal$ make clean
===== [CLEAN PRD] Parar e remover a aplicação (Helm) =====
helm --kubeconfig kubeconfig-make.yaml uninstall projeto-final -n production --wait
These resources were kept due to the resource policy:
[PersistentVolumeClaim] postgres-orders-pvc

release "projeto-final" uninstalled
===== [CLEAN PRD] Namespace production: pods, services, volumes (PVC), secrets, Ingress, HPA =====
namespace "production" deleted
  a aguardar que o namespace production acabe de ser apagado (até 2 min)
===== [CLEAN PRD] Volumes persistentes órfãos =====
===== [CLEAN PRD] Imagens promovidas para PRD (main) no cluster e no Docker =====
  removida do cluster: ghcr.io/kunami264/projeto-final-devops/service-orders:main
  removida do cluster: ghcr.io/kunami264/projeto-final-devops/service-users:main
  removida do cluster: ghcr.io/kunami264/projeto-final-devops/web:main
  removida do Docker: ghcr.io/kunami264/projeto-final-devops/web:main
  removida do Docker: ghcr.io/kunami264/projeto-final-devops/service-orders:main
  removida do Docker: ghcr.io/kunami264/projeto-final-devops/service-users:main
docker system prune -af --volumes
Deleted Images:
untagged: ghcr.io/kunami264/projeto-final-devops/service-orders:stg
deleted: sha256:5687b9278732b10523128dc57de8331509afe9dc1b124de1970f2e366ad1943a
deleted: sha256:9431d8189debb4d061d0f7ec9d923af55ce3964fe056689b4afe0d9e6e213a08
deleted: sha256:a5e1b61444b20a67cd6fd6c133619983c0a7a11558ba9159cf37f949ef53500a
untagged: ghcr.io/kunami264/projeto-final-devops/service-users:stg
deleted: sha256:d6628b3f9be82cb407b2afc187d64d705f5a6c45f33b2842434f349da787162b
deleted: sha256:e3b2e3fa703f8fb248085106b1d4c7b722d8fbb796addf34a59fb23f1ab62b5d
deleted: sha256:e1f88c69e2b28d66f8c75362c8b4c0269721bd6298a2588f79687f127f95e5ea
untagged: ghcr.io/kunami264/projeto-final-devops/web:stg
deleted: sha256:ae2942f9137ab766a80943b3ff95c4e2a48831cc2295d6a37679eba73c3eec7d
deleted: sha256:bf5e22367495f9ebebc8e86c38e7279ede25af1848322c5f88da23be8129d75e
deleted: sha256:ede7bc9efb1fbc07cf0e8752d738b1c46cd5ef3bffb5cc0f52f1767216f61670

Deleted build cache objects:
r9zi3dk1a476q2wy9gjodtr20
nn3d1jmi8ra3urfnui4b4hpep
z8hiljgz81tixq938y2w7n2lz
o9yxwu6hb1q7speuwxykqsfzl
93hdr0bi0iz2ainqwvtwcv4xt
xok3uaxlvun679lsvo2gde218
z98xfqnwgcz809htt4ge2b5gz
trueyhy2o8ep3l2jlv0z9lsdo
yhxkugaosddhw9pkvbn4v4oj6
a9wypm7qxfnhdih4tgg7qv7fz
jnfxm9xxcxtbvfpj8hn918to8
0ekh8ddxb48vkg4p5iho19znw
l6uydsaz68szgrabrap7pvrxs
coykaony8uonqrkg6rzmzl9qf
ik2p737o1wbyn21p7p9dpflxw
j3z6b5403xbk31sd40auehtxt
ql5ohhwx9galijdi4fyceq6c5
04ga6um1ninpdg7cfqqjuiw66
nzb7sgat4a8kuzpl5j1ztomwn
vreiwk7xq2195rr143mmgv5f3
nbz7hxnxvdajy1eti8cazzw9c
bp49ff2tdgef2t77pwslr2j0f
ouinhy2m3gmxbz12pfl9couv4
u8b0yuahd1icd9s4bbznn3ji9
76xy1dloip2lgahhpf6louyxz
z09atwg86j4ajtn30g7av8lg8
wil8jl8oee95bo17pv99q1bb1
0i5o1ao7qj9ytruwre7d2u04d
lxapi3atlteyc61xfyrdphkqd
6jv2zyyisr1t96qjjxg4u7r87
zma0pb97ccv52mkmj0ixldoni
y38jgq816yg2gif0fph32hvdp
j95ezf7ta9z3ukb7mu8eiacy3
n7vcnjotg0by4s1krc4sj431u
dozwval7bnxfkrkg3a2gyz1f8

Total reclaimed space: 402.2MB
docker network prune -f
docker builder prune -af
Total:  0B
===== [CLEAN PRD] Certificado TLS gerado por run-prd =====
rm -rf .certs
===== [CLEAN PRD] Entrada projeto-final.test no /etc/hosts e port-forwards =====
  não existe
===== Estado após a limpeza =====
No resources found in production namespace.
  imagens do projeto no cluster: 12
docker system df
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          0         0         0B        0B
Containers      0         0         0B        0B
Local Volumes   0         0         0B        0B
Build Cache     0         0         0B        0B
===== [CLEAN STG] Parar e remover a aplicação (Helm) =====
helm --kubeconfig kubeconfig-make.yaml uninstall projeto-final -n staging --wait
These resources were kept due to the resource policy:
[PersistentVolumeClaim] postgres-orders-pvc

release "projeto-final" uninstalled
===== [CLEAN STG] Namespace staging: pods, services, volumes (PVC), secrets, network policies =====
namespace "staging" deleted
  a aguardar que o namespace staging acabe de ser apagado (até 2 min)
===== [CLEAN STG] Volumes persistentes órfãos =====
===== [CLEAN STG] Imagens do projeto no cluster (todas as tags) =====
  removida do cluster: ghcr.io/kunami264/projeto-final-devops/service-orders:sha-074bc1de5a7ef6037e7239b3df37f252570f10b7
  removida do cluster: ghcr.io/kunami264/projeto-final-devops/service-orders:sha-5c0b406d6c8522350af44f9a5adfe6c66caf2a62
  removida do cluster: ghcr.io/kunami264/projeto-final-devops/service-orders:stg
  removida do cluster: ghcr.io/kunami264/projeto-final-devops/service-orders@sha256:cae9404fd0067b88ec4a7e92509a2c23afa56978b6e8e5a1db4ea3ec9d316f6b
  removida do cluster: ghcr.io/kunami264/projeto-final-devops/service-users:sha-074bc1de5a7ef6037e7239b3df37f252570f10b7
  removida do cluster: ghcr.io/kunami264/projeto-final-devops/service-users:sha-5c0b406d6c8522350af44f9a5adfe6c66caf2a62
  removida do cluster: ghcr.io/kunami264/projeto-final-devops/service-users:stg
  removida do cluster: ghcr.io/kunami264/projeto-final-devops/service-users@sha256:73eb14504e06147093a64acace1d8b1d1e554f5410a7731b9a1ae88f04de506e
  removida do cluster: ghcr.io/kunami264/projeto-final-devops/web:sha-074bc1de5a7ef6037e7239b3df37f252570f10b7
  removida do cluster: ghcr.io/kunami264/projeto-final-devops/web:sha-5c0b406d6c8522350af44f9a5adfe6c66caf2a62
  removida do cluster: ghcr.io/kunami264/projeto-final-devops/web:stg
  removida do cluster: ghcr.io/kunami264/projeto-final-devops/web@sha256:612cf5e54fd4ce9c7ccaa49bf8599de9b066e0e8c2dbc867a7c0c6d69b67b818
===== [CLEAN STG] Docker: imagens construídas em STG, contentores parados, redes e cache de build =====
docker system prune -af --volumes
Total reclaimed space: 0B
docker network prune -f
docker builder prune -af
Total:  0B
===== [CLEAN STG] Port-forwards =====
===== Estado após a limpeza =====
No resources found in staging namespace.
  imagens do projeto no cluster: 0
docker system df
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          0         0         0B        0B
Containers      0         0         0B        0B
Local Volumes   0         0         0B        0B
Build Cache     0         0         0B        0B
===== [CLEAN K8S] Namespace observability (inclui PVCs) e Keycloak de versões anteriores =====
namespace "observability" deleted
  a aguardar que o namespace observability acabe de ser apagado (até 2 min)
===== [CLEAN K8S] Recursos de cluster do Prometheus =====
microk8s kubectl delete clusterrolebinding prometheus-scraper --ignore-not-found
clusterrolebinding.rbac.authorization.k8s.io "prometheus-scraper" deleted
microk8s kubectl delete clusterrole prometheus-scraper --ignore-not-found
clusterrole.rbac.authorization.k8s.io "prometheus-scraper" deleted
===== [CLEAN K8S] Ingress controller =====
microk8s disable ingress
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
  removida docker.io/library/postgres@sha256:f2f98726820d0342055351c6e9d36e705f5bfffb3dd53ff556325114b08afb6d
  removida docker.io/prom/prometheus:v2.55.1
  removida docker.io/prom/prometheus@sha256:2659f4c2ebb718e7695cb9b25ffa7d6be64db013daba13e05c875451cf51b0d3
  removida registry.k8s.io/ingress-nginx/controller:v1.13.8
  removida registry.k8s.io/ingress-nginx/controller@sha256:0e7fad5de70f55c7f5fb61858be5ba6794d61091ad0874e963a61851e43edf99
===== [CLEAN K8S] Addons ativados pelo projeto (métricas, armazenamento, DNS) =====
for a in metrics-server hostpath-storage:destroy-storage dns; do microk8s disable $a </dev/null; done
Infer repository core for addon metrics-server
Disabling Metrics-Server
Error from server (NotFound): configmaps "metrics-server-config" not found
Error from server (NotFound): deployments.apps "metrics-server-v0.2.1" not found
serviceaccount "metrics-server" deleted from kube-system namespace
clusterrole.rbac.authorization.k8s.io "system:aggregated-metrics-reader" deleted
clusterrole.rbac.authorization.k8s.io "system:metrics-server" deleted
rolebinding.rbac.authorization.k8s.io "metrics-server-auth-reader" deleted from kube-system namespace
clusterrolebinding.rbac.authorization.k8s.io "metrics-server:system:auth-delegator" deleted
clusterrolebinding.rbac.authorization.k8s.io "system:metrics-server" deleted
service "metrics-server" deleted from kube-system namespace
deployment.apps "metrics-server" deleted from kube-system namespace
apiservice.apiregistration.k8s.io "v1beta1.metrics.k8s.io" deleted
clusterrolebinding.rbac.authorization.k8s.io "microk8s-admin" deleted
Metrics-Server is disabled
Infer repository core for addon hostpath-storage
Disabling hostpath storage.
deployment.apps "hostpath-provisioner" deleted from kube-system namespace
storageclass.storage.k8s.io "microk8s-hostpath" deleted
serviceaccount "microk8s-hostpath" deleted from kube-system namespace
clusterrole.rbac.authorization.k8s.io "microk8s-hostpath" deleted
clusterrolebinding.rbac.authorization.k8s.io "microk8s-hostpath" deleted
Storage removed.
sudo: preserving the entire environment is not supported, '-E' is ignored
Storage space reclaimed.
Infer repository core for addon dns
Disabling DNS
Reconfiguring kubelet
Removing DNS manifest
deployment.apps "coredns" deleted from kube-system namespace
pod/coredns-66ffc85ffb-qr74d condition met
serviceaccount "coredns" deleted from kube-system namespace
configmap "coredns" deleted from kube-system namespace
service "kube-dns" deleted from kube-system namespace
clusterrole.rbac.authorization.k8s.io "coredns" deleted
clusterrolebinding.rbac.authorization.k8s.io "coredns" deleted
sudo: preserving the entire environment is not supported, '-E' is ignored
sudo: preserving the entire environment is not supported, '-E' is ignored
No callback tokens file.
make: [Makefile:573: clean-infra] Error 1 (ignorado)
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
Total reclaimed space: 0B
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
===== [CLEAN K8S] Tudo o que resta em todos os namespaces (kubectl delete all --all --all-namespaces) =====
microk8s kubectl delete all --all --all-namespaces
pod "calico-kube-controllers-6d7fffdff7-f8mfd" deleted from kube-system namespace
pod "calico-node-dl66j" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-2cglh" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-2rk2g" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-45vjb" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-57hk2" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-686zg" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-6nq8c" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-6tbl7" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-7792l" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-7jvjj" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-7k4k7" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-7kdlq" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-7ltdx" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-7q4bb" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-7zf6m" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-8hrx6" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-9g6fx" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-c4qr9" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-c84f5" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-cfctk" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-crfc5" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-cxpkr" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-d24cb" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-dsc74" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-dxb84" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-frntz" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-h46rg" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-hgnh2" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-hpgks" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-hs9z9" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-jhbbx" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-jp962" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-js997" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-k9jw6" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-kdrcf" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-l7rvn" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-lcpnt" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-m4r68" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-mst5w" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-n9zrr" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-ntbwd" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-p2mqw" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-qhdck" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-qm6tx" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-s52jq" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-s7drh" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-sxdvw" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-t5vxb" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-t9n6g" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-tkn7d" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-vsjhq" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-whdcc" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-wk7gb" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-wzw6r" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-xbnjk" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-xcfbg" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-xwrvq" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-z4nsb" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-z5wgq" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-zrk96" deleted from kube-system namespace
pod "hostpath-provisioner-daniel-ubuntu-zw5pd" deleted from kube-system namespace
service "kubernetes" deleted from default namespace
daemonset.apps "calico-node" deleted from kube-system namespace
deployment.apps "calico-kube-controllers" deleted from kube-system namespace
===== [CLEAN K8S] Imagens do cluster que já não estão em uso =====
microk8s ctr images prune --all
sudo: preserving the entire environment is not supported, '-E' is ignored
INFO[0000] deleted image: docker.io/calico/cni:v3.29.3  
INFO[0000] deleted image: docker.io/calico/cni@sha256:53f826d3f565a6635b4d58ea4fcfdc0e7ea418ffd4dbb495b4c801074e6eb99c 
INFO[0000] deleted image: docker.io/calico/kube-controllers:v3.29.3 
INFO[0000] deleted image: docker.io/calico/kube-controllers@sha256:5516ab776c38525fcc985a3030b4f2fd472da68b4170601c23bf6887bfdce703 
INFO[0000] deleted image: docker.io/calico/node:v3.29.3 
INFO[0000] deleted image: docker.io/calico/node@sha256:eed399f2a727cfc1f374ab5c9cda6123c207e794ed8dc66c7eb6d8db412669e1 
INFO[0000] deleted image: docker.io/cdkbot/hostpath-provisioner:1.6.0 
INFO[0000] deleted image: docker.io/cdkbot/hostpath-provisioner@sha256:582d3aeaabbb9e6ef8b8ea13408eeefe232c4888109c9e067d8f15ce75764716 
INFO[0000] deleted image: docker.io/coredns/coredns:1.12.3 
INFO[0000] deleted image: docker.io/coredns/coredns@sha256:1391544c978029fcddc65068f6ad67f396e55585b664ecccd7fefba029b9b706 
INFO[0000] deleted image: docker.io/jaegertracing/all-in-one:1.60 
INFO[0000] deleted image: docker.io/jaegertracing/all-in-one@sha256:4fd2d70fa347d6a47e79fcb06b1c177e6079f92cba88b083153d56263082135e 
INFO[0000] deleted image: docker.io/library/nginx:latest 
INFO[0000] deleted image: docker.io/library/nginx@sha256:06aa3d7be10bc6307990c81bdca075793132e9163391abc370c015e344e23128 
INFO[0000] deleted image: registry.k8s.io/metrics-server/metrics-server:v0.8.0 
INFO[0000] deleted image: registry.k8s.io/metrics-server/metrics-server@sha256:89258156d0e9af60403eafd44da9676fd66f600c7934d468ccc17e42b199aee2 
INFO[0000] deleted image: registry.k8s.io/pause@sha256:ee6521f290b2168b6e0935a181d4cff9be1ac3f505666ef0e3c98fae8199917a 
INFO[0000] deleted image: sha256:01502ff793d003e790470c300d0180fccfb5c8b0337b473b4c6f27c90ae6ad43 
INFO[0000] deleted image: sha256:03219d84ae7e10fcf3cad8b70e081dceb7488c5451ac7ffbf14f9b5ab2d586bb 
INFO[0000] deleted image: sha256:04676dd1086a830fc19d9c825f435cef57eace7fa8c6fae1ba5975f7a9ce8d00 
INFO[0000] deleted image: sha256:061e1454ce109251c9515e3e01ac0e15d9cbec00d6847452299fa5a709de99c5 
INFO[0000] deleted image: sha256:081c3f41a0d1fe07829e3324b77b70f45ce58a43d91b2c1d78987f16d4aedef7 
INFO[0000] deleted image: sha256:0e80ec419badc723e033949b24995903cbb97d1e4bf90720ecba5f0c49cad316 
INFO[0000] deleted image: sha256:102b1cbd713334b883becde99fa763451adeb8ccda33a1f3a9b01e4912422bf8 
INFO[0000] deleted image: sha256:11d79908556da9f84f8ac878135f005f757bc9ad96d67fac3683f42a14d99e3a 
INFO[0000] deleted image: sha256:12442e8d3c59f5ca0cbcceac2f6ea04bf8eb1b32292b6c12e9acfe5e50484dca 
INFO[0000] deleted image: sha256:1298f8b0361371068b477ceb81ccb1a4e70d030b1da6365c16b81127c593e3f0 
INFO[0000] deleted image: sha256:150b785caac9ac6a7c673ad666c7184ea78432fd93bcc7fe19f6c93d670bb93e 
INFO[0000] deleted image: sha256:18edff9b2399d3a98becd936890fd7139ef9dcbadf11c17ec28831c9c6ae4af5 
INFO[0000] deleted image: sha256:1d520243c488c22dfcd99d4cba365915c2a6f70ac5df7603238ead81843ac1d8 
INFO[0000] deleted image: sha256:1ea428aa63b903149e9beed2341cc57763daca0d9be6c99ba3ef048929d6141e 
INFO[0000] deleted image: sha256:1f9e30d6c3f09069b7cb09b5db6dcb0b4847e295a96899ac6677383aa302ebee 
INFO[0000] deleted image: sha256:21a72f6adfe28b232cc8235b3487268661a7431d364355d2e1cbc12db80aaec5 
INFO[0000] deleted image: sha256:23637b06816c72158f6866dc4c9acd7ffb4ba66dd9f9559fff3826e7b898c7fa 
INFO[0000] deleted image: sha256:248eca22deaf3a8d2ee306f82ead768b6088e38bffc3b5d784cfb6493b56506f 
INFO[0000] deleted image: sha256:2598bedc8f0ea69e954b9d0297dfac0178cfd128fc518d6b118e825a75fcd853 
INFO[0000] deleted image: sha256:25c943ed3780dbbf62595e0d4d78d520e8f31fe5ecd69689555efb2951d81106 
INFO[0000] deleted image: sha256:27832a982b38fc20ade2fb1d86ee712a28f741255f3530fc35214503584641f4 
INFO[0000] deleted image: sha256:2860cd59ea774f763e9f6c769ad0f9a3e07733d94f5dfc1367ebf5b672c64de9 
INFO[0000] deleted image: sha256:291f14f7665ad5c2e1ae8aafdf3084d055c6ea955280a06efec1c184856e8f7d 
INFO[0000] deleted image: sha256:2ae8f55aa1acb5b2174b359566cc273c2ddcf526cb669e3b02ba56a5b5612d63 
INFO[0000] deleted image: sha256:2af6b79d7157fca1888ee64d7dde5be52a364d30060fdaa8a32e8803569f3de5 
INFO[0000] deleted image: sha256:2b3c064057a3646f1371365bc4e34b64ec65316efee4bf83fe0ddaf0440e575c 
INFO[0000] deleted image: sha256:2d0588b3dc5de1a90399d526f5783e6a9fda93944919f3a9dc819a5142c0144c 
INFO[0000] deleted image: sha256:31b7df755869f3d5b0a8a87e0f29ea85cac62a522f008681d304e311160d181f 
INFO[0000] deleted image: sha256:320d92f3cec75c02eed3ab0a15186ea879fedb5a3acf7c178082e3b84e07349d 
INFO[0000] deleted image: sha256:34984cc4029779dd880e98325144ddd911cfc4b8870076d1e04abd6a754690b9 
INFO[0000] deleted image: sha256:35726244c51a57338a5a5a5ad8a7e2b18f4ecb8dccd51224cab33ac2ea6a5df0 
INFO[0000] deleted image: sha256:37d0a774edadd650458385a9a19d3435ad0d474e2079606b88c337a8fa47e267 
INFO[0000] deleted image: sha256:39339e3371cc41f93f00975ebadebf25747afd7eb17594bacb0c2a1c651b4fe9 
INFO[0000] deleted image: sha256:3b7d542b0a5a215e91023e23b4b30d935c907f53c8d3a19808328df723c20b65 
INFO[0000] deleted image: sha256:3f042a281221bd73228611f56946b3bff494e53f766d602af4f5c3d9472ece1f 
INFO[0000] deleted image: sha256:425e267d15ea187348a198e7ec22ef7c5f1dd8cee061c97a9ee9319646a042bf 
INFO[0000] deleted image: sha256:468f7fbebcce1ec79a2611687a972c85b54b607ddb29bee146a25e1c94196e8d 
INFO[0000] deleted image: sha256:46f6399878d2efea9c3824beb190b19e87ab83aac15c4a78c9f721a56a121216 
INFO[0000] deleted image: sha256:499a2245e0390b921e8f55eaa4299ee275e7d8472c2f3b5bf5b78138fcca8e0d 
INFO[0000] deleted image: sha256:4b79f327ec4c6329c243f2a2e84eff3c721d760817856eb3741741f131795060 
INFO[0000] deleted image: sha256:4c66fcc2b79ff2ebec02ac48075936006af930ed3069dc5dadcaec2e20b6a3d1 
INFO[0000] deleted image: sha256:4e529438e7d09708ecf232d94c9041a539cac9f40ec375ee6a899db61e72d09b 
INFO[0000] deleted image: sha256:4e792298b47566e3a6fc6248e7df6cd5b303193ce7720e03dac8890a35c14d2c 
INFO[0000] deleted image: sha256:52485614696cea8d05e932c45a60fb6ddef63371319e06d4443efa4b60aab432 
INFO[0000] deleted image: sha256:5412a7a7cbd7d9577625b6696777122a30dd30b3fe5ef6b5c9d497e9d8ac1dc8 
INFO[0000] deleted image: sha256:54bd7951b7f3d91d005b55eefcba86584b8a7fe5c4461d09ea8272396bb32dfd 
INFO[0000] deleted image: sha256:59186be36c6c4bea0d9b6fde982aa2b2072d9849ce9f640281e97fcde7cf20d9 
INFO[0000] deleted image: sha256:5b87931dc0ebc94df52379bfd0bb05b181a30d335d7d8f7d6b767a66f20b05d2 
INFO[0000] deleted image: sha256:5ce0bee933b5d09888d7e030561fb20c7c94e31557cadf9f7e060b6f4d2514a2 
INFO[0000] deleted image: sha256:5de7b3593c99a462e2cc552e813abc83d7b8e05f922e0df4d1ac1fa7734bd4e0 
INFO[0000] deleted image: sha256:60c23795bdadeb90d48a9e472143f4bb0bc4f8cb0135e9eb03b8948dfb79b249 
INFO[0000] deleted image: sha256:64357a0240d4e4c3bc8f44a125584146976582a4b5380a33512c57730bc1c101 
INFO[0000] deleted image: sha256:646fdd8f711bf8292890294043ea3f2722d44a0aab8259709e12d6736cf3d102 
INFO[0000] deleted image: sha256:651ed8863867d25fb0bdbe502bdea74a030bbfe0208beb6c97e208e462d0d4fe 
INFO[0000] deleted image: sha256:67d04cad2daf03895e22e1a15b96548ce8098205ddeb2b7bafd5957764ee1acc 
INFO[0000] deleted image: sha256:69a93763f41482d748fa53f2bdc64fd657f9baf17bed0e9d6af0c0c258c66bbf 
INFO[0000] deleted image: sha256:6aa50b9fb5a5cb8fc8b1a98a6ae4aa44b0e9733402145fbb45508ff526e3604b 
INFO[0000] deleted image: sha256:6b919fc797faab6421df342dd53dfe44d0526e001cbec90a1a0a58dc40379e53 
INFO[0000] deleted image: sha256:6c174bffb9bfab049cb5ed74348fd1b390e1dbd04e42178c981c3a0b8edbbcfa 
INFO[0000] deleted image: sha256:6f3ff3c86cd0e2dba0080e2937c7c73b89d6162f69ae85e3c1d5b6c5d545df4a 
INFO[0000] deleted image: sha256:70072faf471b439e96997147faadc1fce37f372ef8667413fb2747e77d535a20 
INFO[0000] deleted image: sha256:70479af011917248d4249015616fe002aec6e8acd430dc86a0a70cb10cbc35ff 
INFO[0000] deleted image: sha256:72340ea9c912561996d6d5c3ffcac6014db3eb907e3940c4ba974644d873a1c6 
INFO[0000] deleted image: sha256:757c07c1f7471c6a325e844316337900fca96210751d11abd6870435d757aa53 
INFO[0000] deleted image: sha256:75a5aeb8b09ae656727de546f33e078c4b7e1b846adaf711799e23e5b58cc7b1 
INFO[0000] deleted image: sha256:75e0e685bde7051c297fb2b11a7b1cae6a20a58448bfd860e61d672a01471143 
INFO[0000] deleted image: sha256:7abcaf199d1f33707c8918c385a652496e9c876877329de969171d82f3ade921 
INFO[0000] deleted image: sha256:7c5219b29754486772d87ddd908a03f7f6e6e8962d4cabc3db41dad4ee6c87c2 
INFO[0000] deleted image: sha256:7d2c6d5b14ea59d0cd651313564c2342a8baa0df42a9cdafed4d1f9675e6286f 
INFO[0000] deleted image: sha256:7ef6cf8e850a2f002805c2872f2963c0f3d8c16be69ca91fa62a88f87263088b 
INFO[0000] deleted image: sha256:7f58833e10df1d3a6dcb958c42ea49efdfcd061bd79ffed57219f114d2aa8057 
INFO[0000] deleted image: sha256:7ff8c97cbda192b744217508a185c1a88f9c3e7d190990ff86db0dff4c20909d 
INFO[0000] deleted image: sha256:806675ffbe06308006fdc40e882a615cc6dd4eff28feca293245b545f039968b 
INFO[0000] deleted image: sha256:815011e28a56912b42326401ce6f866ac47261aa094dfdd486291dde4ad61b50 
INFO[0000] deleted image: sha256:886b46c02917cc1731c1111cb70e21e4cec8eee436b9d48cd6cf5568c7b53327 
INFO[0000] deleted image: sha256:89a35e2ebb6b938201966889b5e8c85b931db6432c5643966116cd1c28bf45cd 
INFO[0000] deleted image: sha256:8a973e37ca613e3e333768d8a0b6c4e8ba1e420df8a20d49b25f8d0d98d51e42 
INFO[0000] deleted image: sha256:8ac16feb092063b0ee139451c6114423c6e2b03f880f8be098a377ff659c3244 
INFO[0000] deleted image: sha256:8eca12a0dee8d166376b8c684d8ffc350d4b8b76e0e5b63c7c9c584c0442c6bd 
INFO[0000] deleted image: sha256:8ee577ee3bb4d2182f9459a185be92ddb5dac0964ede4679e5ded1f0550260d4 
INFO[0000] deleted image: sha256:945b7884358f977d9c7e5c692a15ec5f6e5c86a3d03d65fe9a6598e34e488ef4 
INFO[0000] deleted image: sha256:9474a24b13e8560954f998b0c0ef26588f9ce47f6631f3188963da6020ee9ab4 
INFO[0000] deleted image: sha256:9bc06bbf4f7431d6e76e7dea5a789bbbb36b3f332f5fdd5f480680dab0779404 
INFO[0000] deleted image: sha256:9d8c72d54f7ba3c08ec7ccfcdcc819317f6d9c3dc5fc83f1539a76cc4a770f13 
INFO[0000] deleted image: sha256:9e1cda27eea0d19c983ce669ffb8b50fbe8b4a1a9b88a4ab9312f850a20f21ad 
INFO[0000] deleted image: sha256:a09faa76aadfb094dce1a946b3dda003f1f2b0ff0d0bad0f2026427d4e4e7e87 
INFO[0000] deleted image: sha256:a0e6a8c5c4a706a1bb88a2bc947e6abb3b7070f57dcf1fbc9af3cf35adb121e5 
INFO[0000] deleted image: sha256:a13159c79375a203527701d3672a83c6991fcff9615f2d57e8a10d384cdac80b 
INFO[0000] deleted image: sha256:a6710c48723f9b9a76d01195642ed045b8ee4e1528c159aa5a0e2b6aa32aff72 
INFO[0000] deleted image: sha256:a75a58b9e82530188874d7bc6fdc674b0c570699904296406c52f8c7e75f984d 
INFO[0000] deleted image: sha256:a8e2ac2a14035729760bb6bdb035b5ba36fcb3774f30043b82b99902d7e99aa0 
INFO[0000] deleted image: sha256:acd9a8cae22fdcaa10277503c3a0daeac560d1c3105013a56644132630d0a806 
INFO[0000] deleted image: sha256:add6372545fb406bb017769f222d84c50549ce13e3b19f1fbaee3d8a4aaef627 
INFO[0000] deleted image: sha256:afb61768ce381961ca0beff95337601f29dc70ff3ed14e5e4b3e5699057e6aa8 
INFO[0000] deleted image: sha256:b129addf5634108e1ae390e401ded04f21e0bc743be728c6fe243e47d2962b0f 
INFO[0000] deleted image: sha256:b1676cf4f45b747034ef9b5e174512d27bbf540f3d643126f5914ccf50fcbdde 
INFO[0000] deleted image: sha256:b2ab938e00318edc3db6bb52568b82fa2bed507185e8f6752b59a0fecb3d5eda 
INFO[0000] deleted image: sha256:b31e699b74965d4f01365ed8b332ab384b39603ee29ae2bcb1cc7ed9d5a92729 
INFO[0000] deleted image: sha256:b60a66fdfa5eeeac673842c0a5a084b2a570dedeb58dfbea80a9b40e728850dd 
INFO[0000] deleted image: sha256:b6db4be173443d2379a735e4d3391409f95c64c56b4581d03a9f78aa683e8a86 
INFO[0000] deleted image: sha256:b6f19d9ac66c9b3dcdc95b7ff76ff97a4231c08e9fbd46dc5260fc7f068f9d32 
INFO[0000] deleted image: sha256:b7c873bd97bdc9046fc894e0b216c8aef31e0db4c5b761fb53022e40577ab6c0 
INFO[0000] deleted image: sha256:b80d8e98517275ec964015f3f6b27e49cb1e4f7a958d231c5d982bba31625a8b 
INFO[0000] deleted image: sha256:bb00175247c341ab87be5c32bc7948968a777b08b7f733392be438f2c6f09aad 
INFO[0000] deleted image: sha256:bbde6abd31850a87f012f183a9663e4d8768243ab5e628381566bc89f8842d23 
INFO[0000] deleted image: sha256:bc6c1e09a843da7191a25631adb08537bdcf0ee8c188bcb55ca8b51039272809 
INFO[0000] deleted image: sha256:c2aff362143619e5d0fe492c5d774bf8cb7b671ad11ffb090b05517cd559b34c 
INFO[0000] deleted image: sha256:c32a61742eb35a94209c0eb0aa0b5bff27e39500475d9535922f157c8bac050d 
INFO[0000] deleted image: sha256:c489ef6f500b54e54a0ba25e32502bb3b890d3e5a0ac8a755d07b61c722b677d 
INFO[0000] deleted image: sha256:c54a696c68013b2f8f42f479e00a2b6ad24c5ef10ee31cdfb8972cec3dad7eb7 
INFO[0000] deleted image: sha256:cac9a2bc0c74e65b48fbc518aad5e704d392eca76278db59cc7a2bd88a57274a 
INFO[0000] deleted image: sha256:cdcce3ec4624a24c28cdc07b0ee29ddf6703628edee7452a3f8a8b4816bfd057 
INFO[0000] deleted image: sha256:cf1a7ff747c89acd747ec2e82d9e322e2d2eda402dc5d4e002cfb0cbf479250e 
INFO[0000] deleted image: sha256:d090ef0c3fa38df49d89dfcca52ce77f71d88a8db6bd8388d78817cad20a0c1f 
INFO[0000] deleted image: sha256:d10a7d5af53286b768a754a9b30bed91ac51ab937ffdff2c3a494e9695eb1a01 
INFO[0000] deleted image: sha256:d5002256936c44c48f89a380f7f0df067c18ca5868fd30aeb18cee299381d114 
INFO[0000] deleted image: sha256:d51c25836f5fc130205a276f9c68ec7b32717428cf5c2d71b0fd6a2866409912 
INFO[0000] deleted image: sha256:d8372bcd0ee03524b3951dc04a006c2606c40f4f562d9349f6c4675e61579ddd 
INFO[0000] deleted image: sha256:dc37ab9b1bd5401c1bcb681d58893029ea35a21472bc0cc0866dfca38a6bf1fe 
INFO[0000] deleted image: sha256:dc638cdfb3aa32b6ff16a84de36d866b2c9f1089da8b6f23b060f874d3e1e8ce 
INFO[0000] deleted image: sha256:dc7f9e2b4c8397b06f48205726bda048d21449a20d0e839251627f3edb14faa3 
INFO[0000] deleted image: sha256:dcaf7a67567f00e4f0663b0438e00dd0d05a0137c68fc39e60831c239822ca17 
INFO[0000] deleted image: sha256:dd7c0aaeb11d0017d1706e50c12855f7c387d0e59b876c29581991a44c3d051e 
INFO[0000] deleted image: sha256:e593337cadae930b7f4be0d92a86c05c57a96c53ce4069b073657e3f9dda0e5b 
INFO[0000] deleted image: sha256:e67e758229fe38ae187aa9e50f8f3bf3cb9007dfb62b5727a6a190a34dfcd8cf 
INFO[0000] deleted image: sha256:eaedff8cef1311ba93dae66b79b23d35a5f37e63790730b68a2515dc85fb5b1a 
INFO[0000] deleted image: sha256:ec7c64189a2fd01b24b044fea1840d441e9884a0df32c2e9d6982cfbbea1f814 
INFO[0000] deleted image: sha256:eccd18fa9b44f1903b17dcad0c83068ba61f7fc08f934607b1280598fcbce8fc 
INFO[0000] deleted image: sha256:eed36402c90c9094bfd34568761cf5033348ad8d3705882ed7f5e3b7c2b5fbde 
INFO[0000] deleted image: sha256:ef738a34a8651d11b2bace81c55c7e2187f786b484add6c83070884340074368 
INFO[0000] deleted image: sha256:f02701fffc833a063b74846316f0f0e50e637849d7f6e3c1566b3e2839275ebd 
INFO[0000] deleted image: sha256:f11a9e3d6b88dff1ea9347e31442a51e766d5964cccadf8ce8ea23bbddb94d57 
INFO[0000] deleted image: sha256:f270e17c3767a630afd8d3abf400229e3f3cedb4728fd0b6c884c6b0dd971c6a 
INFO[0000] deleted image: sha256:f2b9123eb037a2cea1ec73f9d27457fa44ace6581d5f5325c8de8e4a0b8361e2 
INFO[0000] deleted image: sha256:f3bedf03e95712d49e589fccadc371552baea982d05b616a2a7ffa9e95a80ad7 
INFO[0000] deleted image: sha256:f43b6d4e60aea7d9bd89f15c81a18278204898a40e43fefd8f2b5931e8ff0b17 
INFO[0000] deleted image: sha256:f59c592ea6d90ba2e6c236355083e204d52e13eb8bd39d90c0770f71b90e4dd8 
INFO[0000] deleted image: sha256:f8efc79d17d2e458c3e466f15eca4fc4f4a2ff4a15d5690388655084791725de 
INFO[0000] deleted image: sha256:f9389419e1aaabef0787d0df3c5f24870921c4c3a53ddaf847f42240b78bc43e 
INFO[0000] deleted image: sha256:f950c1f119ea8bf61a0e0231e0de9f3851e9bf46a1476e6fe0e60b7d3c5a6573 
INFO[0000] deleted image: sha256:fe0a933cb2d7e0625fa81da8c8c0e929c4c83ece25dee55983deef3c132c5b34 
INFO[0004] deleted image: sha256:ffb07efb3f1e042f8a46c36a2ad7a72fb4a14cf6817580b891b0303eeb2aaaf5 

===== [CLEAN] Tudo removido ✅ =====
  Cluster: releases Helm, namespaces production/staging/observability,
           PVCs, Secrets, Ingress e Ingress controller, ClusterRole/Binding,
           imagens do projeto e de terceiros, restantes recursos de todos os namespaces
           (kubectl delete all --all --all-namespaces, incluindo a rede Calico do kube-system),
           imagens sem uso (ctr images prune --all) e addons ativados (dns, hostpath-storage, metrics-server, ingress).
           O make run-stg / run-prd seguinte repõe a rede do cluster (Calico) automaticamente.
  Docker:  todos os contentores parados; imagens, volumes, redes e cache de build removidos
           (docker system prune -af --volumes, volume/network/builder prune).
  Local:   .venv, .certs, ficheiros kubeconfig-*.yaml, caches, *.db, port-forwards e a entrada no /etc/hosts.
  (O cluster microk8s continua instalado.)
daniel-almeida@daniel-ubuntu:~/Transferências/ProjetoFinal$ 