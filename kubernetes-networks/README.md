# Выполнено ДЗ № 3

 - [x] Основное ДЗ
 - [x] Задание 1 со *
 - [x] Задание 2 co *
 - [x] Задание 3 co *

## В процессе сделано:

---
### Решение Д/З №3
Работа с тестовым веб-приложением
- Добавление проверок Pod
- Создание объекта Deployment
- Добавление сервисов в кластер ( ClusterIP )
- Включение режима балансировки IPVS

Доступ к приложению извне кластера
- Установка MetalLB в Layer2-режиме
- Добавление сервиса LoadBalancer
- Установка Ingress-контроллера и прокси ingress-nginx
- Создание правил Ingress

#### Добавление проверок Pod
Добавляем readinessProbe и livenessProbe. Получаем файл web-pod.yml
- Создание объекта Deployment 
#### Создали файл web-deploy.yaml, сделали шаблон конфигурации пода, исправили readinessProbe = 8000 и replicas = 3, добавили RollingUpdate.
Узнал, что можно наблюдать за процессом с помощью 
```
kubectl get events --watch
```
#### Добавление сервисов в кластер ( ClusterIP )
- Создал файл web-svc-cip.yaml 

#### Установка MetalLB
MetalLB позволяет запустить внутри кластера L4-балансировщик, который будет принимать извне запросы к сервисам и раскидывать их между подами. Установка его проста:
```
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.9/config/manifests/metallb-native.yaml
```
Проверяем, что были созданы нужные объекты:
```
kubectl --namespace metallb-system get all
```
Настройка балансировщика с помощью Custom Resourses (ConfigMap deprecated):
```
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 172.17.255.1-172.17.255.255
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
```

#### ⭐ DNS через MetalLB
- Сделайте сервис LoadBalancer , который откроет доступ к CoreDNS снаружи кластера (позволит получать записи через внешний IP).

Например, nslookup web.default.cluster.local 172.17.255.10.
- Поскольку DNS работает по TCP и UDP протоколам - учтите это в конфигурации. Оба протокола должны работать по одному и тому же IP-адресу балансировщика.
- Полученные манифесты положите в подкаталог ./coredns

#### Создание Ingress
- Установка начинается с основного манифеста:
```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingressnginx/master/deploy/static/provider/baremetal/deploy.yaml
```
- После установки основных компонентов, в рекомендуется применить манифест, который создаст NodePort -сервис. Но у нас есть MetalLB, мы можем сделать круче.

Получаем манифест - nginx-lb.yaml 

#### Подключение приложение Web к Ingress
Получаем манифест - web-svc-headless.yaml

#### Создание правил Ingress
Получаем манифест - web-ingress.yaml 

![web-ingress](/images/hw04-ingress-nginx.png) 

#### ⭐ Ingress для Dashboard  
- Добавьте доступ к kubernetes-dashboard через наш Ingress-прокси:
- Cервис должен быть доступен через префикс /dashboard ).
- Kubernetes Dashboard должен быть развернут из официального манифеста. Актуальная ссылка есть в репозитории проекта
- Написанные вами манифесты положите в подкаталог ./dashboard

```bash
$ k describe ingress -n kubernetes-dashboard
Name:             dashboard
Labels:           <none>
Namespace:        kubernetes-dashboard
Address:          172.18.0.2
Ingress Class:    nginx
Default backend:  <default>
Rules:
  Host        Path  Backends
  ----        ----  --------
  *
              /   kubernetes-dashboard:8443 (10.244.0.12:8443)
Annotations:  nginx.ingress.kubernetes.io/backend-protocol: HTTPS
              nginx.ingress.kubernetes.io/rewrite-target: /
Events:
  Type    Reason  Age                From                      Message
  ----    ------  ----               ----                      -------
  Normal  Sync    41m (x7 over 61m)  nginx-ingress-controller  Scheduled for sync
```

![Dashboard](/images/hw04-dashboard.png)  



#### ⭐ Canary для Ingress
Реализуйте канареечное развертывание с помощью ingress-nginx:
- Перенаправление части трафика на выделенную группу подов должно происходить по HTTP-заголовку.

Документация [тут](https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/nginx-configuration/annotations.md#canary)
- Естественно, что вам понадобятся 1-2 "канареечных" пода.
- Написанные манифесты положите в подкаталог ./canary

```bash
$ k get all
NAME                          READY   STATUS    RESTARTS      AGE
pod/canary-8656446cfd-9sxpd   0/1     Running   1 (26s ago)   57s
pod/canary-8656446cfd-px2h8   0/1     Running   1 (26s ago)   57s
pod/canary-8656446cfd-rvlzv   0/1     Running   1 (26s ago)   57s
pod/web-56848597f5-9dj9h      1/1     Running   0             179m
pod/web-56848597f5-qwkrs      1/1     Running   0             179m
pod/web-56848597f5-xxl2n      1/1     Running   0             179m

NAME                  TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)        AGE
service/canary-svc    ClusterIP      None            <none>         80/TCP         29s
service/kubernetes    ClusterIP      10.96.0.1       <none>         443/TCP        3h
service/web-svc       ClusterIP      None            <none>         80/TCP         128m
service/web-svc-cip   ClusterIP      10.96.192.95    <none>         80/TCP         176m
service/web-svc-lb    LoadBalancer   10.96.191.183   172.17.255.1   80:30261/TCP   156m

NAME                     READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/canary   0/3     3            0           57s
deployment.apps/web      3/3     3            3           179m

NAME                                DESIRED   CURRENT   READY   AGE
replicaset.apps/canary-8656446cfd   3         3         0       57s
replicaset.apps/web-56848597f5      3         3         3       179m

$ k describe ingress canary
Name:             canary
Labels:           <none>
Namespace:        default
Address:          172.18.0.2
Ingress Class:    nginx
Default backend:  <default>
Rules:
  Host        Path  Backends
  ----        ----  --------
  *
              /web   canary-svc:8000 ()
Annotations:  nginx.ingress.kubernetes.io/canary: true
              nginx.ingress.kubernetes.io/canary-by-header-value: canary
              nginx.ingress.kubernetes.io/rewrite-target: /
Events:
  Type    Reason  Age                From                      Message
  ----    ------  ----               ----                      -------
  Normal  Sync    35s (x2 over 61s)  nginx-ingress-controller  Scheduled for sync

```

### Как проверить работоспособность:

 - Выполнить команды:
  ```shell
  kubectl --namespace metallb-system get all
  kubectl --namespace ingress-nginx get all
  ```
## PR checklist:
 - [x] Выставлен label с темой домашнего задания
