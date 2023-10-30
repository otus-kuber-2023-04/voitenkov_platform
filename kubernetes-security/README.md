# Выполненное Д/З № 5 - Безопасность и управление доступом

- [x] Основное ДЗ

### task01 
- Создать Service Account bob, дать ему роль admin в рамках всего кластера
- Создать Service Account dave без доступа к кластеру

### task02
- Создать Namespace prometheus
- Создать Service Account carol в этом Namespace
- Дать всем Service Account в Namespace prometheus возможность делать get, list, watch в отношении Pods всего кластера

### task03
- Создать Namespace dev
- Создать Service Account jane в Namespace dev
- Дать jane роль admin в рамках Namespace dev
- Создать Service Account ken в Namespace dev
- Дать ken роль view в рамках Namespace dev

## Как запустить проект:
 - Выполнить команды:
 ```shell
 kubectl apply -f kubernetes-security/task01
 kubectl apply -f kubernetes-security/task02
 kubectl apply -f kubernetes-security/task03
 ```
## Как проверить работоспособность:

 - Выполнить команды:
```shell
kubectl describe sa bob
kubectl describe clusterrolebinding bob-cluster-admin-binding
kubectl describe sa dave
kubectl describe sa carol
kubectl describe clusterrole cluster-pod-reader
kubectl describe clusterrolebinding sa-prometheus-cluster-pod-reader-binding
kubectl describe sa jane
kubectl describe rolebinding jane-admin-binding
kubectl describe sa ken
kubectl describe rolebinding ken-view-binding
```
## PR checklist:
 - [x] Выставлен label с темой домашнего задания

