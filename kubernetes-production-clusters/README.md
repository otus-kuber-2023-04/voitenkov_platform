# Выполнено ДЗ № 14 - Подходы к развертыванию и обновлению production-grade кластера

 - [x] Основное ДЗ
 - [X] Задание со ⭐ Выполните установку кластера с 3 master-нодами и 2 worker-нодами

## В процессе сделано:

### Подготовка инфраструктуры

Использованы мои наработки из дипломного проекта по курсу **DevOps для эксплуатации и разработки**.

Инфраструктура поднимается в облаке Yandex Cloud по методолгии IaaC с использованием Terraform:
1. Административное облако **organization** для размещения административного фолдера **adm-folder** для ресурсов уровня организации (облака)
2. **adm-folder** в облаке **organization** для размещения объектного хранилища, на котором сохраняется Terraform state уровня 1 (организация и описание облаков для проектов)
3. Облако проекта **otus-kuber** для размещения административного фолдера **adm-folder** для ресурсов уровня проекта (фолдеры) и фолдеров окружений проекта
4. **adm-folder** в облаке **otus-kuber** для размещения объектного хранилища, на котором сохраняется Terraform state уровня 2 (облако проекта и описание фолдеров окружений проекта)
5. **stage-folder** в облаке **otus-kuber** для размещения объектного хранилища, на котором сохраняется Terraform state уровня 3 (фолдер Stage окружения проекта и описание ресурсов этого фолдера)
6. **test-folder** в облаке **otus-kuber** для размещения объектного хранилища, на котором сохраняется Terraform state уровня 3 (фолдер Test окружения проекта и описание ресурсов этого фолдера)
7. Ресурсы **Stage** окружения проекта для основного задания:
  - сеть и подсеть
  - сервисные аккаунты
  - группы безопасности
  - виртуальные машины (1 для управления развертыванием кластера и 3 для кластера Kubernetes)
7. Ресурсы **Test** окружения проекта для задания со ⭐:
  - сеть и подсеть
  - сервисные аккаунты
  - группы безопасности
  - виртуальные машины (1 для управления развертыванием кластера и 5 для кластера Kubernetes)
     
![Yandex.Cloud](/images/hw09-yandex-cloud.png)  

Подробнее по инфраструктурной части см. https://github.com/otus-kuber-2023-04/voitenkov_platform/blob/kubernetes-templating/infrastructure/README.md

## Решение Д/З № 14

В этом задании через kubeadm поднимаем самый новый кластер версии 1.28.0 с обновлением до версии 1.28.1.

### Создание кластера Kubernetes v1.28.0 с использованием kubeadm

Для подготовки машин я вставил все необходимые команды в свой Userdata файл для Cloud-Init, который используется при разворачивании ВМ Terraform'ом:
- Для подготовки ВМ к установке кластера Kubernetes:  
https://github.com/otus-kuber-2023-04/voitenkov_platform/blob/kubernetes-production-clusters/infrastructure/templates/ubuntu-k8s.yml.tftpl
- Для подготовки ВМ, управляющей развертыванием кластера:  
https://github.com/otus-kuber-2023-04/voitenkov_platform/blob/kubernetes-production-clusters/infrastructure/templates/ubuntu-devops.yml.tftpl

Создадим настроим мастер ноду при помощи kubeadm, для этого на ней выполним:
```shell
master1@master1:~$ sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --upload-certs --kubernetes-version=v1.28.0 --ignore-preflight-errors=Mem

[init] Using Kubernetes version: v1.28.0
[preflight] Running pre-flight checks
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
W0910 17:19:29.849513   15737 checks.go:835] detected that the sandbox image "registry.k8s.io/pause:3.6" of the container runtime is inconsistent with that used by kubeadm. It is recommended that using "registry.k8s.io/pause:3.9" as the CRI sandbox image.
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Generating "ca" certificate and key
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local master1] and IPs [10.96.0.1 192.168.10.30]
[certs] Generating "apiserver-kubelet-client" certificate and key
[certs] Generating "front-proxy-ca" certificate and key
[certs] Generating "front-proxy-client" certificate and key
[certs] Generating "etcd/ca" certificate and key
[certs] Generating "etcd/server" certificate and key
[certs] etcd/server serving cert is signed for DNS names [localhost master1] and IPs [192.168.10.30 127.0.0.1 ::1]
[certs] Generating "etcd/peer" certificate and key
[certs] etcd/peer serving cert is signed for DNS names [localhost master1] and IPs [192.168.10.30 127.0.0.1 ::1]
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "apiserver-etcd-client" certificate and key
[certs] Generating "sa" key and public key
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
[kubeconfig] Writing "admin.conf" kubeconfig file
[kubeconfig] Writing "kubelet.conf" kubeconfig file
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
[kubeconfig] Writing "scheduler.conf" kubeconfig file
[etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
[control-plane] Creating static Pod manifest for "kube-scheduler"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Starting the kubelet
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests". This can take up to 4m0s
[apiclient] All control plane components are healthy after 8.002981 seconds
[upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config" in namespace kube-system with the configuration for the kubelets in the cluster
[upload-certs] Storing the certificates in Secret "kubeadm-certs" in the "kube-system" Namespace
[upload-certs] Using certificate key:
abf7555303cb49597897e59ed86edc4cb58d7209063a336a956d281fb97aa835
[mark-control-plane] Marking the node master1 as control-plane by adding the labels: [node-role.kubernetes.io/control-plane node.kubernetes.io/exclude-from-external-load-balancers]
[mark-control-plane] Marking the node master1 as control-plane by adding the taints [node-role.kubernetes.io/control-plane:NoSchedule]
[bootstrap-token] Using token: l5wm5d.9oohibiae9cqo8d6
[bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
[bootstrap-token] Configured RBAC rules to allow Node Bootstrap tokens to get nodes
[bootstrap-token] Configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstrap-token] Configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstrap-token] Configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstrap-token] Creating the "cluster-info" ConfigMap in the "kube-public" namespace
[kubelet-finalize] Updating "/etc/kubernetes/kubelet.conf" to point to a rotatable kubelet client certificate and key
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes control-plane has initialized successfully!
```
Устанавливаем Flannel CNI:
`$ kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml`

Мастер-нода перешла в стату Ready:
```shell
$ kubectl get nodes
NAME      STATUS   ROLES           AGE   VERSION
master1   Ready    control-plane   24m   v1.28.0
```
Вводим в кластер второй мастер и три воркера:
```shell
$ kubeadm join 192.168.10.30:6443 --token l5wm5d.9oohibiae9cqo8d6 \
        --discovery-token-ca-cert-hash sha256:a00cb6bca8d611e74bcfb4ca8b687de97fb4f233cb0193656684fbeb8d050757
$ kubectl get nodes
NAME      STATUS     ROLES           AGE    VERSION
master1   Ready      control-plane   84m    v1.28.0
worker1   Ready      <none>          4m4s   v1.28.0
worker2   Ready      <none>          101s   v1.28.0
worker3   NotReady   <none>          6s     v1.28.0
```

Применяем манифест с тестовым Deployment Nginx:
```shell
$ kubectl apply -f deployment.yaml

kubectl get all -n default
NAME                                   READY   STATUS    RESTARTS   AGE
pod/nginx-deployment-f7f5c78c5-bwpzg   1/1     Running   0          41s
pod/nginx-deployment-f7f5c78c5-g5wzb   1/1     Running   0          41s
pod/nginx-deployment-f7f5c78c5-mgjnk   1/1     Running   0          41s
pod/nginx-deployment-f7f5c78c5-wrqxf   1/1     Running   0          41s

NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   95m

NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx-deployment   4/4     4            4           41s

NAME                                         DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-deployment-f7f5c78c5   4         4         4       41s
```
### Обновление кластера Kubernetes до версии v1.28.1 с использованием kubeadm

Я не прочитал заранее методичку и не догадался сначала установить предыдущую минорную версию, поэтому обновлялся до патч-релиза 1.28.1:
```shell
sudo apt update
sudo apt-cache madison kubeadm
sudo apt-mark unhold kubeadm && sudo apt-get update && sudo apt-get install -y kubeadm=1.28.1-00 && sudo apt-mark hold kubeadm
sudo kubeadm upgrade plan
sudo kubeadm upgrade apply v1.28.1

kubectl version
Client Version: v1.28.0
Kustomize Version: v5.0.4-0.20230601165947-6ce0bf390ce3
Server Version: v1.28.1

master1@master1:~$ kubeadm version
kubeadm version: &version.Info{Major:"1", Minor:"28", GitVersion:"v1.28.1", GitCommit:"8dc49c4b984b897d423aab4971090e1879eb4f23", GitTreeState:"clean", BuildDate:"2023-08-24T11:21:51Z", GoVersion:"go1.20.7", Compiler:"gc", Platform:"linux/amd64"}

master1@master1:~$ kubectl describe pod kube-apiserver-master1 -n kube-system
Name:                 kube-apiserver-master1
Namespace:            kube-system
Priority:             2000001000
Priority Class Name:  system-node-critical
Node:                 master1/192.168.10.30
Start Time:           Sun, 10 Sep 2023 19:03:04 +0000
Labels:               component=kube-apiserver
                      tier=control-plane
Annotations:          kubeadm.kubernetes.io/kube-apiserver.advertise-address.endpoint: 192.168.10.30:6443
                      kubernetes.io/config.hash: 4d384e09e5c76d5f79ae2caac4287a5f
                      kubernetes.io/config.mirror: 4d384e09e5c76d5f79ae2caac4287a5f
                      kubernetes.io/config.seen: 2023-09-10T19:04:56.557049225Z
                      kubernetes.io/config.source: file
Status:               Running
SeccompProfile:       RuntimeDefault
IP:                   192.168.10.30
IPs:
  IP:           192.168.10.30
Controlled By:  Node/master1
Containers:
  kube-apiserver:
    Container ID:  containerd://517b44a6252bff7e6b876c7952d482aa5e2a617decd8aa34a7793f2479bdbd4e
    Image:         registry.k8s.io/kube-apiserver:v1.28.1
```
Обновляю второй мастер и воркеры:
```shell
kubectl drain master1 --ignore-daemonsets
sudo apt-mark unhold kubeadm && sudo apt-get update && sudo apt-get install -y kubelet=1.28.1-00 kubelet=1.28.1-00 && sudo apt-mark hold kubelet kubectl
sudo systemctl daemon-reload
kubectl uncordon master1

kubectl drain worker1 --ignore-daemonsets
node/worker1 already cordoned
Warning: ignoring DaemonSet-managed Pods: kube-flannel/kube-flannel-ds-h9m86, kube-system/kube-proxy-vlxtl
evicting pod default/nginx-deployment-f7f5c78c5-mgjnk
evicting pod default/nginx-deployment-f7f5c78c5-bwpzg
pod/nginx-deployment-f7f5c78c5-bwpzg evicted
pod/nginx-deployment-f7f5c78c5-mgjnk evicted
node/worker1 drained

sudo apt-mark unhold kubeadm && sudo apt-get update && sudo apt-get install -y kubeadm=1.28.1-00 && sudo apt-mark hold kubeadm
sudo kubeadm upgrade node
sudo apt-mark unhold kubeadm && sudo apt-get update && sudo apt-get install -y kubelet=1.28.1-00 kubelet=1.28.1-00 && sudo apt-mark hold kubelet kubectl
```

### Автоматическое развертывание кластеров

Выполняю сразу задание со ⭐ Выполните установку кластера с 3 master-нодами и 2 worker-нодами.

Для подготовки машин я вставил все необходимые команды в свой Userdata файл для Cloud-Init, который используется при разворачивании ВМ Terraform'ом:
- Для подготовки ВМ к установке кластера Kubernetes:  
[https://github.com/otus-kuber-2023-04/voitenkov_platform/blob/infrastructure/templates/ubuntu-k8s-kubespray.yml.tftpl](https://github.com/otus-kuber-2023-04/voitenkov_platform/blob/kubernetes-production-clusters/infrastructure/templates/ubuntu-k8s-kubespray.yml.tftpl)
- И добавил команды установки Ansible + Kubespray с зависимостями в Bootstrap ВМ:  
[https://github.com/otus-kuber-2023-04/voitenkov_platform/blob/infrastructure/templates/ubuntu-k8s-bootstrap.yml.tftpl](https://github.com/otus-kuber-2023-04/voitenkov_platform/blob/kubernetes-production-clusters/infrastructure/templates/ubuntu-k8s-bootstrap.yml.tftpl)

Использую Kubespray, все настройки дефолтные, за исключением того, что включил Flannel CNI.
Конфигурация узлов:  
master1 - control plane, etcd  
master2 - control plane, etcd  
master3 - etcd  
worker1 - node  
worker2 - node

Файл инвентаризации [https://github.com/otus-kuber-2023-04/voitenkov_platform/blob/kubernetes-production-clusters/inventory.ini. 
](https://github.com/otus-kuber-2023-04/voitenkov_platform/blob/kubernetes-production-clusters/kubernetes-production-clusters/inventory.ini)
`ansible-playbook -i inventory/mycluster/inventory.ini --become --become-user=root --user=ansible cluster.yaml`

Время установки - 20 минут. Результаты:
![Kubespray](/images/hw14-kubespray.png)  
```shell
ansible@master1:~$ kubectl get nodes -o wide
NAME      STATUS   ROLES           AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
master1   Ready    control-plane   18m   v1.27.5   192.168.10.24   <none>        Ubuntu 20.04.6 LTS   5.4.0-159-generic   containerd://1.7.5
master2   Ready    control-plane   17m   v1.27.5   192.168.10.37   <none>        Ubuntu 20.04.6 LTS   5.4.0-159-generic   containerd://1.7.5
worker1   Ready    <none>          17m   v1.27.5   192.168.10.18   <none>        Ubuntu 20.04.6 LTS   5.4.0-159-generic   containerd://1.7.5
worker2   Ready    <none>          17m   v1.27.5   192.168.10.10   <none>        Ubuntu 20.04.6 LTS   5.4.0-159-generic   containerd://1.7.5
ansible@master1:~$ kubectl get all -A
NAMESPACE     NAME                                  READY   STATUS    RESTARTS   AGE
kube-system   pod/coredns-5c469774b8-bw9bx          1/1     Running   0          12m
kube-system   pod/coredns-5c469774b8-d25t7          1/1     Running   0          12m
kube-system   pod/dns-autoscaler-f455cf558-c6p5h    1/1     Running   0          12m
kube-system   pod/kube-apiserver-master1            1/1     Running   1          14m
kube-system   pod/kube-apiserver-master2            1/1     Running   1          14m
kube-system   pod/kube-controller-manager-master1   1/1     Running   2          14m
kube-system   pod/kube-controller-manager-master2   1/1     Running   2          14m
kube-system   pod/kube-flannel-6j72p                1/1     Running   0          13m
kube-system   pod/kube-flannel-6mxz7                1/1     Running   0          13m
kube-system   pod/kube-flannel-6zskq                1/1     Running   0          13m
kube-system   pod/kube-flannel-tk7vg                1/1     Running   0          13m
kube-system   pod/kube-proxy-86jms                  1/1     Running   0          13m
kube-system   pod/kube-proxy-d8r2v                  1/1     Running   0          13m
kube-system   pod/kube-proxy-dctj6                  1/1     Running   0          13m
kube-system   pod/kube-proxy-xp8kg                  1/1     Running   0          13m
kube-system   pod/kube-scheduler-master1            1/1     Running   1          14m
kube-system   pod/kube-scheduler-master2            1/1     Running   1          14m
kube-system   pod/nginx-proxy-worker1               1/1     Running   0          13m
kube-system   pod/nginx-proxy-worker2               1/1     Running   0          13m
kube-system   pod/nodelocaldns-27mq8                1/1     Running   0          12m
kube-system   pod/nodelocaldns-7tq5q                1/1     Running   0          12m
kube-system   pod/nodelocaldns-cvhqg                1/1     Running   0          12m
kube-system   pod/nodelocaldns-grl5t                1/1     Running   0          12m

NAMESPACE     NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE
default       service/kubernetes   ClusterIP   10.233.0.1   <none>        443/TCP                  14m
kube-system   service/coredns      ClusterIP   10.233.0.3   <none>        53/UDP,53/TCP,9153/TCP   12m

NAMESPACE     NAME                                     DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
kube-system   daemonset.apps/kube-flannel              4         4         4       4            4           <none>                   13m
kube-system   daemonset.apps/kube-flannel-ds-arm       0         0         0       0            0           <none>                   13m
kube-system   daemonset.apps/kube-flannel-ds-arm64     0         0         0       0            0           <none>                   13m
kube-system   daemonset.apps/kube-flannel-ds-ppc64le   0         0         0       0            0           <none>                   13m
kube-system   daemonset.apps/kube-flannel-ds-s390x     0         0         0       0            0           <none>                   13m
kube-system   daemonset.apps/kube-proxy                4         4         4       4            4           kubernetes.io/os=linux   14m
kube-system   daemonset.apps/nodelocaldns              4         4         4       4            4           kubernetes.io/os=linux   12m

NAMESPACE     NAME                             READY   UP-TO-DATE   AVAILABLE   AGE
kube-system   deployment.apps/coredns          2/2     2            2           12m
kube-system   deployment.apps/dns-autoscaler   1/1     1            1           12m

NAMESPACE     NAME                                       DESIRED   CURRENT   READY   AGE
kube-system   replicaset.apps/coredns-5c469774b8         2         2         2       12m
kube-system   replicaset.apps/dns-autoscaler-f455cf558   1         1         1       12m
```
etcd развернут на 3 узлах и здоров:
```shell
etcdctl --endpoints 192.168.10.24:2379,192.168.10.37:2379,192.168.10.11:2379 --cacert=/etc/ssl/etcd/ssl/ca.pem --cert=/etc/ssl/etcd/ssl/node-master1.pem --key=/etc/ssl/etcd/ssl/node-master1-key.pem endpoint health
192.168.10.24:2379 is healthy: successfully committed proposal: took = 14.414868ms
192.168.10.11:2379 is healthy: successfully committed proposal: took = 14.378384ms
192.168.10.37:2379 is healthy: successfully committed proposal: took = 15.424987ms
```

## Как проверить работоспособность:
 - см. выше
## PR checklist:
 - [x] Выставлен label с темой домашнего задания
