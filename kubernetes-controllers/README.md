# Выполнено ДЗ № 2 - Механика запуска и взаимодействия контейнеров в Kubernetes

 - [x] Основное ДЗ
 - [x] Задание со *
 - [x] Задание с **

## В процессе сделано:
- Развернут локальный кластер k8s на основе [kind](https://kind.sigs.k8s.io/docs/user/quick-start/) 
- ReplicaSet ***frontend-replicaset.yaml*** задеплоен и протестирован.
- Deployment ***frontend-deployment.yaml*** задеплоен и протестирован.
- Собран образ ***paymentservice*** и отправлен в репозиторий [https://hub.docker.com/r/voitenkov/hipster-paymentservice](https://hub.docker.com/r/voitenkov/hipster-paymentservice)
- ReplicaSet ***paymentservice-replicaset.yaml*** задеплоен и протестирован.
- Deployment ***paymentservice-deployment.yaml*** задеплоен и протестирован.
- Blue-green сценарий развертывания ***paymentservice-deployment-bg.yaml*** задеплоен и протестирован.
- Reverse Rolling Update сценарий развертывания ***paymentservice-deployment-reverse.yaml*** задеплоен и протестирован.
- ReadynessProbe добавлен в ***frontend-deployment.yaml*** и протестирован.
- Сценарий неудачного обновления и его отката (Rollback) протестирован.
- DaemonSet для node-exporter ***node-exporter-daemonset.yaml*** задеплоен и протестирован на все ноды, включая Master.
---
### Решение Д/З №2

- Руководствуясь материалами лекции опишите произошедшую ситуацию, почему обновление ReplicaSet не повлекло обновление запущенных pod?

Ответ: 
ReplicaSet не умеет рестартовать запущенные поды при обновлении шаблона, для этого придуман Deployment.

- ⭐ Deployment | С использованием параметров **maxSurge** и **maxUnavailable** самостоятельно реализуйте два следующих сценария развертывания:
1. Аналог blue-green:
 - Развертывание трех новых pod
 - Удаление трех старых pod

Результат - ***paymentservice-deployment-bg.yaml***
```shell
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 100% 
```

2. Reverse Rolling Update:
  - Удаление одного старого pod
  - Создание одного нового pod 
  - ....
  - ....

Результат - ***paymentservice-deployment-reverse.yaml***
```shell
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 0 
```

- ⭐ Написать манифест DaemonSet для node-exporter

Опробуем DaemonSet на примере [Node Exporter](https://github.com/prometheus/node_exporter)
1. Найдите в интернете или напишите самостоятельно манифест node-exporter-daemonset.yaml для развертывания DaemonSet с Node Exporter.
2. После применения данного DaemonSet и выполнения команды:
 ```shell
 kubectl port-forward <имя любого pod в DaemonSet> 9100:9100
 ```
метрики должны быть доступны на localhost: curl localhost:9100/metrics

- ⭐⭐ DaemonSet на Master и Worker nodes
Как правило, мониторинг требуется не только для worker, но и для master нод. При этом, по умолчанию, pod управляемые DaemonSet на master нодах не разворачиваются 
Найдите способ модернизировать свой DaemonSet таким образом, чтобы Node Exporter был развернут как на master, так и на worker нодах (конфигурацию самих нод изменять нельзя) 
Отразите изменения в манифесте.

Нужно добавить: 
```shell
    spec:
      tolerations:
      - operator: "Exists"
```
Результат - ***node-exporter-daemonset.yaml***

### Как проверить работоспособность:

 - Выполнить команды:
  ```shell
  kubectl apply -f node-exporter-daemonset.yaml 
  kubectl port-forward <имя любого pod в DaemonSet> 9100:9100
  curl localhost:9100/metrics
  ```
## PR checklist:
 - [x] Выставлен label с темой домашнего задания
