# Выполнено ДЗ № 9 - Сервисы централизованного логирования для компонентов Kubernetes и приложений

 - [x] Основное ДЗ
 - [ ] Задание со ⭐ - issue с дублирующимися полями уже пофиксено и в текушей версии приложения не воспроизводится
 - [ ] Задание сo ⭐ (audit logging) - не довел до конца
 - [ ] Задание сo ⭐ (host logging)

## В процессе сделано:

### Подготовка инфраструктуры

Использованы мои наработки из дипломного проекта по курсу **DevOps для эксплуатации и разработки**.

Кластер Kubernetes поднимается в облаке Yandex Cloud. Вся инфраструктура разворачивается по методолгии IaaC с использованием Terraform:
1. Административное облако **organization** для размещения административного фолдера **adm-folder** для ресурсов уровня организации (облака)
2. **adm-folder** в облаке **organization** для размещения объектного хранилища, на котором сохраняется Terraform state уровня 1 (организация и описание облаков для проектов)
3. Облако проекта **otus-kuber** для размещения административного фолдера **adm-folder** для ресурсов уровня проекта (фолдеры) и фолдеров окружений проекта
4. **adm-folder** в облаке **otus-kuber** для размещения объектного хранилища, на котором сохраняется Terraform state уровня 2 (облако проекта и описание фолдеров окружений проекта)
5. **dev-folder** в облаке **otus-kuber** для размещения объектного хранилища, на котором сохраняется Terraform state уровня 3 (фолдер Development окружения проекта и описание ресурсов этого фолдера)
6. **prod-folder** в облаке **otus-kuber** для размещения объектного хранилища, на котором сохраняется Terraform state уровня 3 (фолдер Production окружения проекта и описание ресурсов этого фолдера)
7. Ресурсы **Development** окружения проекта:
  - сеть и подсеть
  - сервисные аккаунты
  - группы безопасности
  - Managed Kubernetes cluster
  - зона и записи DNS
    
    В кластере Managed Kubernetes развернуты 2 нодгруппы с включенным автоскалированием нод:
    - default-pool - от 0 до 1
    - infra-pool - от 0 до 3
      
    В infra-pool Терраформом заданы node_taints:

    ```shell
    k8s_node_group_node_taints        = ["node-role=infra:NoSchedule"]
     ```
    
![Yandex.Cloud](/images/hw09-yandex-cloud.png)  

Подробнее по инфраструктурной части см. https://github.com/otus-kuber-2023-04/voitenkov_platform/blob/kubernetes-templating/infrastructure/README.md

## Решение Д/З № 9

### Установка HipsterShop

```shell
$ kubectl apply -f https://raw.githubusercontent.com/express42/otus-platform-snippets/master/Module-02/Logging/microservices-demo-without-resources.yaml -n microservices-demo
            
$ kubectl get nodes
NAME                        STATUS   ROLES    AGE   VERSION
cl15meagv87pu1svnhq5-axif   Ready    <none>   49m   v1.24.8

$ kubectl get pods -n microservices-demo -o wide
NAME                                     READY   STATUS             RESTARTS        AGE     IP             NODE                        NOMINATED NODE   READINESS GATES
adservice-58f8655b97-5kmrr               1/1     Running            0               9m19s   10.96.128.18   cl15meagv87pu1svnhq5-axif   <none>           <none>
cartservice-6f6b5b875d-l5bg4             1/1     Running            2 (8m8s ago)    9m20s   10.96.128.13   cl15meagv87pu1svnhq5-axif   <none>           <none>
checkoutservice-b5545dc95-6kdf7          1/1     Running            0               9m22s   10.96.128.9    cl15meagv87pu1svnhq5-axif   <none>           <none>
currencyservice-f7b9cc-jhktb             1/1     Running            0               9m20s   10.96.128.15   cl15meagv87pu1svnhq5-axif   <none>           <none>
emailservice-59954c6bff-g5df2            1/1     Running            0               9m22s   10.96.128.7    cl15meagv87pu1svnhq5-axif   <none>           <none>
frontend-75f46fcfb7-x7sbq                1/1     Running            0               9m21s   10.96.128.10   cl15meagv87pu1svnhq5-axif   <none>           <none>
loadgenerator-7d88bdbbf8-mxhw9           1/1     Running            4 (7m23s ago)   9m20s   10.96.128.14   cl15meagv87pu1svnhq5-axif   <none>           <none>
paymentservice-556f7b5695-wf5k8          1/1     Running            0               9m21s   10.96.128.11   cl15meagv87pu1svnhq5-axif   <none>           <none>
productcatalogservice-78854d86ff-lx5rb   1/1     Running            0               9m20s   10.96.128.12   cl15meagv87pu1svnhq5-axif   <none>           <none>
recommendationservice-b8f974fc-zfwzl     1/1     Running            0               9m21s   10.96.128.8    cl15meagv87pu1svnhq5-axif   <none>           <none>
redis-cart-745456dd9b-8c8sf              1/1     Running            0               9m19s   10.96.128.17   cl15meagv87pu1svnhq5-axif   <none>           <none>
shippingservice-7b5695bdb5-lsc42         1/1     Running            0               9m19s   10.96.128.16   cl15meagv87pu1svnhq5-axif   <none>           <none>
```
они все запустились на одной ноде

### Установка  Elasticsearch кластера

Подключаем mirror-репозиторий, так как репозиторий **elastic** заблокирован в нашей стране. 
Пуллим чарты, чтобы переписать в Values ссылки на докер репозитории, которые тоже заблокированы.

```shell
$ kubectl create ns observability
helm repo add elastic-mirror https://elastic.comcloud.xyz
helm pull elastic-mirror/elasticsearch --untar
$ helm upgrade --install elasticsearch elasticsearch --namespace observability --set image=elasticsearch --set imageTag=8.5.1
Release "elasticsearch" does not exist. Installing it now.
NAME: elasticsearch
LAST DEPLOYED: Fri Jun 16 00:30:38 2023
NAMESPACE: observability
STATUS: deployed
REVISION: 1
NOTES:
1. Watch all cluster members come up.
  $ kubectl get pods --namespace=observability -l app=elasticsearch-master -w
2. Retrieve elastic user's password.
  $ kubectl get secrets --namespace=observability elasticsearch-master-credentials -ojsonpath='{.data.password}' | base64 -d
3. Test cluster health using Helm test.
  $ helm --namespace=observability test elasticsearch
```

Видим, что Elasticsearch пытался запуститься на одной (все три реплики), но запустился только один. Это связано с параметром tolerations.
Нод-группа Infra-pool1 пока без нод.

```shell
$ kubectl get pods -n observability -o wide
NAME                       READY   STATUS    RESTARTS   AGE     IP             NODE                        NOMINATED NODE   READINESS GATES
elasticsearch-master-0     0/1     Running   0          4m37s   10.96.128.20   cl15meagv87pu1svnhq5-axif   <none>           <none>
elasticsearch-master-1     0/1     Pending   0          4m37s   <none>         <none>                      <none>           <none>
elasticsearch-master-2     0/1     Pending   0          4m37s   <none>         <none>                      <none>           <none>
elasticsearch-yvkne-test   0/1     Error     0          89s     10.96.128.21   cl15meagv87pu1svnhq5-axif   <none>           <none>

$ kubectl get nodes
NAME                        STATUS   ROLES    AGE    VERSION
cl15meagv87pu1svnhq5-axif   Ready    <none>   111m   v1.24.8
```

Создадим файл elasticsearch.values.yaml, где укажем, что мы можем ставить и на другие ноды.
Чтобы установить пул машин, на которых должен запускаться ElasticSearch, добавим еще настройку nodeSelector:

```shell
tolerations:
  - key: node-role
    operator: Equal
    value: infra
    effect: NoSchedule
nodeSelector:
  node-group: infra-pooll
```

```shell
helm upgrade --install elasticsearch elasticsearch --namespace observability -f elasticsearch.values.yaml

$ kubectl get pods -n observability -o wide -l chart=elasticsearch
NAME                     READY   STATUS    RESTARTS   AGE     IP            NODE                        NOMINATED NODE   READINESS GATES
elasticsearch-master-0   1/1     Running   0          2m35s   10.96.131.4   cl1oqhmjrhj4eneiiavf-eliv   <none>           <none>
elasticsearch-master-1   1/1     Running   0          2m35s   10.96.129.5   cl1oqhmjrhj4eneiiavf-unad   <none>           <none>
elasticsearch-master-2   1/1     Running   0          2m35s   10.96.130.5   cl1oqhmjrhj4eneiiavf-ecar   <none>           <none>

$ kubectl get nodes
NAME                        STATUS   ROLES    AGE     VERSION
cl15meagv87pu1svnhq5-axif   Ready    <none>   5d2h    v1.24.8
cl1oqhmjrhj4eneiiavf-ecar   Ready    <none>   106m    v1.24.8
cl1oqhmjrhj4eneiiavf-eliv   Ready    <none>   7m30s   v1.24.8
cl1oqhmjrhj4eneiiavf-unad   Ready    <none>   110m    v1.24.8
```

### Установка Cert-manager и Nginx Ingress Controller

```shell
$ helm repo add jetstack https://charts.jetstack.io
$ helm repo update
$ helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.12.0 --set installCRDs=true

$ helm upgrade --install ingress-nginx ingress-nginx --repo https://kubernetes.github.io/ingress-nginx -f nginx-ingress.values.yaml  --namespace ingress-nginx --create-namespace --atomic 

$ kubectl get pods -n ingress-nginx -o wide
NAME                                        READY   STATUS    RESTARTS   AGE   IP            NODE                        NOMINATED NODE   READINESS GATES
ingress-nginx-controller-6489c68749-5w49s   1/1     Running   0          10m   10.96.129.8   cl1oqhmjrhj4eneiiavf-unad   <none>           <none>
ingress-nginx-controller-6489c68749-hrqnl   1/1     Running   0          10m   10.96.131.7   cl1oqhmjrhj4eneiiavf-eliv   <none>           <none>
ingress-nginx-controller-6489c68749-trsxx   1/1     Running   0          10m   10.96.130.8   cl1oqhmjrhj4eneiiavf-ecar   <none>           <none>
```

### Установка Kibana

```shell
$ helm pull elastic-mirror/kibana --untar
$ helm upgrade --install kibana kibana --namespace observability -f kibana.values.yaml --atomic
NAME: kibana
LAST DEPLOYED: Wed Jun 21 23:26:27 2023
NAMESPACE: observability
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
1. Watch all containers come up.
  $ kubectl get pods --namespace=observability -l release=kibana -w
2. Retrieve the elastic user's password.
  $ kubectl get secrets --namespace=observability elasticsearch-master-credentials -ojsonpath='{.data.password}' | base64 -d
3. Retrieve the kibana service account token.
  $ kubectl get secrets --namespace=observability kibana-kibana-es-token -ojsonpath='{.data.token}' | base64 -d
```
![kibana](/images/hw10-kibana.png)

### Установка Fluent-bit

```shell
$ helm repo add fluent https://fluent.github.io/helm-charts
$ helm upgrade --install fluent-bit fluent/fluent-bit -n observability --atomic
```

**Fluent-bit** сконфигурирован на прием логов из кластера Kubernetes и на отправку их в Elasticsearch. Логи микросервисов Hipster-shop можно посмотреть в Kibana:
![Kubernetes logs](/images/hw10-kibana-logs2.png)

### Задание со ⭐

Описанная в методичке прблема с дубликатами полей не проявляется уже, так как давно исправлена.

### Мониторинг ElasticSearch

#### Устанавливаем Prometheus Elasticsearch Exporter:

```shell
$ helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
$ helm install elasticsearch-exporter stable/elasticsearch-exporter -f elasticsearch-exporter.values --namespace=observability --atomic
NAME: prometheus-elasticsearch-exporter
LAST DEPLOYED: Sat Jun 24 02:47:12 2023
NAMESPACE: observability
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace observability -l "app=prometheus-elasticsearch-exporter" -o jsonpath="{.items[0].metadata.name}")
  echo "Visit http://127.0.0.1:9108/metrics to use your application"
  kubectl port-forward $POD_NAME 9108:9108 --namespace observability
```

#### Устанавливаем Kube Prometheus Stack:

```shell
$ helm upgrade --install prometheus prometheus-community/kube-prometheus-stack -n observability -f prometheus-operator.values.yaml
Release "prometheus" does not exist. Installing it now.
NAME: prometheus
LAST DEPLOYED: Sat Jun 24 02:44:19 2023
NAMESPACE: observability
STATUS: deployed
REVISION: 1
NOTES:
kube-prometheus-stack has been installed. Check its status by running:
  kubectl --namespace observability get pods -l "release=prometheus"

Visit https://github.com/prometheus-operator/kube-prometheus for instructions on how to create & configure Alertmanager and Prometheus instances using the Operator.
```

#### Импортируем дашбоард (https://grafana.com/grafana/dashboards/4358) в Grafana:

![grafana](/images/hw10-grafana-elastic.png)

#### Выключаем одну ноду:

```shell
$ kubectl drain cl1oqhmjrhj4eneiiavf-ecar --ignore-daemonsets --delete-emptydir-data
node/cl1oqhmjrhj4eneiiavf-ecar cordoned
Warning: ignoring DaemonSet-managed Pods: kube-system/ip-masq-agent-4pjf7, kube-system/kube-proxy-b9k72, kube-system/npd-v0.8.0-8frqg, kube-system/yc-disk-csi-node-v2-tjpvn, observability/prometheus-prometheus-node-exporter-m494h
evicting pod observability/prometheus-kube-state-metrics-678b958c5-55hz7
evicting pod observability/alertmanager-prometheus-kube-prometheus-alertmanager-0
evicting pod observability/elasticsearch-master-0
evicting pod ingress-nginx/ingress-nginx-controller-6489c68749-trsxx
evicting pod observability/prometheus-kube-prometheus-operator-5d87d8765f-2zpnm
pod/prometheus-kube-state-metrics-678b958c5-55hz7 evicted
pod/alertmanager-prometheus-kube-prometheus-alertmanager-0 evicted
pod/prometheus-kube-prometheus-operator-5d87d8765f-2zpnm evicted
pod/elasticsearch-master-0 evicted
pod/ingress-nginx-controller-6489c68749-trsxx evicted
node/cl1oqhmjrhj4eneiiavf-ecar drained
```
![grafana](/images/hw10-grafana-elastic-drained.png)

#### Уроним еще одну ноду
```
kubectl drain cl1oqhmjrhj4eneiiavf-unad --ignore-daemonsets --delete-emptydir-data
node/cl1oqhmjrhj4eneiiavf-unad cordoned
Warning: ignoring DaemonSet-managed Pods: kube-system/ip-masq-agent-k95wf, kube-system/kube-proxy-shmbs, kube-system/npd-v0.8.0-l6cct, kube-system/yc-disk-csi-node-v2-2msp5, observability/prometheus-prometheus-node-exporter-vg7mq
evicting pod observability/prometheus-kube-prometheus-operator-5d87d8765f-gg77r
evicting pod observability/elasticsearch-master-1
evicting pod observability/kibana-kibana-799769b95c-2mm64
evicting pod ingress-nginx/ingress-nginx-controller-6489c68749-5w49s
error when evicting pods/"elasticsearch-master-1" -n "observability" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/kibana-kibana-799769b95c-2mm64 evicted
pod/prometheus-kube-prometheus-operator-5d87d8765f-gg77r evicted
evicting pod observability/elasticsearch-master-1
error when evicting pods/"elasticsearch-master-1" -n "observability" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
```

Удаляем второй под Elasticsearch руками и тем самым разваливаем кластер Elasticsearch.
Но так как включен автоскейлинг, то автоматически запускается новая нода нодгруппы:

```shell
$ kubectl delete pod elasticsearch-master-1 -n observability
pod "elasticsearch-master-1" deleted

$ kubectl get po -n observability -l chart=elasticsearch
NAME                                                     READY   STATUS    RESTARTS      AGE
elasticsearch-master-0                                   0/1     Pending   0             8m20s
elasticsearch-master-1                                   0/1     Pending   0             78s
elasticsearch-master-2                                   1/1     Running   0             137m

$ kubectl get nodes
NAME                        STATUS                     ROLES    AGE     VERSION
cl15meagv87pu1svnhq5-axif   Ready                      <none>   10d     v1.24.8
cl1oqhmjrhj4eneiiavf-eliv   Ready                      <none>   4d22h   v1.24.8
cl1oqhmjrhj4eneiiavf-ixos   Ready                      <none>   3m6s    v1.24.8
cl1oqhmjrhj4eneiiavf-unad   Ready,SchedulingDisabled   <none>   4d23h   v1.24.8
```
В логах Elasticsearch видим сообщение: "master not discovered or elected yet, an election requires at least 2 nodes with ids from..."

Восстанавливаем работоспособность кластера:

```shell
$ kubectl uncordon cl1oqhmjrhj4eneiiavf-unad
node/cl1oqhmjrhj4eneiiavf-unad uncordoned
$ kubectl get nodes
NAME                        STATUS   ROLES    AGE     VERSION
cl15meagv87pu1svnhq5-axif   Ready    <none>   10d     v1.24.8
cl1oqhmjrhj4eneiiavf-eliv   Ready    <none>   4d22h   v1.24.8
cl1oqhmjrhj4eneiiavf-ixos   Ready    <none>   7m59s   v1.24.8
cl1oqhmjrhj4eneiiavf-unad   Ready    <none>   5d      v1.24.8

$ k get po -n observability -l chart=elasticsearch
NAME                                                     READY   STATUS    RESTARTS      AGE
elasticsearch-master-0                                   0/1     Running   0             20m
elasticsearch-master-1                                   1/1     Running   0             13m
elasticsearch-master-2                                   1/1     Running   0             149m
```

![grafana](/images/hw10-grafana-elastic-recovered.png)

### Логи nginx-ingress

Чтобы появились логи поменяем fluentbit.values.yaml и nginx-ingress.values.yaml
Получим:

![kibana](/images/hw10-kibana-nginx-index.png)

Создадим дэшбоард
(kubernetes.labels.app : nginx-ingress and status < 500 and status >= 400)

![kibana](/images/hw10-kibana-nginx.png)

### Loki

Установка:

```shell
$ helm repo add grafana https://grafana.github.io/helm-charts
$ helm repo update
$ helm upgrade --install loki grafana/loki-stack --namespace=observability -f loki.values.yaml --atomic
Release "loki" does not exist. Installing it now.
NAME: loki
LAST DEPLOYED: Mon Jun 26 18:04:04 2023
NAMESPACE: observability
STATUS: deployed
REVISION: 1
NOTES:
The Loki stack has been deployed to your cluster. Loki can now be added as a datasource in Grafana.

See http://docs.grafana.org/features/datasources/loki/ for more detail.

helm upgrade --install prometheus prometheus-community/kube-prometheus-stack -n observability -f kube-prometheus-stack.values.yaml --atomic
```

Откроем Grafana и  посмотрим логи от Loki

![grafana-loki](/images/hw10-loki-explore.png)

Cоздадим свой дэшборд для Nginx Ingress:

![grafana-loki](/images/hw10-grafana-nginx.png)

### Задание сo ⭐ (audit logging)

Используем решение **Yandex.Cloud Security Solution Library** по сбору аудит-логов с кластера Kubernetes и отправки их в Elasticsearch (ELK):  
https://github.com/yandex-cloud/yc-solution-library-for-security/blob/master/auditlogs/export-auditlogs-to-ELK_k8s/README.md  
Решение развернул, логи экспортируются, но оно заточено на Yandex Managed Service for Elasticsearch и в развернутый чартами в кластере Elasticsearch не попадают. Требуется переработка данного решения в части интеграции с собственным (не в виде Managed Service) Elasticsearch.

Пример сгенерированного для FALCO события безопасности, экспортированного в **Yandex Cloud Logging**:
![cloud-logging](/images/hw10-cloud-logging.png)

### Задание сo ⭐ (host logging)

Не делал.

## Как проверить работоспособность:
 - см. выше
## PR checklist:
 - [x] Выставлен label с темой домашнего задания
