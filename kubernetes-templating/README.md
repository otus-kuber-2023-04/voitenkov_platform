# Выполнено ДЗ № 8 - Шаблонизация манифестов. Helm и его аналоги (Jsonnet, Kustomize)

 - [x] Основное ДЗ
 - [x] Задание со ⭐ (chartmuseum)
 - [x] Задание сo ⭐ (helmfile)
 - [x] Задание сo ⭐ (community charts)
 - [x] Необязательное задание (helm secrets)
 - [x] Задание сo ⭐ (jsonnet другие решения)

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

## Решение Д/З № 8

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
$ helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.12.0 --set installCRDs=true

NAME: cert-manager
LAST DEPLOYED: Sun Jun 11 16:42:22 2023
NAMESPACE: cert-manager
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
cert-manager v1.12.0 has been deployed successfully!

$ kubectl label namespace cert-manager certmanager.k8s.io/disable-validation="true" 
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

Для того, чтобы можно было пользоваться развернутым chartmuseum репозиторием, надо добавить в values разрешение на обработку маршрутов /api:
```shell
env:
  open:
    # disable all routes prefixed with /api
    DISABLE_API: false
```

Возьмем чарт микросервиса frontend, запакуем:
```shell
cd kubernetes-templating
helm package frontend
```
и отправим в наш chartmuseum репозиторий:
```shell
$ curl --data-binary "@frontend-0.1.1.tgz" https://chartmuseum.k8s-dev.voytenkov.ru/api/charts
{"saved":true}
```
Добавим развернутый ранее chartmuseum в качестве Helm репозитория:  
`helm repo add my-chartmuseum https://chartmuseum.k8s-dev.voytenkov.ru/`

Поиск по репозиторию - увидим, что загруженный чарт появился (если нет, то стоит сделать helm repo update):
```shell
$ helm search repo my-chartmuseum/
NAME                    CHART VERSION   APP VERSION     DESCRIPTION
my-chartmuseum/frontend 0.1.1           1.16.0          A Helm chart for Kubernetes
```

Для установки чарта запустить:
```shell
$ helm install frontend my-chartmuseum/frontend
NAME: frontend
LAST DEPLOYED: Thu Sep 14 22:25:08 2023
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

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

Добавим в Chart hipster-shop зависимость, например Redis:
```shell
dependencies:
  - name: redis
    version: 17.11.5
    repository: https://charts.bitnami.com/bitnami
```

Обновляем зависимости с учетом Redis:
```shell
helm dep update hipster-shop
Getting updates for unmanaged Helm repositories...
...Successfully got an update from the "https://charts.bitnami.com/bitnami" chart repository
Hang tight while we grab the latest from your chart repositories...
...
Update Complete. ⎈Happy Helming!⎈
Saving 2 charts
Downloading redis from repo https://charts.bitnami.com/bitnami
Deleting outdated charts
```
Обновляем чарт:
```shell
helm upgrade --install hipster-shop kubernetes-templating/hipster-shop --namespace hipster-shop
```

Видим новый микросервис redis-cart:
```shell
$ k get all -n hipster-shop | grep redis-cart
pod/redis-cart-7667674fc7-4bxbv              1/1     Running            0          7m56s
pod/redis-cart-master-d77d9db6-vhdl7         1/1     Running            0          72s
service/redis-cart              ClusterIP   10.112.204.239   <none>        6379/TCP       7m56s
service/redis-cart-headless     ClusterIP   None             <none>        6379/TCP       73s
service/redis-cart-master       ClusterIP   10.112.130.216   <none>        6379/TCP       73s
deployment.apps/redis-cart              1/1     1            1           7m56s
deployment.apps/redis-cart-master       1/1     1            1           72s
replicaset.apps/redis-cart-7667674fc7              1         1         1       7m56s
replicaset.apps/redis-cart-master-d77d9db6         1         1         1       72s
```


### Необязательное задание (helm secrets)

Установим sops и helm-secrets:
```shell
$ go install go.mozilla.org/sops/v3/cmd/sops@latest
$ helm plugin install https://github.com/jkroepke/helm-secrets --version v3.12.0
Installed plugin: secrets
```

Сгенерируем новый PGP ключ:
```shell
gpg --full-generate-key
```
Просмотр ключей:
```shell
$ gpg -k
gpg: checking the trustdb
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: depth: 0  valid:   1  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 1u
/home/andy/.gnupg/pubring.kbx
-----------------------------
pub   rsa3072 2023-09-14 [SC]
      9A2AD.........48EC2
uid           [ultimate] andrey (otus rules!) <voytenkov@inbox.ru>
sub   rsa3072 2023-09-14 [E]

создал secrets.yaml
зашифровал:
```shell
$ sops -e -i --pgp 9A2AD.........48EC2 secrets.yaml
[PGP]    WARN[0000] Deprecation Warning: GPG key fetching from a keyserver within sops will be removed in a future version of sops. See https://github.com/mozilla/sops/issues/727 for more information.
```
Проверил что файл зашифрован:
```shell
$ cat secrets.yaml
visibleKey: ENC[AES256_GCM,data:EmcDJ2tid8wb/D0=,iv:dVqPp6XkHY5qxhz2bwgh2Ca/fzliDYQ+XRGQpY+Ck2Q=,tag:iGEMBrzp/LBu7goGupGa4w==,type:str]
sops:
    kms: []
    gcp_kms: []
    azure_kv: []
    hc_vault: []
    age: []
    lastmodified: "2023-09-14T21:21:34Z"
    mac: ENC[AES256_GCM,data:KXGKOMs+xeB2d2pzRbpFACr1uvrmMPQ
...
            =fnXu
            -----END PGP MESSAGE-----
          fp: 9A2ADCD510A680FAD264750DC772CC4F5B548EC2
    unencrypted_suffix: _unencrypted
    version: 3.7.3
```
    
Cоздал манифест с вызовом к секрету:  
`$ helm secrets upgrade --install frontend frontend --namespace hipster-shop -f frontend/values.yaml -f frontend/secrets.yaml`

Проверьте, что секрет создан, и его содержимое соответствует нашим ожиданиям: **сделано**  
Предложите способ использования плагина helm-secrets в CI/CD:  
**расшифровка паролей и других чувствительных данных, хранящихся в git-репозитории, хотя лучше использовать такие решения, как Hashicorp Vault.**  
Про что необходимо помнить, если используем helm-secrets (например, как обезопасить себя от коммита файлов с секретами, которые забыл зашифровать)?  
**нешифрованные файлы именовать по специальному шаблону, который держать в .gitignore. После шифрования файлы сохранять с именем, не подпадающим под шаблон.**

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

Попробуем qbec. Создадим demo-приложение:
```shell
qbec init qbec --with-example
using server URL "https://84.252.128.16" and default namespace "default" for the default environment
wrote qbec/params.libsonnet
wrote qbec/environments/base.libsonnet
wrote qbec/environments/default.libsonnet
wrote qbec/components/hello.jsonnet
wrote qbec/qbec.yaml
```
Заменим в демо-приложении hello.jsonnet на services.jsonnet и подправим переменные в конфигурационных файлах demo, чтобы они соответствовали нашим микросервисам.
Проверяем:
```shell
$ qbec show default
1 components evaluated in 9ms
---
apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    qbec.io/component: services
  labels:
    name: paymentservice
    qbec.io/application: qbec-test
    qbec.io/environment: default
  name: paymentservice
spec:
  minReadySeconds: 30
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      name: paymentservice
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      annotations: {}
      labels:
        name: paymentservice
    spec:
      containers:
      - args: []
        env:
        - name: PORT
          value: "50051"
        image: gcr.io/google-samples/microservices-demo/paymentservice:v0.1.3
        imagePullPolicy: IfNotPresent
        livenessProbe:
          exec:
            command:
            - /bin/grpc_health_probe
            - -addr=:50051
          initialDelaySeconds: 20
          periodSeconds: 15
        name: server
        ports:
        - containerPort: 50051
        readinessProbe:
          exec:
            command:
            - /bin/grpc_health_probe
            - -addr=:50051
          initialDelaySeconds: 20
          periodSeconds: 15
        resources:
          limits:
            cpu: 200m
            memory: 128Mi
          requests:
            cpu: 100m
            memory: 128Mi
        securityContext:
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 10001
        stdin: false
        tty: false
        volumeMounts: []
      imagePullSecrets: []
      initContainers: []
      terminationGracePeriodSeconds: 30
      volumes: []

---
apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    qbec.io/component: services
  labels:
    name: shippingservice
    qbec.io/application: qbec-test
    qbec.io/environment: default
  name: shippingservice
spec:
  minReadySeconds: 30
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      name: shippingservice
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      annotations: {}
      labels:
        name: shippingservice
    spec:
      containers:
      - args: []
        env:
        - name: PORT
          value: "50051"
        image: gcr.io/google-samples/microservices-demo/shippingservice:v0.1.3
        imagePullPolicy: IfNotPresent
        livenessProbe:
          exec:
            command:
            - /bin/grpc_health_probe
            - -addr=:50051
          initialDelaySeconds: 20
          periodSeconds: 15
        name: server
        ports:
        - containerPort: 50051
        readinessProbe:
          exec:
            command:
            - /bin/grpc_health_probe
            - -addr=:50051
          initialDelaySeconds: 20
          periodSeconds: 15
        resources:
          limits:
            cpu: 200m
            memory: 128Mi
          requests:
            cpu: 100m
            memory: 128Mi
        securityContext:
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 10001
        stdin: false
        tty: false
        volumeMounts: []
      imagePullSecrets: []
      initContainers: []
      terminationGracePeriodSeconds: 30
      volumes: []

---
apiVersion: v1
kind: Service
metadata:
  annotations:
    qbec.io/component: services
  labels:
    name: paymentservice
    qbec.io/application: qbec-test
    qbec.io/environment: default
  name: paymentservice
spec:
  ports:
  - name: grpc
    port: 50051
    targetPort: 5051
  selector:
    name: paymentservice
  type: ClusterIP

---
apiVersion: v1
kind: Service
metadata:
  annotations:
    qbec.io/component: services
  labels:
    name: shippingservice
    qbec.io/application: qbec-test
    qbec.io/environment: default
  name: shippingservice
spec:
  ports:
  - name: grpc
    port: 50051
    targetPort: 5051
  selector:
    name: shippingservice
  type: ClusterIP
```

Деплоим:
```shell
$ qbec apply default
setting cluster to yc-managed-k8s-cat9qin15kkpl904lp72
setting context to yc-k8s-otus-kuber-stage-cluster-1
cluster metadata load took 979ms
1 components evaluated in 20ms

will synchronize 4 object(s)

Do you want to continue [y/n]: y
1 components evaluated in 7ms
create deployments paymentservice -n hipster-shop (source services)
create deployments shippingservice -n hipster-shop (source services)
create services paymentservice -n hipster-shop (source services)
create services shippingservice -n hipster-shop (source services)
waiting for deletion list to be returned
server objects load took 1.04s
---
stats:
  created:
  - deployments paymentservice -n hipster-shop (source services)
  - deployments shippingservice -n hipster-shop (source services)
  - services paymentservice -n hipster-shop (source services)
  - services shippingservice -n hipster-shop (source services)

waiting for readiness of 2 objects
  - deployments paymentservice -n hipster-shop
  - deployments shippingservice -n hipster-shop

  0s    : deployments shippingservice -n hipster-shop :: 0 of 1 updated replicas are available
  0s    : deployments paymentservice -n hipster-shop :: 0 of 1 updated replicas are available
✓ 1m0s  : deployments paymentservice -n hipster-shop :: successfully rolled out (1 remaining)
✓ 1m0s  : deployments shippingservice -n hipster-shop :: successfully rolled out (0 remaining)

✓ 1m0s: rollout complete
command took 1m5.11s
```

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
