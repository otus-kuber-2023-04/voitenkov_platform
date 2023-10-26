# Выполнено ДЗ № 1 - Знакомство с Kubernetes, основные понятия и архитектура

 - [x] Основное ДЗ
 - [x] Задание со *

## В процессе сделано:
 - Настроено локальное окружение в **Windows Subsystem for Linux (WSL) 2 Ubuntu**: **Minikube**, **kubectl**. Настроена интеграция с **VS Code** через **WSL extension**.
 - Проверена устойчивость Kubernetes к отказам через удаление и автоматическое восстановление подов в kube-system namespace.
### Web-сервер nginx: 
 - Написан Dockerfile и файл конфигурации Nginx, образ собран и отправлен в репозиторий [https://hub.docker.com/r/voitenkov/k8s-intro-web](https://hub.docker.com/r/voitenkov/k8s-intro-web) 
 - Написан манифест, в описание пода также добавлен init-контейнер и к обоим контейнерам смонтирован volume типа EmptyDir, под успешно задеплоен в Minikube.
### Микросервис hipster-frontend:
 - Образ собран и отправлен в репозиторий [https://hub.docker.com/r/voitenkov/hipster-frontend](https://hub.docker.com/r/voitenkov/hipster-frontend) 
 - Написан манифест, под успешно задеплоен в Minikube
---
## Решение ДЗ
- Разберитесь почему все pod в namespace kube-system восстановились после удаления. Укажите причину в описании PR. Hint: core-dns и, например, kube-apiserver, имеют различия в механизме запуска и восстанавливаются по разным причинам:

\
Поды кроме **core-dns** - это [static Pods](https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/), управляемые напрямую kubelet'ом. Описания подов хранятся тут:
```
docker@minikube:~$ ll /etc/kubernetes/manifests/
total 28
drwxr-xr-x 1 root root 4096 May  8 21:43 ./
drwxr-xr-x 1 root root 4096 May  8 21:43 ../
-rw------- 1 root root 2470 May  8 21:43 etcd.yaml
-rw------- 1 root root 4076 May  8 21:43 kube-apiserver.yaml
-rw------- 1 root root 3395 May  8 21:43 kube-controller-manager.yaml
-rw------- 1 root root 1441 May  8 21:43 kube-scheduler.yaml
```
\
Под **coredns** описан в деплойменте: 
```
andy@res-3:~$ kubectl describe deployments.apps -n kube-system
Name:                   coredns
Namespace:              kube-system
CreationTimestamp:      Mon, 08 May 2023 23:43:57 +0200
Labels:                 k8s-app=kube-dns
Annotations:            deployment.kubernetes.io/revision: 1
Selector:               k8s-app=kube-dns
Replicas:               1 desired | 1 updated | 1 total | 1 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  1 max unavailable, 25% max surge
```
- ⭐ Выясните причину, по которой pod frontend находится в статусе **Error**: 

\
Потому, что в спецификации контейнера не заданы переменные окружения (env), необходимые для работы приложения: 
```sh
panic: environment variable "PRODUCT_CATALOG_SERVICE_ADDR" not set
```
---
## Как запустить проект:
### Web-сервер nginx:
 - Запустить команду **kubectl apply -f web-pod.yaml**
### Микросервис hipster-frontend:
 - Запустить команду **kubectl apply -f frontend-pod-healthy.yaml**

## Как проверить работоспособность:
### Web-сервер nginx:
 - Выполнить команды:
  ```shell
  kubectl port-forward --address 0.0.0.0 pod/web 8000:8000 &
  curl http://localhost:8000
  ```
### Микросервис hipster-frontend:
 - Выполнить команды:
  ```shell
  kubectl get pods -l app=frontend --field-selector=status.phase=Running
  ```
## PR checklist:
 - [x] Выставлен label с темой домашнего задания
