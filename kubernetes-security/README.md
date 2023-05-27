### Выполненное Д/З №5

- [x] Основное ДЗ


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
