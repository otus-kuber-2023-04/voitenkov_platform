# Выполнено ДЗ № 9

 - [x] Основное ДЗ
 - [ ] Задание со ⭐ (chartmuseum)
 - [x] Задание сo ⭐ (helmfile)
 - [ ] Задание сo ⭐ (community charts)
 - [ ] Необязательное задание (helm secrets)
 - [ ] Задание сo ⭐ (jsonnet другие решения)

## В процессе сделано:

### Подготовка инфраструктуры

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
  
```bash
$ minikube start
😄  minikube v1.30.1 on Ubuntu 22.04 (amd64)
...
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
```
- Составлен CustomResource и CustomResourceDefinition для mysql оператора.
- Собран образ и задеплоен оператор.
- Проведены тесты бэкап-восстановление базы данных MySQL после удаления инстанса MySQL

---
## Решение Д/З № 8

Все манифесты лежат в директории kubernetes-operators/deploy

### CustomResourceDefinition и CustomResourse

Cоздадим CustomResourceDefinition
```bash
$ kubectl apply -f deploy/crd.yaml
customresourcedefinition.apiextensions.k8s.io/mysqls.otus.homework created
```
Cоздадим CustomResource
```bash
kubectl apply -f deploy/cr.yaml
Error from server (BadRequest): error when creating "deploy/cr.yaml": MySQL in version "v1" cannot be handled as a MySQL: strict decoding error: unknown field "usless_data"
```
Убираем из cr.yml: usless_data: "useless info". Применяем ... 
```bash
$ kubectl apply -f deploy/cr.yaml
mysql.otus.homework/mysql-instance created

$ k describe mysql mysql-instance
Name:         mysql-instance
Namespace:    default
Labels:       <none>
Annotations:  <none>
API Version:  otus.homework/v1
Kind:         MySQL
Metadata:
  Creation Timestamp:  2023-06-01T11:49:28Z
  Generation:          1
  Resource Version:    39522
  UID:                 6e436b51-2640-4f0a-9b33-a9d0d5d17a56
Spec:
  Database:      otus-database
  Image:         mysql:5.7
  Password:      otuspassword
  storage_size:  1Gi
Events:          <none>
```
Схема уже описана, так как в новой версии API схема обязательна.
Также добавил Requred поля, деплой CR без обязательного поля дает ошибку:
```bash
$ kubectl apply -f deploy/cr2.yaml
The MySQL "mysql-instance2" is invalid: spec.password: Required value
```
Доустанавливаем зависимости и запускаем оператор:
```bash
sudo apt install python3-pip
sudo apt-get update
sudo apt install python3-pip --fix-missing
pip install kopf
kopf run mysql-operator.py
pip install kubernetes
pip install jinja2
$ kopf run mysql-operator.py
/home/andy/.local/lib/python3.10/site-packages/kopf/_core/reactor/running.py:179: FutureWarning: Absence of either namespaces or cluster-wide flag will become an error soon. For now, switching to the cluster-wide mode for backward compatibility.
  warnings.warn("Absence of either namespaces or cluster-wide flag will become an error soon."
[2023-06-01 16:20:52,500] kopf._core.engines.a [INFO    ] Initial authentication has been initiated.
[2023-06-01 16:20:52,514] kopf.activities.auth [INFO    ] Activity 'login_via_client' succeeded.
[2023-06-01 16:20:52,514] kopf._core.engines.a [INFO    ] Initial authentication has finished.
[2023-06-01 16:20:52,725] kopf.objects         [INFO    ] [default/mysql-instance] Handler 'mysql_on_create' succeeded.
[2023-06-01 16:20:52,725] kopf.objects         [INFO    ] [default/mysql-instance] Creation is processed: 1 succeeded; 0 failed.
```

### Деплой оператора 
Создаем в папке kubernetes-operator/deploy манифесты и применяем их:
+ service-account.yml
+ role.yml
+ role-binding.yml
+ deploy-operator.yml 

Проверим, что все работает: 
```
kubectl get pvc
NAME                        STATUS   VOLUME                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
backup-mysql-instance-pvc   Bound    backup-mysql-instance-pv   1Gi        RWO                           30m
mysql-instance-pvc          Bound    mysql-instance-pv          1Gi        RWO                           30
```
Заполним базу созданного mysql-instance: 
```
export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}")
###
kubectl exec -it $MYSQLPOD -- mysql -u root -potuspassword -e "CREATE TABLE testX ( id smallint unsigned not null auto_increment, name varchar(20) not null, constraint pk_example primary key (id) );" otus-database
###
kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "INSERT INTO testX ( id, name ) VALUES ( null, 'dataX' );" otus-database
kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "INSERT INTO testX ( id, name ) VALUES ( null, 'dataX2' );" otus-database
kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from testX;" otus-database
```
Вывод при запущенном MySQL:
```
kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database
mysql: [Warning] Using a password on the command line interface can be insecure.
+----+-------------+
| id | name        |
+----+-------------+
|  1 | some data   |
|  2 | some data-2 |
+----+-------------+
```
Удалим mysql-instance:
```
kubectl delete mysqls.otus.homework mysql-instance
```
Теперь `kubectl get pv` показывает, что PV для mysql больше нет, а `kubectl get jobs.batch` показывает
```
kubectl get pvc
NAME                        STATUS        VOLUME                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
backup-mysql-instance-pvc   Bound         backup-mysql-instance-pv   1Gi        RWO                           32m
mysql-instance-pvc          Terminating   mysql-instance-pv          1Gi        RWO                           32m
####
kubectl get jobs.batch
NAME                         COMPLETIONS   DURATION   AGE
backup-mysql-instance-job    1/1           2s         15s
restore-mysql-instance-job   0/1           32m        32m
```

Создадим заново mysql-instance:
``` 
kubectl apply -f deploy/cr.yml
```

Немного подождем и: 
```
export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}")
kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database
mysql: [Warning] Using a password on the command line interface can be insecure.

+----+-------------+
| id | name        |
+----+-------------+
|  1 | some data   |
|  2 | some data-2 |
+----+-------------+

```
### Как проверить работоспособность:
 - см. выше
## PR checklist:
 - [x] Выставлен label с темой домашнего задания
