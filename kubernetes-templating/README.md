# Выполнено ДЗ № 9

 - [x] Основное ДЗ
 - [ ] Задание со ⭐ (chartmuseum)
 - [x] Задание сo ⭐ (helmfile)
 - [ ] Задание сo ⭐ (community charts)
 - [ ] Необязательное задание (helm secrets)
 - [ ] Задание сo ⭐ (jsonnet другие решения)

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

![Yandex.Cloud](/images/hw09-yandex-cloud.png)  

Подробнее по инфраструктурной части см. https://github.com/otus-kuber-2023-04/voitenkov_platform/blob/kubernetes-templating/infrastructure/README.md

## Решение Д/З № 9

### Устанавливаем готовые Helm charts. Будем работать со следующими сервисами:

#### Nginx Ingress

Cервис, обеспечивающий доступ к публичным ресурсам кластера 
```shell
$ helm upgrade --install ingress-nginx ingress-nginx   --repo https://kubernetes.github.io/ingress-nginx   --namespace ingress-nginx --create-namespace --atomic

Release "ingress-nginx" has been upgraded. Happy Helming!
NAME: ingress-nginx
LAST DEPLOYED: Sun Jun 11 16:25:28 2023
NAMESPACE: ingress-nginx
STATUS: deployed
REVISION: 2
TEST SUITE: None
NOTES:
The ingress-nginx controller has been installed.
It may take a few minutes for the LoadBalancer IP to be available.
You can watch the status by running 'kubectl --namespace ingress-nginx get services -o wide -w ingress-nginx-controller'

$ helm list -n ingress-nginx
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
ingress-nginx   ingress-nginx   2               2023-06-11 16:25:28.492660353 +0200 EET deployed        ingress-nginx-4.7.0     1.8.0
```
#### Cert Manager

Cервис, позволяющий динамически генерировать Let's Encrypt сертификаты для ingress ресурсов.

Задеплоил чарт с CRD.
```shell
$ helm repo add jetstack https://charts.jetstack.io
$ helm repo update
$ kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.0/cert-manager.crds.yaml
$ kubectl label namespace cert-manager certmanager.k8s.io/disable-validation="true" 
$ helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.12.0 --set installCRDs=true

NAME: cert-manager
LAST DEPLOYED: Sun Jun 11 16:42:22 2023
NAMESPACE: cert-manager
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
cert-manager v1.12.0 has been deployed successfully!
```
Настроил CR для cert-manager по инструкции https://cert-manager.io/docs/tutorials/acme/nginx-ingress/ 
В документации описывают ClusterIssues и Issues. Создаем
```shell
$ kubectl apply -f cert-manager
```

#### Chart Museum

Cпециализированный репозиторий для хранения helm charts.

Узнаем External Ip nginx-ingress
```shell
$ kubectl get svc -A
NAMESPACE       NAME                                 TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                      AGE
cert-manager    cert-manager                         ClusterIP      10.112.162.72    <none>          9402/TCP                     5h23m
cert-manager    cert-manager-webhook                 ClusterIP      10.112.180.53    <none>          443/TCP                      5h23m
default         kubernetes                           ClusterIP      10.112.128.1     <none>          443/TCP                      11h
ingress-nginx   ingress-nginx-controller             LoadBalancer   10.112.252.18    62.84.116.141   80:31931/TCP,443:32269/TCP   5h40m
ingress-nginx   ingress-nginx-controller-admission   ClusterIP      10.112.219.240   <none>          443/TCP                      5h40m
kube-system     kube-dns                             ClusterIP      10.112.128.2     <none>          53/UDP,53/TCP,9153/TCP       11h
kube-system     metrics-server                       ClusterIP      10.112.214.95    <none>          443/TCP                      11h
```

наш ip - 62.84.116.141. Изменяем переменную ресурса Terraform:
```shell
external_ip1 = "62.84.116.141"

resource "yandex_dns_recordset" "r1-dns-rs-otus-kuber-dev" {
  zone_id = yandex_dns_zone.z1-dns-zone-otus-kuber.id
  name    = "*.${var.subdomain1_1}.${var.domain1}."
  type    = "A"
  ttl     = 600
  data    = ["${var.external_ip1}"]

  depends_on = [yandex_dns_zone.z1-dns-zone-otus-kuber]
}
```
**Terraform apply** - в облаке в записи DNS *.k8s-dev.voytenkov.ru прописывается актуальный IP адрес, соответствующий нашему Nginx Ingress.
Имена DNS в поддомене *.k8s-dev.voytenkov.ru будут использоваться в настройках Ingress нашего кластера.

Файл values.yaml включает в себя:
- Создание ingress ресурса с корректным hosts.name (должен использоваться nginx-ingress)
- Автоматическую генерацию Let's Encrypt сертификата

```shell
$ kubectl create ns chartmuseum
$ helm repo add chartmuseum https://chartmuseum.github.io/charts
$ helm upgrade --install chartmuseum chartmuseum/chartmuseum --wait --atomic --namespace=chartmuseum -f kubernetes-templating/chartmuseum/values.yaml

Release "chartmuseum" does not exist. Installing it now.
NAME: chartmuseum
LAST DEPLOYED: Sun Jun 11 22:29:04 2023
NAMESPACE: chartmuseum
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
** Please be patient while the chart is being deployed **

Get the ChartMuseum URL by running:

  export POD_NAME=$(kubectl get pods --namespace chartmuseum -l "app=chartmuseum" -l "release=chartmuseum" -o jsonpath="{.items[0].metadata.name}")
  echo http://127.0.0.1:8080/
  kubectl port-forward $POD_NAME 8080:8080 --namespace chartmuseum

$ kubectl get secrets -n chartmuseum
NAME                                TYPE                 DATA   AGE
chartmuseum                         Opaque               0      17h
chartmuseum.k8s-dev.voytenkov.ru    kubernetes.io/tls    2      29s
sh.helm.release.v1.chartmuseum.v1   helm.sh/release.v1   1      17h

$ kubectl get ingress -n chartmuseum
NAME          CLASS    HOSTS                              ADDRESS         PORTS     AGE
chartmuseum   <none>   chartmuseum.k8s-dev.voytenkov.ru   62.84.116.141   80, 443   17h

$ helm ls -n chartmuseum
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
chartmuseum     chartmuseum     1               2023-06-11 22:29:04.860949766 +0200 EET deployed        chartmuseum-3.9.3       0.15.0
```
Критерий успешности установки: 
- Chartmuseum доступен по URL https://chartmuseum.k8s-dev.voytenkov.ru
- Сертификат для данного URL валиден

![chartmuseum](/images/hw09-chartmuseum.png)  

#### Задание со ⭐ (chartmuseum)
 
Не выполнено пока.

#### Harbor

- [harbor](https://github.com/goharbor/harbor-helm) хранилище артефактов общего назначения (Docker Registry), поддерживающее helm charts

Файл values.yaml включает в себя:
- Создание ingress ресурса с корректным hosts.name (должен использоваться nginx-ingress)
- Автоматическую генерацию Let's Encrypt сертификата

```shell
$ helm repo add harbor https://helm.goharbor.io
$ kubectl create ns harbor
$ helm upgrade --install harbor harbor/harbor --version 1.12.2  --wait --atomic --namespace=harbor -f kubernetes-templating/harbor/values.yaml
Release "harbor" does not exist. Installing it now.
NAME: harbor
LAST DEPLOYED: Mon Jun 12 17:00:06 2023
NAMESPACE: harbor
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Please wait for several minutes for Harbor deployment to complete.
Then you should be able to visit the Harbor portal at https://harbor.k8s-dev.voytenkov.ru
For more details, please visit https://github.com/goharbor/harbor
```

Критерий успешности установки: 
- Harbor доступен по URL https://harbor.k8s-dev.voytenkov.ru
- Сертификат для данного URL валиден
- 
![chartmuseum](/images/hw09-harbor.png)  

### Задание сo ⭐ (helmfile)
 
Выполнено, см. kubernetes-templating/helmfile/helmfile.yaml

### Создаем свой helm chart

#### Типичная жизненная ситуация:
- У вас есть приложение, которое готово к запуску в Kubernetes
- У вас есть манифесты для этого приложения, но вам надо запускать его на разных окружениях с разными параметрами
#### Возможные варианты решения:
- Написать разные манифесты для разных окружений
- Использовать "костыли" - sed, envsubst, etc...
- Использовать полноценное решение для шаблонизации (helm, etc...)

#### Мы рассмотрим третий вариант. Возьмем готовые манифесты и подготовим их к релизу на разные окружения.
Использовать будем демо-приложение [hipster-shop](https://github.com/GoogleCloudPlatform/microservices-demo), представляющее собой типичный набор микросервисов.

Стандартными средствами helm инициализируйте структуру директории с содержимым будущего helm chart
```
helm create kubernetes-templating/hipster-shop
```
Мы будем создавать chart для приложения с нуля, поэтому удалите values.yaml и содержимое templates. После этого перенесите файл all-hipster-shop.yaml в директорию templates.

В целом, helm chart уже готов, вы можете попробовать установить его:
```
kubectl create ns hipster-shop
helm upgrade --install hipster-shop kubernetes-templating/hipster-shop --namespace hipster-shop
```

Сейчас наш helm chart hipster-shop совсем не похож на настоящий. При этом, все микросервисы устанавливаются из одного файла all-hipstershop.yaml

Давайте исправим это и первым делом займемся микросервисом frontend. Скорее всего он разрабатывается отдельной командой, а исходный код хранится в отдельном репозитории.

Создадим заготовку:
```
helm create kubernetes-templating/frontend
```
Аналогично чарту hipster-shop удалите файл values.yaml и файлы в директории templates, создаваемые по умолчанию. 
Выделим из файла all-hipster-shop.yaml манифесты для установки микросервиса frontend. В директории templates чарта frontend создайте файлы: 
- deployment.yaml, service.yaml, ingress.yaml

После того, как вынесете описание deployment и service для frontend из файла all-hipster-shop.yaml переустановите chart hipster-shop и проверьте, что доступ к UI пропал и таких ресурсов больше нет.

Установите chart frontend в namespace hipster-shop и проверьте что доступ к UI вновь появился:
```
helm upgrade --install frontend kubernetes-templating/frontend --namespace hipster-shop
```
![chartmuseum](/images/hw09-hipster.png)  

#### Пришло время минимально шаблонизировать наш chart frontend
- выносим данные в переменную (смотри файл values.yaml)

Теперь наш frontend стал немного похож на настоящий helm chart. Не стоит забывать, что он все еще является частью одного большого микросервисного приложения hipster-shop. Поэтому было бы неплохо включить его в зависимости этого
приложения.

Для начала, удалите release frontend из кластера:
```
helm list -a -A
helm delete frontend -n hipster-shop
```

В Helm 3 список зависимостей рекомендуют объявлять в файле Chart.yaml

Добавьте chart frontend как зависимость
```
dependencies:
  - name: frontend
    version: 0.1.0
    repository: "file://../frontend" - ссылается на /frontend
```
Обновим зависимости:
```
helm dep update kubernetes-templating/hipster-shop
```
В директории kubernetes-templating/hipster-shop/charts появился архив frontend-0.1.0.tgz содержащий chart frontend определенной версии и добавленный в chart hipster-shop как зависимость. Обновите release hipster-shop и убедитесь, что ресурсы frontend вновь созданы.
```
helm upgrade --install hipster-shop kubernetes-templating/hipster-shop --namespace hipster-shop
```
### Таким образом мы можем микросервисное приложение выносить в отдельную разработку и добавлять при необходмости

Осталось понять, как из CI-системы мы можем менять параметры helm chart, описанные в values.yaml. Для этого существует специальный ключ --set. Изменим NodePort для frontend в release, не меняя его в самом chart:
```
helm upgrade --install hipster-shop kubernetes-templating/hipster-shop --namespace
hipster-shop --set frontend.service.NodePort=31234
```

### Задание сo ⭐ (community charts)

Не выполнено пока.

### Необязательное задание (helm secrets)

Не выполнено пока.

### Создание репозитория Harbor

#### Создаем скрипт скрипт repo.sh 

Создаем и выполняем скрипт repo.sh
```shell
#!/bin/bash
helm3 repo add templating https://harbor.k8s-dev.voytenkov.ru/library && helm3 repo update
```

#### Загружаем пакеты в Harbor

```shell
helm registry login -u admin harbor.k8s-dev.voytenkov.ru
Password:
Login Succeeded
$ helm push frontend-0.1.1.tgz oci://harbor.k8s-dev.voytenkov.ru/library
Pushed: harbor.k8s-dev.voytenkov.ru/library/frontend:0.1.1
Digest: sha256:3203892dc838417477656933d8a009ede3be16b6763932e94432f8d0245fd1ab
```

### Kubecfg/Jsonnet
        
Вытаскиваем из конфига all.yaml Deployment и Service для paymentservice и shippingservice
Переустановим и убедимся что сервисы catalogue и payment пропали
```shell
$ helm upgrade --install hipster-shop ./hipster-shop --namespace hipster-shop
```
Пишем services.jsonnet
взят со сниппета https://raw.githubusercontent.com/express42/otus-platform-snippets/master/Module-04/05-Templating/hipster-shop-jsonnet/services.jsonnet

Применяем:
```shell
$ kubecfg update services.jsonnet --namespace hipster-shop
INFO  Validating deployments paymentservice
INFO  validate object "apps/v1, Kind=Deployment"
INFO  Validating services paymentservice
INFO  validate object "/v1, Kind=Service"
INFO  Validating deployments shippingservice
INFO  validate object "apps/v1, Kind=Deployment"
INFO  Validating services shippingservice
INFO  validate object "/v1, Kind=Service"
INFO  Fetching schemas for 4 resources
INFO  Creating services paymentservice
INFO  Creating services shippingservice
INFO  Creating deployments paymentservice
INFO  Creating deployments shippingservice
```

### Задание сo ⭐ (jsonnet другие решения)

Не выполнено пока.

### Kustomize

Отпилим сервис cartservice и переустановим.
```
$ helm upgrade --install hipster-shop ./hipster-shop --namespace hipster-shop
```

В папке base лежат оригинальные сами манифесты и файл kustomize указывающих какие ресурсы нужно использовать для кастомизации.
В папке overrides описаны окружения Dev и Prod.

В Dev окружении мы добавили параметр Replicas: 1. Метки и имя неймспеса остались оригинальные. Проверяем:
```shell
$ kubectl kustomize kubernetes-templating/kustomize/overrides/dev/
apiVersion: v1
kind: Namespace
metadata:
  labels:
    app: cartservice
  name: hipster-shop
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: cartservice
  name: cartservice
  namespace: hipster-shop
spec:
  ports:
  - name: grpc
    port: 7070
    targetPort: 7070
  selector:
    app: cartservice
  type: ClusterIP
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: cartservice
  name: cartservice
  namespace: hipster-shop
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cartservice
  template:
    metadata:
      labels:
        app: cartservice
    spec:
      containers:
      - env:
        - name: REDIS_ADDR
          value: redis-cart:6379
        - name: PORT
          value: "7070"
        - name: LISTEN_ADDR
          value: 0.0.0.0
        image: gcr.io/google-samples/microservices-demo/cartservice:v0.1.3
        livenessProbe:
          exec:
            command:
            - /bin/grpc_health_probe
            - -addr=:7070
            - -rpc-timeout=5s
          initialDelaySeconds: 15
          periodSeconds: 10
        name: server
        ports:
        - containerPort: 7070
        readinessProbe:
          exec:
            command:
            - /bin/grpc_health_probe
            - -addr=:7070
            - -rpc-timeout=5s
          initialDelaySeconds: 15
        resources:
          limits:
            cpu: 300m
            memory: 128Mi
          requests:
            cpu: 200m
            memory: 64Mi
```

В Prod окружении мы добавили параметр Replicas: 2 и поменяли limits и requests. Метки и имя неймспеса с суффиксом **-prod**. Проверяем:
```shell
$ kubectl kustomize kubernetes-templating/kustomize/overrides/prod/
apiVersion: v1
kind: Namespace
metadata:
  labels:
    app: cartservice-prod
  name: hipster-shop-prod
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: cartservice-prod
  name: cartservice-prod
  namespace: hipster-shop-prod
spec:
  ports:
  - name: grpc
    port: 7070
    targetPort: 7070
  selector:
    app: cartservice-prod
  type: ClusterIP
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: cartservice-prod
  name: cartservice-prod
  namespace: hipster-shop-prod
spec:
  replicas: 2
  selector:
    matchLabels:
      app: cartservice-prod
  template:
    metadata:
      labels:
        app: cartservice-prod
    spec:
      containers:
      - env:
        - name: REDIS_ADDR
          value: redis-cart:6379
        - name: PORT
          value: "7070"
        - name: LISTEN_ADDR
          value: 0.0.0.0
        image: gcr.io/google-samples/microservices-demo/cartservice:v0.1.3
        livenessProbe:
          exec:
            command:
            - /bin/grpc_health_probe
            - -addr=:7070
            - -rpc-timeout=5s
          initialDelaySeconds: 15
          periodSeconds: 10
        name: server
        ports:
        - containerPort: 7070
        readinessProbe:
          exec:
            command:
            - /bin/grpc_health_probe
            - -addr=:7070
            - -rpc-timeout=5s
          initialDelaySeconds: 15
        resources:
          limits:
            cpu: 500m
            memory: 256Mi
          requests:
            cpu: 200m
            memory: 128Mi
```

Деплоим:
```shell
$ kubectl apply -k kubernetes-templating/kustomize/overrides/dev/
namespace/hipster-shop configured
service/cartservice created
deployment.apps/cartservice created

$ kubectl apply -k kubernetes-templating/kustomize/overrides/prod/
namespace/hipster-shop-prod created
service/cartservice-prod created
deployment.apps/cartservice-prod created

$ kubectl get all -n hipster-shop-prod
NAME                                    READY   STATUS             RESTARTS      AGE
pod/cartservice-prod-767b9f97f6-cbk6q   0/1     CrashLoopBackOff   6 (32s ago)   6m29s
pod/cartservice-prod-767b9f97f6-gnqk2   0/1     CrashLoopBackOff   1 (5s ago)    10s

NAME                       TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/cartservice-prod   ClusterIP   10.112.213.30   <none>        7070/TCP   6m30s

NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/cartservice-prod   0/2     2            0           6m29s

NAME                                          DESIRED   CURRENT   READY   AGE
replicaset.apps/cartservice-prod-767b9f97f6   2         2         0       6m29s
```
Поды сваливаются, так как не могут подключиться к Redis.

### Как проверить работоспособность:
 - см. выше
## PR checklist:
 - [x] Выставлен label с темой домашнего задания
