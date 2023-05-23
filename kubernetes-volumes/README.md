### Выполненное Д/З №4

- [x] Основное ДЗ
- [x] Задание со *

ДЗ выполняется на основе kind

Запуск 
```
kind create cluster
export KUBECONFIG="$(kind get kubeconfig-path --name="kind")"
```
#### В этом ДЗ мы развернем StatefulSet c [minIO](https://min.io/) - локальным S3 хранилищем
minio-statefulset.yaml
В результате применения конфигурации должно произойти следующее:
- Запуститься под с MinIO
- Создаться PVC
- Динамически создаться PV на этом PVC с помощью дефолтного StorageClass

Для того, чтобы наш StatefulSet был доступен изнутри кластера, создадим Headless Service - minio-headlessservice.yaml 

#### ⭐ В конфигурации нашего StatefulSet данные указаны в открытом виде, что не безопасно. Поместите данные в secrets и настройте конфигурацию на их использование.
- файл secret.yaml
- плюс исправленный файл minio-statefulset.yaml

## Как запустить проект:
 - Запустить команду **kubectl apply -f kubernetes-volumes**

## Как проверить работоспособность:
### Web-сервер nginx:
 - Выполнить команды:
```shell
kubectl get statefulsets
kubectl get pods
kubectl get pvc
kubectl get pv
kubectl describe <resource> <resource_name>
```
## PR checklist:
 - [x] Выставлен label с темой домашнего задания
