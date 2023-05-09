# Выполнено ДЗ № 1

 [v] Основное ДЗ
 [v] Задание со *

## В процессе сделано:
 - Настроено локальное окружение в WSL2 Ubuntu: Minikube, kubectl. Настроена интеграция с VS Code через WSL extension.
 - Проверена устойчивость Kubernetes к отказам через удаление и автоматическое восстановление подов в kube-system namespace.
   Web-сервер nginx: 
 - Написан Dockerfile и файл конфигурации Nginx, образ собран и отправлен в репозиторий [docker hub](https://hub.docker.com/r/voitenkov/k8s-intro-web) 
 - Написан манифест, в описание пода также добавлен init-контейнер и к обоим контейнерам смонтирован volume типа EmptyDir, под успешно задеплоен в Minikube.
   Микросервис hipster-frontend:
 - Образ собран и отправлен в репозиторий [docker hub](https://hub.docker.com/r/voitenkov/hipster-frontend) 
 - Написан манифест, под успешно задеплоен в Minikube

## Как запустить проект:
   Web-сервер nginx:
 - Запустить команду kubectl apply -f web-pod.yaml
   Микросервис hipster-frontend:
 - Запустить команду kubectl apply -f frontend-pod-healthy.yaml

## Как проверить работоспособность:
   Web-сервер nginx:
 - Выполнить команды:
  ```shell
  kubectl port-forward --address 0.0.0.0 pod/web 8000:8000 &
  curl http://localhost:8000
  ```
   Микросервис hipster-frontend:
 - Выполнить команды:
  ```shell
  kubectl get pods -l app=frontend --field-selector=status.phase=Running
  ```
## PR checklist:
 - [v] Выставлен label с темой домашнего задания
