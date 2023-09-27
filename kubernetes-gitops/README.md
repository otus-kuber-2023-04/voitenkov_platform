# Выполнено ДЗ № 11

 - [x] Основное ДЗ
 - [x] Задание со ⭐ (Подготовка Kubernetes кластера)
 - [x] Задание сo ⭐ (Continuous Integration)
 - [x] Задание сo ⭐ (Установка Istio)
 - [ ] Дополнительное задание сo ⭐ (Flagger еще один микросервис)
 - [ ] Дополнительное задание сo ⭐ (Flagger нотификации в Slack)
 - [ ] Дополнительное задание сo ⭐ (Инфраструктурный репозиторий)
 - [ ] Дополнительное задание сo ⭐ (Distributed Tracing)
 - [ ] Дополнительное задание с ⭐⭐ (Monorepos: Please don’t!)
 - [ ] Дополнительное задание с ⭐⭐ (ArgoCD)

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
  - compute инстанс (виртуальная машина) с предустановленным через UserData template-file набором утилит для DevOp-инженера (yandex cli, kubectl, helm, go, etc.)      
8. Ресурсы **Production** окружения проекта:
  - сеть и подсеть
  - сервисные аккаунты
  - группы безопасности
  - Managed Kubernetes cluster
  - зона и записи DNS
    
    В кластере Managed Kubernetes развернуты 1 нодгруппа с включенным автоскалированием нод:
    - default-pool - от 0 до 4     
    
![Yandex.Cloud](/images/hw09-yandex-cloud.png)  

Подробнее по инфраструктурной части см. https://github.com/otus-kuber-2023-04/voitenkov_platform/blob/kubernetes-templating/infrastructure/README.md

## Решение Д/З № 11

### Подготовка Kubernetes кластера | Задание со ⭐

Автоматизируйте создание Kubernetes кластера
Кластер должен разворачиваться после запуска pipeline в GitLab
Инфраструктурный код и файл .gitlab-ci.yaml поместите в отдельный репозиторий и приложите ссылку на данный репозиторий в PR
```shell
git clone https://github.com/GoogleCloudPlatform/microservices-demo
cd microservices-demo
git remote add gitlab git@gitlab.com:voitenkov/microservices-demo.git
git remote remove origin
git push --set-upstream origin main
```
Для автоматизации было сделано:
- Terraform'ом (пока вручную) в Development-окружении создана виртуальная машина, в ней установлен и подключен Gitlab-Runner.
- Настроена интеграция Gitlab с Terraform с использованием готового шаблона. Репозиторий GitLab можно посмотреть https://gitlab.com/voitenkov/microservices-demo . 

Структура репозитория:
```
application - application part of repo
├── .gitlab-ci - microservices pipelines
├── ... - application source code
clusters - GitOps part of repo
├── production 
    ├── flux-system - Flux v2 manifests 
    ├── releases - HelmReleses to be deployed by Flux
    ├── ... - manifests to be deployed by Flux
infrastructure - infrastructure part of repo
├──.gitlab-ci - pipelines for infrastructure deploy (terraform intergration)
├── 1-organization - Organization level Terraform project (to create new clouds within different organizations)
├── 2-cloud - Cloud level Terraform project (to create new folders within specific cloud)
├── 3-development - Development environment level Terraform project (to deploy Development infrastructure within specific cloud)
├── 4-production - Production environment level Terraform project (to deploy Production infrastructure within specific cloud)
├── deploy 
│   ├── charts - Helm charts to deploy applications in Kubernetes
├── images - application images to upload to YC S3 object storage
├── modules - common Terraform modules to use in Terraform projects
│   ├── bucket - for YC object sorage
│   ├── cloud - for YC cloud resourse 
│   ├── folder - for YC folder resourse 
│   ├── instance - for YC compute instance 
│   ├── k8s-cluster - for YC Managed Kubernetes cluster
│   ├── k8s-node - for YC Managed Kubernetes cluster node group
│   ├── sa - for YC service account
│   ├── subnet - for YC VPC subnet
├── templates - cloud-init userdata templates to use in instances deploymnet
.gitlab-ci - Main downstream pipeline
```
 
Сам файл .gitlab-ci.yaml
```shell
include:
  - template: Terraform.latest.gitlab-ci.yml

variables:
  TF_STATE_NAME: default
  TF_CACHE_KEY: default
  TF_ROOT: "infrastructure/4-production"

before_script:
  - |
    cat <<EOF >> ~/.terraformrc
    provider_installation {
      network_mirror {
        url = "https://terraform-mirror.yandexcloud.net/"
        include = ["registry.terraform.io/*/*"]
      }
      direct {
        exclude = ["registry.terraform.io/*/*"]
      }
    }
    EOF
  - echo "$YC_IAM_KEY" > ~/key.json
  - echo "$SSH_PUBLIC_KEY" > ~/id_rsa.pub
```
Коммитим в проекте Terraform, запускается пайплайн, Terraform'ом разворачивается инфраструктура Managed Kubernetes в Yandex Cloud:

![GitLab TF pipeline](/images/hw11-gitlab-pipe.png)  
![GitLab TF_deploy_job](/images/hw11-gitlab-job.png)  

### Continuous Integration | Задание со ⭐

Устанавливаю Gitlab Runner (Kubernetes Executor):
```shell
export HELM_EXPERIMENTAL_OCI=1
helm pull oci://cr.yandex/yc-marketplace/yandex-cloud/gitlab-org/gitlab-runner/chart/gitlab-runner --version 0.49.1-8 --untar --untardir=charts
helm install gitlab-runner gitlab-runner -f gitlab-runner.values.yaml --set runnerRegistrationToken=$GITLAB_TOKEN --namespace gitlab --create-namespace
```
Подготавливаю Downstream pipeline сборки, сканирования на уязвимости и загрузки образов в Gitlab Container Registry, в качестве тега образа используется значение переменной **CI_PIPELINE_IID** (порядковый номер запуска пайплайна), сборка запускается на собственном Gitlab Runner, при сборке используется образ Kaniko:

![GitLab build](/images/hw11-gitlab-build.png)  
Container Registry:

![GitLab build](/images/hw11-gitlab-repos.png)  
Repository tags:

![GitLab build](/images/hw11-gitlab-tags.png)  

### GitOps

### Установка и настройка Flux v2

Задания в методичке основываются на deprecated версии Flux, используем актуальную версию Flux v2, которая существенно переработана и улучшена относительно первой.
Соответсвенно, пытаемся решить поставленную задачу не по методичке, а по документации Flux v2:
- https://fluxcd.io/flux/installation/
- https://fluxcd.io/flux/guides/helmreleases/
- https://fluxcd.io/flux/components/image/imagepolicies/
- https://fluxcd.io/flux/guides/image-update/
- https://fluxcd.io/flux/migration/flux-v1-automation-migration/

Устанавливаем Flux v2 CLI, запускаем bootstrap и интегрируем Flux в репозиторий:
```shell
flux bootstrap git --url=ssh://git@gitlab.com/voitenkov/microservices-demo.git --branch=main --path=clusters/production --components-extra=image-reflector-controller,image-automation-controller --private-key-file=/home/andy/.ssh/id_rsa --password=$GIT_PASSWORD
► cloning branch "main" from Git repository "ssh://git@gitlab.com/voitenkov/microservices-demo.git"
✔ cloned repository
...
✔ helm-controller: deployment ready
✔ kustomize-controller: deployment ready
✔ notification-controller: deployment ready
✔ source-controller: deployment ready
✔ all components are healthy
```
Helm Operator устанавливать не надо, flux CLI устанавливает пачку специфических контроллеров.
```shell
k get all -n flux-system
NAME                                               READY   STATUS    RESTARTS   AGE
pod/helm-controller-c68789cd9-54wv6                1/1     Running   0          82m
pod/image-automation-controller-6c979c96b6-r9zbl   1/1     Running   0          56s
pod/image-reflector-controller-cc6dd9998-wbtng     1/1     Running   0          56s
pod/kustomize-controller-7865db4f48-ltfgz          1/1     Running   0          82m
pod/notification-controller-d85fb896-4hfrl         1/1     Running   0          82m
pod/source-controller-6bb97c96-vcjv6               1/1     Running   0          82m

NAME                              TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
service/notification-controller   ClusterIP   10.112.250.215   <none>        80/TCP    82m
service/source-controller         ClusterIP   10.112.252.104   <none>        80/TCP    82m
service/webhook-receiver          ClusterIP   10.112.156.15    <none>        80/TCP    82m

NAME                                          READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/helm-controller               1/1     1            1           82m
deployment.apps/image-automation-controller   1/1     1            1           56s
deployment.apps/image-reflector-controller    1/1     1            1           56s
deployment.apps/kustomize-controller          1/1     1            1           82m
deployment.apps/notification-controller       1/1     1            1           82m
deployment.apps/source-controller             1/1     1            1           82m

NAME                                                     DESIRED   CURRENT   READY   AGE
replicaset.apps/helm-controller-c68789cd9                1         1         1       82m
replicaset.apps/image-automation-controller-6c979c96b6   1         1         1       56s
replicaset.apps/image-reflector-controller-cc6dd9998     1         1         1       56s
replicaset.apps/kustomize-controller-7865db4f48          1         1         1       82m
replicaset.apps/notification-controller-d85fb896         1         1         1       82m
replicaset.apps/source-controller-6bb97c96               1         1         1       82m
```

### Проверка созданием манифеста для Namespace

Создаем в репозитории в каталоге /clusters/production/ манифест для Namespace, ожидаем синхронизации, неймспейс создается:
```
$ kubectl get ns | grep microservices-demo
microservices-demo   Active   41s
```
### HelmRelease проверка

Создаем сначала для микросервиса Frontend HelmRelease и кладем его в каталог /clusters/production/releases, ждем синхронизацию, видим, что чарт развернулся автоматически. GitOps в действии :)
```shell
$ flux reconcile kustomization flux-system --with-source

$ kubectl get helmrelease -n microservices-demo
NAME       AGE   READY   STATUS
frontend   26s   True    Release reconciliation succeeded
```
### Обновление образа

Вносим изменения в исходный код, запускается пайплайн, в Container Registry выгружается новый образ:

![GitLab TF pipeline](/images/hw11-cr-updated.png)  
Для автоматического обновления образов созданы следующие CR:
```
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: microservices-charts
  namespace: flux-system
spec:
  interval: 1m0s
  ref:
    branch: main
  secretRef:
    name: flux-system
  url: ssh://git@gitlab.com/voitenkov/microservices-demo.git
  ignore: |
    # exclude all
    /*
    # include charts directory
    !/infrastructure/deploy/charts/
---
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImageRepository
metadata:
  name: frontend
  namespace: flux-system
spec:
  image: registry.gitlab.com/voitenkov/microservices-demo/frontend
  interval: 1m
---
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImagePolicy
metadata:
  name: frontend
  namespace: flux-system
spec:
  imageRepositoryRef:
    name: frontend
  policy:
    semver:
      range: 0.0.x
---
apiVersion: image.toolkit.fluxcd.io/v1beta1
kind: ImageUpdateAutomation
metadata:
  name: flux-system
  namespace: flux-system
spec:
  interval: 5m
  sourceRef:
    kind: GitRepository
    name: microservices-charts
  git:
    checkout:
      ref:
        branch: main
    commit:
      author:
        email: voytenkov@inbox.ru
        name: voytenkov
      messageTemplate: '{{range .Updated.Images}}{{println .}}{{end}}'
    push:
      branch: main
  update:
    path: ./clusters/production
    strategy: Setters
```
Ждем синхронизации, проверяем:
```shell
$ kubectl get ImageUpdateAutomation -n flux-system
NAME          LAST RUN
flux-system   2023-07-10T21:46:06Z

$ kubectl describe ImageUpdateAutomation -n flux-system
Name:         flux-system
Namespace:    flux-system
Labels:       kustomize.toolkit.fluxcd.io/name=flux-system
              kustomize.toolkit.fluxcd.io/namespace=flux-system
Annotations:  <none>
API Version:  image.toolkit.fluxcd.io/v1beta1
Kind:         ImageUpdateAutomation
...
Status:
  Conditions:
    Last Transition Time:    2023-07-10T21:45:18Z
    Message:                 no updates made; last commit e6e7139 at 2023-07-10T21:45:11Z
    Reason:                  ReconciliationSucceeded
    Status:                  True
    Type:                    Ready
  Last Automation Run Time:  2023-07-10T21:46:06Z
  Last Push Commit:          e6e7139cff96f31d001c470f8f23d5f999349d46
  Last Push Time:            2023-07-10T21:45:11Z
  Observed Generation:       1
Events:
  Type     Reason  Age                   From                         Message
  ----     ------  ----                  ----                         -------
  Warning  error   5m34s (x10 over 12m)  image-automation-controller  authentication required
  Normal   info    2m50s                 image-automation-controller  Committed and pushed change e6e7139cff96f31d001c470f8f23d5f999349d46 to main
registry.gitlab.com/voitenkov/microservices-demo/frontend:0.0.169
  Helm Chart:                      flux-system/microservices-demo-frontend
  Last Applied Revision:           0.21.1
  Last Attempted Revision:         0.21.1
  Last Attempted Values Checksum:  72d44179eaf153fd4e6a54246e89690bf32cc65b
  Last Release Revision:           4
  Observed Generation:             2
Events:
  Type    Reason  Age                From             Message
  ----    ------  ----               ----             -------
  Normal  info    45m                helm-controller  HelmChart 'flux-system/microservices-demo-frontend' is not ready
  Normal  info    45m                helm-controller  Helm install has started
  Normal  info    45m                helm-controller  Helm install succeeded
  Normal  info    23s (x3 over 13m)  helm-controller  Helm upgrade has started
  Normal  info    23s (x3 over 13m)  helm-controller  Helm upgrade succeeded

$ kubectl describe imagerepository frontend -n flux-system
Name:         frontend
Namespace:    flux-system
Labels:       kustomize.toolkit.fluxcd.io/name=flux-system
              kustomize.toolkit.fluxcd.io/namespace=flux-system
Annotations:  <none>
API Version:  image.toolkit.fluxcd.io/v1beta2
Kind:         ImageRepository

  Last Scan Result:
    Latest Tags:
      latest
      c31e6339ec814ae09bd02dc7c7437ae32e09fc5f371b2269d8d9b1d1056885b3
      c1df80e1e90053353e0ed58bf861cf164fcf6d05e3530751e7984ebd1d200da8
      b8f600564f996f4f51198aed27a1e1bf44cfc27eda613f2d8cc315b37c4b1f48
      90bc3632ffef5225bf606039c33564a84fc7c7e42db9652aba39da3dfdb6796d
      76617cd8600151442e059eb465286c601ccee6e8215dabab86c899f7f489167c
      74ee3b54b135e1954473fb1a1f28635e68c3fda76b3bc0cc81538f7d03d45a74
      0.0.169
      0.0.155
    Scan Time:  2023-07-10T21:30:06Z
    Tag Count:  9
  Observed Exclusion List:
    ^.*\.sig$
  Observed Generation:  1
Events:
  Type     Reason               Age                 From                        Message
  ----     ------               ----                ----                        -------
  Normal   Succeeded            18m                 image-reflector-controller  successful scan: found 7 tags
  Normal   Succeeded            9m11s               image-reflector-controller  successful scan: found 9 tags

flux get image policy frontend
NAME            LATEST IMAGE                                                            READY   MESSAGE
frontend        registry.gitlab.com/voitenkov/microservices-demo/frontend:0.0.169       True    Latest image tag for 'registry.gitlab.com/voitenkov/microservices-demo/frontend' resolved to 0.0.169

{"level":"info","ts":"2023-07-10T21:58:21.694Z","msg":"artifact up-to-date with remote revision: '0.21.0'","controller":"helmchart","controllerGroup":"source.toolkit.fluxcd.io","controllerKind":"HelmChart","HelmChart":{"name":"microservices-demo-frontend","namespace":"flux-system"},"namespace":"flux-system","name":"microservices-demo-frontend","reconcileID":"34d982c1-fd9d-4079-85f0-45d0dafc0f8e"}
{"level":"info","ts":"2023-07-10T21:58:27.056Z","msg":"stored artifact for commit 'chart version increased'","controller":"gitrepository","controllerGroup":"source.toolkit.fluxcd.io","controllerKind":"GitRepository","GitRepository":{"name":"microservices-charts","namespace":"flux-system"},"namespace":"flux-system","name":"microservices-charts","reconcileID":"76c91a25-a586-4142-91db-dc8c034dee40"}
{"level":"info","ts":"2023-07-10T21:58:27.130Z","msg":"packaged 'frontend' chart with version '0.22.0'","controller":"helmchart","controllerGroup":"source.toolkit.fluxcd.io","controllerKind":"HelmChart","HelmChart":{"name":"microservices-demo-frontend","namespace":"flux-system"},"namespace":"flux-system","name":"microservices-demo-frontend","reconcileID":"efda7842-603a-4341-af97-51ea79524cb3"}
{"level":"info","ts":"2023-07-10T21:58:40.094Z","msg":"no changes since last reconcilation: observed revision 'main@sha1:8bbb75ae343a2b558517d5715e8de8fc20660aea'","controller":"gitrepository","controllerGroup":"source.toolkit.fluxcd.io","controllerKind":"GitRepository","GitRepository":{"name":"flux-system","namespace":"flux-system"},"namespace":"flux-system","name":"flux-system","reconcileID":"c9160300-d2f0-476f-956a-151b32cd7040"}
```


Создаем для каждого микросервиса свой CR HelmRelease и кладем их в каталог /clusters/production/releases, ждем синхронизацию, видим, что микросервисы развернулись автоматически. 
```shell
$ kubectl get helmreleases   -n microservices-demo -o wide
NAME                    AGE    READY   STATUS
adservice               65s    True    Release reconciliation succeeded
cartservice             32m    True    Release reconciliation succeeded
checkoutservice         29m    True    Release reconciliation succeeded
currencyservice         29m    True    Release reconciliation succeeded
emailservice            26m    True    Release reconciliation succeeded
frontend                2d3h   True    Release reconciliation succeeded
loadgenerator           24m    True    Release reconciliation succeeded
paymentservice          26m    True    Release reconciliation succeeded
productcatalogservice   26m    True    Release reconciliation succeeded
recommendationservice   26m    True    Release reconciliation succeeded
shippingservice         26m    True    Release reconciliation succeeded
```
### Canary deployments с Flagger и Istio

#### Установка Istio

```shell
$ curl -L https://istio.io/downloadIstio | sh -
$ cd istio-1.6.2/bin/
$ sudo cp istioctl /usr/local/bin/
$ istioctl manifest apply --set profile=demo
```
### Установка Istio | Задание со ⭐

Реализуйте установку Istio альтернативным способом:
установка с помощью Istio-operator.
```shell
$ istioctl operator init
Installing operator controller in namespace: istio-operator using image: docker.io/istio/operator:1.18.1
Operator controller will watch namespaces: istio-system
✔ Istio operator installed
✔ Installation complete
$ kubectl get all -n istio-operator
NAME                                 READY   STATUS    RESTARTS   AGE
pod/istio-operator-97fb74554-c2qwt   1/1     Running   0          108s

NAME                     TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/istio-operator   ClusterIP   10.112.231.162   <none>        8383/TCP   108s

NAME                             READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/istio-operator   1/1     1            1           108s

NAME                                       DESIRED   CURRENT   READY   AGE
replicaset.apps/istio-operator-97fb74554   1         1         1       108s
```

#### Установка Flagger

```
$ helm repo add flagger https://flagger.app
$ kubectl apply -f https://raw.githubusercontent.com/weaveworks/flagger/master/artifacts/flagger/crd.yaml
$ helm upgrade --install flagger flagger/flagger --namespace=istio-system --set crd.create=false --set meshProvider=istio --set metricsServer=http://prometheus.monitoring.svc.cluster.local:9090
```

#### Istio sidecar injector 

Добавить в **microservice-ns.yaml**
```
apiVersion: v1
kind: Namespace
metadata:
    name: microservices-demo
    labels:
      istio-injection: enabled   
```

посмотрим:
```shell
kubectl describe pod -l app=frontend -n microservices-demo

Name:             frontend-hipster-57b5c89c67-zqn4t
Namespace:        microservices-demo
...
Init Containers:
  istio-init:
...
Containers:
  server:
    Container ID:   containerd://f1353f3b172afb50bdadead01cfc48e98f4402403e6fe9915bca69b8b0deb1bd
...
  istio-proxy:
    Container ID:  containerd://a08c6c1527f767eed50875e1fadcc54f7ad947fb280d3888d4afcf64d29d967a
    Image:         docker.io/istio/proxyv2:1.18.1
...
Events:
  Type    Reason     Age    From               Message
  ----    ------     ----   ----               -------
  Normal  Scheduled  2m13s  default-scheduler  Successfully assigned microservices-demo/frontend-hipster-57b5c89c67-zqn4t to cl1mktce243bh6pnth9k-erox
  Normal  Pulled     2m10s  kubelet            Container image "docker.io/istio/proxyv2:1.18.1" already present on machine
  Normal  Created    2m9s   kubelet            Created container istio-init
  Normal  Started    2m8s   kubelet            Started container istio-init
  Normal  Pulling    2m8s   kubelet            Pulling image "registry.gitlab.com/voitenkov/microservices-demo/frontend:0.0.195"
  Normal  Pulled     2m7s   kubelet            Successfully pulled image "registry.gitlab.com/voitenkov/microservices-demo/frontend:0.0.195" in 1.283616194s
  Normal  Created    2m6s   kubelet            Created container server
  Normal  Started    2m5s   kubelet            Started container server
  Normal  Pulled     2m5s   kubelet            Container image "docker.io/istio/proxyv2:1.18.1" already present on machine
  Normal  Created    2m4s   kubelet            Created container istio-proxy
  Normal  Started    2m4s   kubelet            Started container istio-proxy
```

### Добавить VirtualService и Gateway

```shell
$ kubectl get gateway -n microservices-demo
NAME       AGE
frontend   26s
andy@res-3:~$ kubectl get virtualservice -n microservices-demo
NAME       GATEWAYS       HOSTS   AGE
frontend   ["frontend"]   ["*"]   41s

$ kubectl get svc istio-ingressgateway -n istio-system
NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP       PORT(S)                                                                      AGE
istio-ingressgateway   LoadBalancer   10.112.246.183   158.160.108.188   15021:30239/TCP,80:31971/TCP,443:31481/TCP,31400:30162/TCP,15443:30145/TCP   36m
```
![Istio Gateway](/images/hw11-istio-gw.png)  

### Canary

Коммитим манифест с Canary CR:
```shell
$ kubectl get canary -n microservices-demo
NAME       STATUS         WEIGHT   LASTTRANSITIONTIME
frontend   Initializing   0        2023-07-15T10:23:10Z
```
Обновил pod, добавив ему к названию постфикс primary:
```shell
kubectl get pods -n microservices-demo -l app=frontend-primary
NAME                                       READY   STATUS    RESTARTS   AGE
frontend-hipster-primary-c694675f4-6q5dk   2/2     Running   0          116s
```
Для loadbalancer был выставлен publicIP.
Также для успешности релиза надо было настроить Loadgenerator микросервис на внешний IP Frontend.

Выкатываем новую версию и ждем. Через какое-то время:
```
$ kubectl describe canary frontend -n microservices-demo
Events:
  Type     Reason  Age              From     Message
  ----     ------  ----             ----     -------
  Warning  Synced  9m4s             flagger  frontend-primary.microservices-demo not ready: waiting for rollout to finish: observed deployment generation less than desired generation
  Normal   Synced  8m34s            flagger  Initialization done! frontend.microservices-demo
  Normal   Synced  7m34s            flagger  New revision detected! Scaling up frontend.microservices-demo
  Normal   Synced  7m4s             flagger  Starting canary analysis for frontend.microservices-demo
  Normal   Synced  7m4s             flagger  Advance frontend.microservices-demo canary weight 5
  Normal   Synced  6m30s            flagger  Advance frontend.microservices-demo canary weight 10
  Normal   Synced  5m               flagger  Advance frontend.microservices-demo canary weight 15
  Normal   Synced  4m30s            flagger  Advance frontend.microservices-demo canary weight 20
  Normal   Synced  3m               flagger  Advance frontend.microservices-demo canary weight 25
  Normal   Synced  2m30s            flagger  Advance frontend.microservices-demo canary weight 30
  Normal   Synced  2m               flagger  Copying frontend.microservices-demo template spec to frontend-primary.microservices-demo
  Normal   Synced  1m (x3 over 7m)  flagger  (combined from similar events): Promotion completed! Scaling down frontend-hipster.microservices-demo

$ kubectl get canaries -n microservices-demo 
NAME       STATUS      WEIGHT   LASTTRANSITIONTIME
frontend   Succeeded   0       2023-07-15T11:23:10Z

$ kubectl get pods -n microservices-demo 
NAME                                        READY   STATUS    RESTARTS   AGE
adservice-86c4899fcb-trbkh                  2/2     Running   0          10m
cartservice-54d954bdf9-gd2dg                2/2     Running   2          10m
cartservice-redis-master-0                  2/2     Running   0          10m
checkoutservice-7f664dbc5d-d9bzl            2/2     Running   0          10m
currencyservice-78b589b9c4-j8vzh            2/2     Running   0          10m
emailservice-55584694f4-szh28               2/2     Running   0          10m
frontend-hipster-56b9ff5464-znkxt           2/2     Running   0          64s
frontend-hipster-primary-5bbf57d9cf-tx8mb   2/2     Running   0          10m
loadgenerator-5f89f6487d-6q2m5              2/2     Running   0          10m
paymentservice-6f889fd874-p5bnc             2/2     Running   0          10m
productcatalogservice-846756b974-cbrx5      2/2     Running   0          10m
recommendationservice-58cb799b76-rhnv4      2/2     Running   0          10m
shippingservice-9c6bbf4b-rrb8k              2/2     Running   0          10m
```

### Flagger | Задание со ⭐️
Реализуйте канареечное развертывание для одного из оставшихся микросервисов. Опишите сложности с которыми пришлось столкнуться в PR и соответствующим образом модифицируйте файлы в GitLab репозитории.

Берем сервис adservice. Так как он и все остальные сервисы работают по gRPC, в CRD canary для этого сервиса указываем `portName: grpc`. И наш Loadgenerator уже не подходит. Деплоим loadgenerator от Flagger:
```shell
helm upgrade -i flagger-loadtester flagger/loadtester --namespace=istio-system --set cmd.timeout=1h --set cmd.namespaceRegexp=''
```
Однако, нагрузка пока не идет:
```shell
Events:
  Type     Reason  Age                    From     Message
  ----     ------  ----                   ----     -------
  Normal   Synced  107s                   flagger  New revision detected! Scaling up adservice.microservices-demo
  Warning  Synced  77s                    flagger  canary deployment adservice.microservices-demo not ready: waiting for rollout to finish: 0 of 1 (readyThreshold 100%) updated replicas are available
  Normal   Synced  47s                    flagger  Starting canary analysis for adservice.microservices-demo
  Normal   Synced  47s                    flagger  Advance adservice.microservices-demo canary weight 5
  Warning  Synced  17s                    flagger  Halt advancement no values found for istio metric request-success-rate probably adservice.microservices-demo is not receiving traffic: running query failed: no values found
```
Дальше не разбирался. Там еще с метриками будет вопрос.


### Удаление инфраструктуры

Для удаления **Production** инфраструктуры, запускаем пайплайн, а в нем вручную запускаем Destroy Job, инфраструктура удаляется:

![GitLab TF destroy_pipeline](/images/hw11-destroy.png)  
![GitLab TF_destroy_job](/images/hw11-destroy-job.png)  

Для удаления **Development** инфраструктуры, пайплайн не получится задействовать, так как собственно в ней запущен Gitlab Runner. Запускаем Terraform Destroy в каталоге проекта Infrastructure/3-Development

## Как проверить работоспособность:
 - см. выше
## PR checklist:
 - [x] Выставлен label с темой домашнего задания
