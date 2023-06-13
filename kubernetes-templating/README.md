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

#### Chart Museum

Cпециализированный репозиторий для хранения helm charts.

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
- Chartmuseum доступен по URL https://chartmuseum.DOMAIN
- Сертификат для данного URL валиден



#### Harbor

- [harbor](https://github.com/goharbor/harbor-helm) хранилище артефактов общего назначения (Docker Registry), поддерживающее helm charts

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

### Установите harbor в кластер с использованием helm3
Для этого: 
- Реализуем файл [values.yaml]
- Установил harbor:
```
helm repo add harbor https://helm.goharbor.io
helm repo update
kubectl create ns harbor
helm upgrade --install harbor harbor/harbor --wait \
--namespace=harbor \
--version=1.1.2 \
-f kubernetes-templating/harbor/values.yaml
```
Реквизиты по умолчанию: admin/Harbor12345

Критерий успешности установки: 
- Chartmuseum доступен по URL https://harbor.DOMAIN
- Сертификат для данного URL валиден

Обратите внимание, как helm3 хранит информацию о release:
```
kubectl get secrets -n harbor -l owner=helm
```
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
## Таким образом мы можем микросервисное приложение выносить в отдельную разработку и добавлять при необходмости

Осталось понять, как из CI-системы мы можем менять параметры helm chart, описанные в values.yaml. Для этого существует специальный ключ --set. Изменим NodePort для frontend в release, не меняя его в самом chart:
```
helm upgrade --install hipster-shop kubernetes-templating/hipster-shop --namespace
hipster-shop --set frontend.service.NodePort=31234
```

⭐ Выберите сервисы, которые можно установить как зависимости, используя community chart's. Например, это может быть Redis. Реализуйте их установку через Chart.yaml и обеспечьте сохранение работоспособности приложения.
- Убираем redis из hister-shop/templates/all-hipster-shop.yaml
- Создаем ```helm create redis```
- Добавляем зависимости hister-shop/Chart.yaml и обновляем эти зависимости ```helm dep update kubernetes-templating/hipster-shop```
- В директории kubernetes-templating/hipster-shop/charts должен появится архив redis-****
- Обновляем release hipster-shop ```helm upgrade --install hipster-shop hipster-shop --namespace hipster-shop```


```
### Как проверить работоспособность:
 - см. выше
## PR checklist:
 - [x] Выставлен label с темой домашнего задания
