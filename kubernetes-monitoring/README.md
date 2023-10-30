# Выполненное Д/З № 6 - Мониторинг компонентов кластера и приложений, работающих в нем

- [x] Основное ДЗ
- [x] дэшборд Grafana

![Wolfenstein](/images/wolf3d-levels.png)  
Такие градации уровней сложностей я видел ...цать лет назад, учась в универе, винды тогда еще не было, запускали из под DOS на 80386, 
Wolfenstein, классика жанра. Играл, но не особо много - компы были учебные.

Домашку сделал с Prometheus Operator, так как вариант с настройкой Prometheus я выполнял на курсе по DevOps, а вот с оператором как раз не сталкивался.

## Сборка образа Nginx
можно было с ConfigMap сразу сделать, но требовалось кастомный и продолжаю развивать Deployment из предыдущих домашек.
Дополнил config Nginx и запушил новую версию **0.0.2** в Docker Hub.

## Деплой веб-сервера Nginx

```bash
$ k apply -f deployment-web.yaml
deployment.apps/web created
$ k apply -f service-web.yaml
service/web created
$ kubectl port-forward --address 0.0.0.0 svc/web 8000:80
Forwarding from 0.0.0.0:8000 -> 8000
```

## Деплой nginx-prometheus-exporter

```bash
$ k apply -f deployment-nginx-exporter.yaml
deployment.apps/nginx-exporter created
$ k apply -f service-nginx-exporter.yaml
service/nginx-exporter created
```

## Деплой Prometheus operator

```bash
$ LATEST=$(curl -s https://api.github.com/repos/prometheus-operator/prometheus-operator/releases/latest | jq -cr .tag_name)
$ curl -sL https://github.com/prometheus-operator/prometheus-operator/releases/download/${LATEST}/bundle.yaml | kubectl create -f -
customresourcedefinition.apiextensions.k8s.io/alertmanagerconfigs.monitoring.coreos.com created
customresourcedefinition.apiextensions.k8s.io/alertmanagers.monitoring.coreos.com created
customresourcedefinition.apiextensions.k8s.io/podmonitors.monitoring.coreos.com created
customresourcedefinition.apiextensions.k8s.io/probes.monitoring.coreos.com created
customresourcedefinition.apiextensions.k8s.io/prometheusagents.monitoring.coreos.com created
customresourcedefinition.apiextensions.k8s.io/prometheuses.monitoring.coreos.com created
customresourcedefinition.apiextensions.k8s.io/prometheusrules.monitoring.coreos.com created
customresourcedefinition.apiextensions.k8s.io/scrapeconfigs.monitoring.coreos.com created
customresourcedefinition.apiextensions.k8s.io/servicemonitors.monitoring.coreos.com created
customresourcedefinition.apiextensions.k8s.io/thanosrulers.monitoring.coreos.com created
clusterrolebinding.rbac.authorization.k8s.io/prometheus-operator created
clusterrole.rbac.authorization.k8s.io/prometheus-operator created
deployment.apps/prometheus-operator created
serviceaccount/prometheus-operator created
service/prometheus-operator created
```

## Деплой ServiceMonitor и Prometheus CR's

```bash
$ k apply -f servicemonitor.yaml
servicemonitor.monitoring.coreos.com/web created
$ k apply -f prometheus.yaml
serviceaccount/prometheus created
clusterrole.rbac.authorization.k8s.io/prometheus created
clusterrolebinding.rbac.authorization.k8s.io/prometheus created
prometheus.monitoring.coreos.com/prometheus created
$ k port-forward --address 0.0.0.0 svc/prometheus-operated 9090:9090
Forwarding from 0.0.0.0:9090 -> 9090
```
![Prometheus](/images/hw07-prometheus.png)  

## Деплой Grafana

```bash
$ k apply -f grafana.yaml
persistentvolumeclaim/grafana-pvc created
deployment.apps/grafana created
service/grafana created
$ k get all
NAME                                       READY   STATUS    RESTARTS        AGE
pod/grafana-d446777f-z7r4n                 0/1     Pending   0               3s
pod/nginx-exporter-789c49685f-svnmd        1/1     Running   0               17m
pod/prometheus-operator-6b8d85bc4c-mws6c   1/1     Running   0               106m
pod/prometheus-prometheus-0                2/2     Running   0               91m
pod/web-c695cc6f4-clbzf                    1/1     Running   0               138m
pod/web-c695cc6f4-jbtrd                    1/1     Running   0               138m
pod/web-c695cc6f4-wkvdc                    1/1     Running   0               138m

NAME                          TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
service/grafana               LoadBalancer   10.96.56.26    <pending>     3000:32691/TCP   3s
service/kubernetes            ClusterIP      10.96.0.1      <none>        443/TCP          5d20h
service/nginx-exporter        ClusterIP      10.96.13.112   <none>        80/TCP           17m
service/prometheus-operated   ClusterIP      None           <none>        9090/TCP         91m
service/prometheus-operator   ClusterIP      None           <none>        8080/TCP         106m
service/web                   ClusterIP      10.96.60.228   <none>        80/TCP           131m

NAME                                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/grafana               0/1     1            0           3s
deployment.apps/nginx-exporter        1/1     1            1           17m
deployment.apps/prometheus-operator   1/1     1            1           106m
deployment.apps/web                   3/3     3            3           138m

NAME                                             DESIRED   CURRENT   READY   AGE
replicaset.apps/grafana-d446777f                 1         1         0       3s
replicaset.apps/nginx-exporter-789c49685f        1         1         1       17m
replicaset.apps/prometheus-operator-6b8d85bc4c   1         1         1       106m
replicaset.apps/web-c695cc6f4                    3         3         3       138m

NAME                                     READY   AGE
statefulset.apps/prometheus-prometheus   1/1     91m
$ k port-forward --address 0.0.0.0 svc/grafana 3000:3000
Forwarding from 0.0.0.0:3000 -> 3000
```

В UI Grafana добавил Data Source **http://prometheus-operated:9090**  
Установил [дэшборд nginx-exporter](https://grafana.com/grafana/dashboards/12708-nginx/)  
![Grafana](/images/hw07-grafana.png)  

## Как проверить работоспособность:

## PR checklist:
 - [x] Выставлен label с темой домашнего задания
