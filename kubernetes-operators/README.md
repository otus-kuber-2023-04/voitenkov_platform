# Выполнено ДЗ № 8

 - [x] 🐍 Основное ДЗ
 - [x] 🐍 Задание со ⭐ (1)
 - [x] 🐍 Задание сo ⭐ (2)

## В процессе сделано:
- кластер поднимается средствами Minikube
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

## 🐍 Задание со 🌟 (1)

В коде mysql-operator.py добавил в код функции переменную msg в зависимости от успешности restore-job и вывод этой переменной, которая попадает в Status объекта
```py
    # Пытаемся восстановиться из backup
    try:
        api = kubernetes.client.BatchV1Api()
        api.create_namespaced_job('default', restore_job)
        msg = "mysql-instance created with restore-job" 
    except kubernetes.client.rest.ApiException:
        msg = "mysql-instance created without restore-job" 
        pass

    return {'Message': msg, 'mysql-instance': name}
```  
Проверяем значение `Status` экземпляра mysql:
```shell
$ kubectl describe mysqls.otus.homework mysql-instance
Name:         mysql-instance
Namespace:    default
Labels:       <none>
Annotations:  kopf.zalando.org/last-handled-configuration:
                {"spec":{"database":"otus-database","image":"mysql:5.7","password":"otuspassword","storage_size":"1Gi"}}
API Version:  otus.homework/v1
Kind:         MySQL
Metadata:
  Creation Timestamp:  2023-09-07T21:37:49Z
  Finalizers:
    kopf.zalando.org/KopfFinalizerMarker
  Generation:        2
  Resource Version:  534
  UID:               67158dd9-b2b9-4991-924d-5f71e6e8edba
Spec:
  Database:      otus-database
  Image:         mysql:5.7
  Password:      otuspassword
  storage_size:  1Gi
Status:
  mysql_on_create:
    Message:           mysql-instance created with restore-job
    Mysql - Instance:  mysql-instance
Events:
  Type    Reason   Age   From  Message
  ----    ------   ----  ----  -------
  Normal  Logging  47s   kopf  Creation is processed: 1 succeeded; 0 failed.
  Normal  Logging  47s   kopf  Handler 'mysql_on_create' succeeded.
```

## 🐍 Задание со 🌟 (2)

Реализовал в коде контролера как обработку события обновления через декоратор `@kopf.on.update`:  
```py
@kopf.on.update('otus.homework', 'v1', 'mysqls')
# Функция, которая будет запускаться при изменении объектов тип MySQL:
def mysql_on_update(body, spec, status, **kwargs):
    name = status['mysql_on_create']['mysql-instance']
    image = body['spec']['image']
    password = spec.get('password', None)
    database = body['spec']['database']

    # Генерируем JSON манифесты для деплоя
    deployment = render_template('mysql-deployment.yml.j2', {
        'name': name,
        'image': image,
        'password': password,
        'database': database})

    api = kubernetes.client.CoreV1Api()

    # Создаем mysql Deployment:
    api = kubernetes.client.AppsV1Api()
    api.patch_namespaced_deployment(name,'default', deployment)
   
     # Update status 
    return {'Message': 'mysql-instance updated', 'mysql-instance': name}
```

Проверяем, новый пароль: otuspassword-new:
```shell
$ kubectl apply -f deploy/cr.yaml
mysql.otus.homework/mysql-instance configured

$ kubectl describe mysqls.otus.homework mysql-instance
Name:         mysql-instance
Namespace:    default
Labels:       <none>
Annotations:  kopf.zalando.org/last-handled-configuration:
                {"spec":{"database":"otus-database","image":"mysql:5.7","password":"otuspassword-new","storage_size":"1Gi"}}
API Version:  otus.homework/v1
...
  Normal  Logging  37s  kopf  Handler 'mysql_on_update' succeeded.
  Normal  Logging  3s   kopf  Updating is processed: 1 succeeded; 0 failed.
  Normal  Logging  3s   kopf  Handler 'mysql_on_update' succeeded.
```
Проверяем пересозданный под:
```shell
$ kubectl describe pod/mysql-instance-7b98c99c4d-gjgbz
Name:             mysql-instance-7b98c99c4d-gjgbz
Namespace:        default
...
    State:          Running
      Started:      Fri, 08 Sep 2023 00:42:12 +0200
    Ready:          True
    Restart Count:  0
    Environment:
      MYSQL_ROOT_PASSWORD:  otuspassword-new      
```

### Как проверить работоспособность:
 - см. выше
## PR checklist:
 - [x] Выставлен label с темой домашнего задания
