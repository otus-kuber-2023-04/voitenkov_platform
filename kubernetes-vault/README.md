# Выполнено ДЗ № 11 - Хранилище секретов для приложений. Vault

 - [x] Основное ДЗ
 - [x] Задание со ⭐ (Реализовать доступ к Vault через https)
 - [x] Задание сo ⭐ (Настроить autounseal)
 - [x] Задание сo ⭐ (Настроить lease временных секретов для доступа к БД)
 

## В процессе сделано:

### Подготовка инфраструктуры

Использованы мои наработки из дипломного проекта по курсу **DevOps для эксплуатации и разработки**.

Кластер Kubernetes поднимается в облаке Yandex Cloud. Вся инфраструктура разворачивается по методолгии IaaC с использованием Terraform, **Production** окружение разворачивается после запуска pipeline в GitLab.
Репозиторий GitLab можно посмотреть https://gitlab.com/voitenkov/microservices-demo :
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
  - compute инстанс (виртуальная машина) с предустановленным через UserData template-file набором утилит для DevOp-инженера (yandex cli, kubectl, helm, go, etc.)      
8. Ресурсы **Production** окружения проекта:
  - сеть и подсеть
  - сервисные аккаунты
  - группы безопасности
  - Managed Kubernetes cluster
  - зона и записи DNS
    
    В кластере Managed Kubernetes развернуты 1 нодгруппа с включенным автоскалированием нод:
    - default-pool - от 3 до 4     
    
![Yandex.Cloud](/images/hw09-yandex-cloud.png)  

Подробнее по инфраструктурной части см. https://github.com/otus-kuber-2023-04/voitenkov_platform/blob/kubernetes-templating/infrastructure/README.md

## Решение Д/З № 11

### Установка Hashicorp Vault + Consul HA 

Vault можно установить с интегрированной базой данных, работающей в режиме HA по протоколу RAFT. 
Но мы не ищем легких путей, мы поставим еще и Consul, также в режиме HA на 3 Kubernetes нодах, и настроим его как бэкенд для Vault.

```shell
$ git clone https://github.com/hashicorp/consul-helm.git
$ helm upgrade --install consul consul-helm -f consul.values.yaml --atomic
$ git clone https://github.com/hashicorp/vault-helm.git
$ helm upgrade --install vault vault-helm -f vault.values.yaml --atomic
```
Получаем следующее:
```shell
$ kubectl get pods -o wide
NAME                                    READY   STATUS    RESTARTS   AGE     IP             NODE                        NOMINATED NODE   READINESS GATES
consul-consul-6jjz2                     1/1     Running   0          7h      10.96.128.2    cl15osnu0991flfjcnhq-yhyq   <none>           <none>
consul-consul-7nnh4                     1/1     Running   0          6h59m   10.96.129.2    cl15osnu0991flfjcnhq-amal   <none>           <none>
consul-consul-server-0                  1/1     Running   0          6h50m   10.96.129.6    cl15osnu0991flfjcnhq-amal   <none>           <none>
consul-consul-server-1                  1/1     Running   0          6h58m   10.96.130.6    cl15osnu0991flfjcnhq-oces   <none>           <none>
consul-consul-server-2                  1/1     Running   0          7h      10.96.128.6    cl15osnu0991flfjcnhq-yhyq   <none>           <none>
consul-consul-xshbq                     1/1     Running   0          6h59m   10.96.130.3    cl15osnu0991flfjcnhq-oces   <none>           <none>
vault-0                                 1/1     Running   0          6h50m   10.96.128.7    cl15osnu0991flfjcnhq-yhyq   <none>           <none>
vault-1                                 1/1     Running   0          6h41m   10.96.130.8    cl15osnu0991flfjcnhq-oces   <none>           <none>
vault-2                                 1/1     Running   0          6h59m   10.96.129.4    cl15osnu0991flfjcnhq-amal   <none>           <none>
vault-agent-injector-6549d85b8f-r2gg5   1/1     Running   0          6h50m   10.96.130.7    cl15osnu0991flfjcnhq-oces   <none>           <none>
```

#### Инициализация Vault

Для удобства настроим alias:
```shell
$ alias vault='kubectl exec -it vault-0 -- vault'
```
Vault не инициализирован и запечатан:
```shell
$ vault status
Key                Value
---                -----
Seal Type          shamir
Initialized        false
Sealed             true
Total Shares       0
Threshold          0
Unseal Progress    0/0
Unseal Nonce       n/a
Version            1.14.0
Build Date         2023-06-19T11:40:23Z
Storage Type       consul
HA Enabled         true
command terminated with exit code 2
```
Инициализируем Vault и распечатываем первый хост:
```shell
$ vault operator init -key-shares=1 -key-threshold=1 -format=json > cluster-keys.json
$ VAULT_UNSEAL_KEY=$(cat cluster-keys.json | jq -r ".unseal_keys_b64[]")
$ vault operator unseal $VAULT_UNSEAL_KEY
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    1
Threshold       1
Version         1.14.0
Build Date      2023-06-19T11:40:23Z
Storage Type    consul
Cluster Name    vault-cluster-689b48c2
Cluster ID      406b2cc8-0946-b761-9fcf-7a8fe9c118a6
HA Enabled      true
HA Cluster      https://vault-0.vault-internal:8201
HA Mode         active
Active Since    2023-07-20T23:13:11.20099792Z
```
Распечатываем оставшиеся 2 хоста:
```shell
$ kubectl exec vault-1 -- vault operator unseal $VAULT_UNSEAL_KEY
Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
...
HA Mode                standby
Active Node Address    http://10.96.130.8:8200

$ kubectl exec vault-2 -- vault operator unseal $VAULT_UNSEAL_KEY
Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
...
HA Mode                standby
Active Node Address    http://10.96.129.4:8200
```
Проверим статус и конфигурацию сервера:
```shell
$ vault status
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    1
Threshold       1
Version         1.14.0
Build Date      2023-06-19T11:40:23Z
Storage Type    consul
Cluster Name    vault-cluster-58bcc1dc
Cluster ID      b0cfa2ed-3a90-cf62-1e18-e31a909206ca
HA Enabled      true
HA Cluster      https://vault-0.vault-internal:8201
HA Mode         active
Active Since    2023-07-22T15:16:45.528516586Z

$ kubectl logs vault-0
==> Vault server configuration:
             Api Address: http://10.96.128.7:8200
                     Cgo: disabled
         Cluster Address: https://vault-0.vault-internal:8201
...
              Go Version: go1.20.5
              Listener 1: tcp (addr: "[::]:8200", cluster address: "[::]:8201", max_request_duration: "1m30s", max_request_size: "33554432", tls: "disabled")
               Log Level:
                   Mlock: supported: true, enabled: false
           Recovery Mode: false
                 Storage: consul (HA available)
                 Version: Vault v1.14.0, built 2023-06-19T11:40:23Z  
==> Vault server started! Log data will stream in below:
2023-07-22T16:02:17.171Z [INFO]  core.cluster-listener.tcp: starting listener: listener_address=[::]:8201
2023-07-22T16:02:17.171Z [INFO]  core.cluster-listener: serving cluster requests: cluster_listen_address=[::]:8201
2023-07-22T16:02:17.171Z [INFO]  core: vault is unsealed
2023-07-22T16:02:17.171Z [INFO]  core: entering standby mode
```

####  Настройка аутентификации (Kubernetes JWT)

Логинимся:
```shell
$ vault login
Token (will be hidden):
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.
Key                  Value
---                  -----
token                hvs.jecIRCCuOp7h2CCykIIbYUys
token_accessor       WWC6SqpqTFiyljgx4xIKwPoY
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]
```
Список включенных методов аутентификации:
```shell
$ vault auth list
Path      Type     Accessor               Description                Version
----      ----     --------               -----------                -------
token/    token    auth_token_03d6dc95    token based credentials    n/a
```
### Работа с секретами

Заведем секреты:
```shell
$ vault secrets enable --path=otus kv
Success! Enabled the kv secrets engine at: otus/

$ vault secrets list --detailed
Path          Plugin       Accessor              Default TTL    Max TTL    Force No Cache    Replication    Seal Wrap    External Entropy Access    Options    Description
         UUID                                    Version    Running Version          Running SHA256    Deprecation Status
----          ------       --------              -----------    -------    --------------    -----------    ---------    -----------------------    -------    -----------
         ----                                    -------    ---------------          --------------    ------------------
cubbyhole/    cubbyhole    cubbyhole_5bb34fd6    n/a            n/a        false             local          false        false                      map[]      per-token private secret storage
         196f443e-3874-fec7-eef7-a0397c77aa65    n/a        v1.14.0+builtin.vault    n/a               n/a
identity/     identity     identity_f2180ab6     system         system     false             replicated     false        false                      map[]      identity store
         f1059a69-a8f1-2160-667b-241053473208    n/a        v1.14.0+builtin.vault    n/a               n/a
otus/         kv           kv_1a7a1a9c           system         system     false             replicated     false        false                      map[]      n/a
         78c91a3c-a539-c4a6-f060-a75d06a02b7b    n/a        v0.15.0+builtin          n/a               supported
sys/          system       system_4ba1c8e7       n/a            n/a        false             replicated     true         false                      map[]      system endpoints used for control, policy and debugging    6f333680-f08a-269a-39ed-c21d0fcebf70    n/a        v1.14.0+builtin.vault    n/a               n/a

$ vault kv put otus/otus-ro/config username='otus' password='asajkjkahs'
Success! Data written to: otus/otus-ro/config

$ vault kv put otus/otus-rw/config username='otus' password='asajkjkahs'
Success! Data written to: otus/otus-rw/config

$ vault read otus/otus-ro/config
Key                 Value
---                 -----
refresh_interval    768h
password            asajkjkahs
username            otus

$ vault kv get otus/otus-rw/config
====== Data ======
Key         Value
---         -----
password    asajkjkahs
username    otus
```

### Аутентификация Kubernetes

Включаем аутентификацию Kubernetes
```shell
vault auth enable kubernetes
vault auth list
Path           Type          Accessor                    Description                Version
----           ----          --------                    -----------                -------
kubernetes/    kubernetes    auth_kubernetes_dbc80b5b    n/a                        n/a
token/         token         auth_token_03d6dc95         token based credentials    n/a
```
Создаем сервисный аккаунт, роль и секрет. Для Kubernetes, начиная с версии 1.24, требуется создавать секрет отдельно от сервисного аккаунта.
```shell
$ kubectl apply --filename vault-auth-service-account.yaml
clusterrolebinding.rbac.authorization.k8s.io/role-tokenreview-binding created
serviceaccount/vault-auth created
secret/vault-auth-secret created
```
Настроим переменные среды. Методичка устарела, делаем по документации Hashicorp:
```shell
$ export SA_SECRET_NAME=$(kubectl get secrets --output=json    | jq -r '.items[].metadata | select(.name|startswith("vault-auth-")).name')
$ export SA_JWT_TOKEN=$(kubectl get secret $SA_SECRET_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)
$ export SA_CA_CRT=$(kubectl config view --raw --minify --flatten   --output 'jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 --decode)
$ export K8S_HOST=$(kubectl config view --raw --minify --flatten   --output 'jsonpath={.clusters[].cluster.server}')

$ vault write auth/kubernetes/config token_reviewer_jwt="$SA_JWT_TOKEN" kubernetes_host="$K8S_HOST" kubernetes_ca_cert="$SA_CA_CRT" issuer="https://kubernetes.default.svc.cluster.local"
Success! Data written to: auth/kubernetes/config
```            
Создаем политику и роль в vault:
```shell
kubectl cp --no-preserve=false otus-policy.hcl vault-0:/tmp
vault policy write otus-policy /tmp/otus-policy.hcl
vault write auth/kubernetes/role/otus bound_service_account_names=vault-auth bound_service_account_namespaces=default token_policies=otus-policy ttl=24h
```
Проверим как работает аутентификация. Для этого деплоим тестовый под с привязанным сервис-аккаунтом:
```shell
kubectl apply --filename vault-test-pod.yaml
```
Заходим в тестовый под, ставим curl и jq, получаем токен:
```shell
kubectl exec -it vault-test -- sh
# curl http://vault:8200/v1/sys/seal-status
{"type":"shamir","initialized":true,"sealed":false,"t":1,"n":1,"progress":0,"nonce":"","version":"1.14.0","build_date":"2023-06-19T11:40:23Z","migration":false,"cluster_name":"vault-cluster-58bcc1dc","cluster_id":"b0cfa2ed-3a90-cf62-1e18-e31a909206ca","recovery_seal":false,"storage_type":"consul"}
# export VAULT_ADDR=http://vault:8200
# KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
# curl --request POST --data '{"jwt": "'$KUBE_TOKEN'", "role": "otus"}' $VAULT_ADDR/v1/auth/kubernetes/login | jq 
# TOKEN=$(curl -k -s --request POST --data '{"jwt": "'$KUBE_TOKEN'", "role": "otus"}' $VAULT_ADDR/v1/auth/kubernetes/login | jq '.auth.client_token' | awk -F\" '{print $2}')
```
Проверяем чтение и запись секретов:
```shell
# curl -s  --header "X-Vault-Token:${TOKEN}" $VAULT_ADDR/v1/otus/otus-ro/config | jq
{
  "request_id": "862a196c-1530-e71b-a671-8e4dd70f083a",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 2764800,
  "data": {
    "password": "asajkjkahs",
    "username": "otus"
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}
# curl --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:${TOKEN}" $VAULT_ADDR/v1/otus/otus-ro/config 
{"errors":["1 error occurred:\n\t* permission denied\n\n"]}
# curl --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:${TOKEN}" $VAULT_ADDR/v1/otus/otus-rw/config
{"errors":["1 error occurred:\n\t* permission denied\n\n"]}
# curl --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:${TOKEN}" $VAULT_ADDR/v1/otus/otus-rw/config1
```
Чтение работает, в отличии от обновления.  
Вопрос: Почему мы смогли записать otus-rw/config1 но не смогли otus-rw/config?  
Ответ: Потому что в политиках определены правила

```shell
path "otus/otus-ro/*" {
      capabilities = ["read", "list"]
}
path "otus/otus-rw/*" {
      capabilities = ["read", "create", "list"]
}
```
Правила определяют, что я могу создавать ключи, а менять не могу. Чтобы это исправить надо изменить правило:
```shell
path "otus/otus-ro/*" {
     capabilities = ["read", "list"]
}
path "otus/otus-rw/*" {
     capabilities = ["read", "create", "list", "update"]
}
```
Изменяем политику, проверяем, теперь ключ обновляется:
```shell
# curl --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:${TOKEN}" $VAULT_ADDR/v1/otus/otus-rw/config1
# curl -s --header "X-Vault-Token:${TOKEN}" $VAULT_ADDR/v1/otus/otus-rw/config 1| jq
{
  "request_id": "2bc507c2-2f6a-a798-4a8d-630f704c99ab",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 2764800,
  "data": {
    "bar": "baz"
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}
```

### Use case использования аутентификации через Kubernetes

Исправляем configmap **vault-agent**, деплоим **vault-agent** и тестовый под.
```shell
$ kubectl create configmap example-vault-agent-config --from-file=./configs-k8s/
$ kubectl get configmap example-vault-agent-config -o yaml
```
Проверяем. Init-контейнер с Vault-agent сходил в Vault, достал секреты и записал их на стартовой странице Nginx:
```shell
$ kubectl exec -it vault-agent-example -- sh
Defaulted container "nginx-container" out of: nginx-container, vault-agent (init)
# cat /usr/share/nginx/html/index.html
<html>
<body>
<p>Some secrets:</p>
<ul>
<li><pre>username: otus</pre></li>
<li><pre>password: asajkjkahs</pre></li>
</ul>

</body>
</html>
```
## CA на базе vault
                
Включим PKI:
```shell
$ vault secrets enable pki
$ vault secrets tune -max-lease-ttl=87600h pki
$ vault write -field=certificate pki/root/generate/internal common_name="vault.voytenkov.ru" ttl=87600h > CA_cert.crt
```
Пропишем URL-ы и СА для отозванных сертификатов:
```shell
$ vault write pki/config/urls issuing_certificates="http://vault:8200/v1/pki/ca" crl_distribution_points="http://vault:8200/v1/pki/crl"
```
Создадим промежуточный сертификат и сохраним все сертификаты CA в Vault:
```shell
$ vault secrets enable --path=pki_int pki
$ vault secrets tune -max-lease-ttl=87600h pki_int
$ vault write -format=json pki_int/intermediate/generate/internal common_name="vault.voytenkov.ru Intermediate Authority" | jq -r '.data.csr' > pki_intermediate.csr
$ kubectl cp pki_intermediate.csr vault-0:/tmp
$ vault write -format=json pki/root/sign-intermediate csr=@/tmp/pki_intermediate.csr format=pem_bundle ttl="43800h" | jq -r '.data.certificate' > intermediate.cert.pem
$ kubectl cp intermediate.cert.pem vault-0:/tmp
# vault write pki_int/intermediate/set-signed certificate=@/tmp/intermediate.cert.pem
```
Создадим роль для выдачи сертификатов:
```shell
$ vault write pki_int/roles/vault-voytenkov-ru    allowed_domains="vault.voytenkov.ru" allow_subdomains=true max_ttl="720h"
```
Выпустим сертификат:
```
vault write pki_int/issue/vault-voytenkov-ru common_name="*.vault.voytenkov.ru" ttl="24h"
Key                 Value
---                 -----
ca_chain            [-----BEGIN CERTIFICATE-----
MIIDrDCCApSgAwIBAgIUHUhlI/8RJyiFvJ31Flgge6iOCmUwDQYJKoZIhvcNAQEL
...
ZmNEl6HBkYNQpIt6YHe7HrsEqTypyImNZEBQzs2++UQ=
-----END CERTIFICATE----- -----BEGIN CERTIFICATE-----
MIIDTDCCAjSgAwIBAgIULJs7t2kbpAWnSf8ot6l2yRcx05AwDQYJKoZIhvcNAQEL
..
iUqxeEt73IJG7cZiGTYQdQx3y3XTeQDYMc+6jGwSL8E=
-----END CERTIFICATE-----]
certificate         -----BEGIN CERTIFICATE-----
MIIDdTCCAl2gAwIBAgIUMD1kWThYDW8IndgEu5bKQ7GB3LUwDQYJKoZIhvcNAQEL
...
/91wZx5cp6ndbviqKoyWhDTTw8MBkvpacw==
-----END CERTIFICATE-----
expiration          1690149533
issuing_ca          -----BEGIN CERTIFICATE-----
MIIDrDCCApSgAwIBAgIUHUhlI/8RJyiFvJ31Flgge6iOCmUwDQYJKoZIhvcNAQEL
...
ZmNEl6HBkYNQpIt6YHe7HrsEqTypyImNZEBQzs2++UQ=
-----END CERTIFICATE-----
private_key         -----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEA4ja58K4uTQBkwcnYNuPXt79JtBBDm56/+kWYSDJUDb7b7Fcb
...
nn3RSAm66wMWe94+6iIh/5Z/rKONBjuxBfHkmlTn3N1z63VXVhwflIY=
-----END RSA PRIVATE KEY-----
private_key_type    rsa
serial_number       30:3d:64:59:38:58:0d:6f:08:9d:d8:04:bb:96:ca:43:b1:81:dc:b5
```
Отзовем сертификат:
```shell
$ vault write pki_int/revoke serial_number="30:3d:64:59:38:58:0d:6f:08:9d:d8:04:bb:96:ca:43:b1:81:dc:b5"
Key                        Value
---                        -----
revocation_time            1690063265
revocation_time_rfc3339    2023-07-22T22:01:05.170178347Z
state                      revoked
```

## Задание со ⭐ Реализовать доступ к Vault через https

Выполняем все действия согласно инструкции [https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-minikube-tls](https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-minikube-tls)  
Получаем кластер Vault с включенным TLS:  
```shell
$ kubectl exec -n $VAULT_K8S_NAMESPACE vault-0 -- vault operator raft list-peers
Node       Address                        State       Voter
----       -------                        -----       -----
vault-0    vault-0.vault-internal:8201    leader      true
vault-1    vault-1.vault-internal:8201    follower    true
vault-2    vault-2.vault-internal:8201    follower    true

$ kubectl exec -n $VAULT_K8S_NAMESPACE vault-0 -- vault status
Key                     Value
---                     -----
Seal Type               shamir
Initialized             true
Sealed                  false
Total Shares            1
Threshold               1
Version                 1.14.0
Build Date              2023-06-19T11:40:23Z
Storage Type            raft
Cluster Name            vault-cluster-73f4af4c
Cluster ID              e363c282-b282-2f1d-a354-5c5318840b8b
HA Enabled              true
HA Cluster              https://vault-0.vault-internal:8201
HA Mode                 active
Active Since            2023-10-05T22:36:32.066881126Z
Raft Committed Index    40
Raft Applied Index      40

```
Сохраням секрет:
```shell
$ kubectl exec -n $VAULT_K8S_NAMESPACE -it vault-0 -- /bin/sh
/ $ vault secrets enable -path=secret kv-v2
Success! Enabled the kv-v2 secrets engine at: secret/
/ $ vault kv put secret/tls/apitest username="apiuser" password="supersecret"
===== Secret Path =====
secret/data/tls/apitest

======= Metadata =======
Key                Value
---                -----
created_time       2023-10-05T22:44:01.738625233Z
custom_metadata    <nil>
deletion_time      n/a
destroyed          false
version            1
/ $ vault kv get secret/tls/apitest
===== Secret Path =====
secret/data/tls/apitest

======= Metadata =======
Key                Value
---                -----
created_time       2023-10-05T22:44:01.738625233Z
custom_metadata    <nil>
deletion_time      n/a
destroyed          false
version            1

====== Data ======
Key         Value
---         -----
password    supersecret
username    apiuser
/ $ exit
```

Читаем секрет:  
```shell
$ curl --cacert $WORKDIR/vault.ca \
   --header "X-Vault-Token: $CLUSTER_ROOT_TOKEN" \
   https://127.0.0.1:8200/v1/secret/data/tls/apitest | jq .data.data
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   347  100   347    0     0   2139      0 --:--:-- --:--:-- --:--:--  2155
{
  "password": "supersecret",
  "username": "apiuser"
}
```

## Задание сo ⭐ (Настроить autounseal)

Настраиваем провайдера autounseal в Yandex Cloud, действуем по инструкции [https://cloud.yandex.ru/docs/kms/tutorials/vault-secret#setup](https://cloud.yandex.ru/docs/kms/tutorials/vault-secret#setup)  
Терраформом деплоим симметричный ключа KMS, сохраняем его ID. Также деплоим сервисный аккаунт с правами kms.keys.encrypterDecrypter и создаем для него IAM-key.
Создаем из IAM-key секрет в Kubernetes:  
`kubectl create secret generic vault-yc-kms  -n vault  --from-file=key.json= ./.secrets/vault-key.json`  
Добавляем в конфигурацию Vault параметры autounseal:
```shell
seal "yandexcloudkms" {
     kms_key_id               = "abjn0c3psqufihncssam"
     service_account_key_file = "/usr/vault/yc-kms/key.json"
}
```
С HA конфигурацией не получилось, запускается процесс миграции на Autоunseal, сервер инициализируется автоматически, но по прежнему Sealed. Запустить ручной Unseal тоже не дает из-за настроенного autounseal.
```shell
$ kubectl exec -n vault vault-0 -- vault status
Key                           Value
---                           -----
Recovery Seal Type            shamir
Initialized                   true
Sealed                        true
Total Recovery Shares         1
Threshold                     1
Unseal Progress               0/1
Unseal Nonce                  n/a
Seal Migration in Progress    true
Version                       1.14.1+yckms
Build Date                    2023-08-01T20:32:02Z
Storage Type                  raft
HA Enabled                    true
```
Здесь пишут [https://github.com/hashicorp/vault/issues/6810](https://github.com/hashicorp/vault/issues/6810), что надо потушить другие сервера в кластере, и только после этого успешно завершится миграция первого.

Деплою Vault в standalone конфигурации, теперь все получается:
```shell
$ kubectl exec -n vault vault-0 -- vault status
Key                      Value
---                      -----
Recovery Seal Type       yandexcloudkms
Initialized              false
Sealed                   true
Total Recovery Shares    0
Threshold                0
Unseal Progress          0/0
Unseal Nonce             n/a
Version                  1.14.1+yckms
Build Date               2023-08-01T20:32:02Z
Storage Type             file
HA Enabled               false
```
Все равно Vault надо инициализировать руками, но ключ он берет с Yandex KMS:
```shell
$ kubectl exec -n vault vault-0 -- vault operator init
Recovery Key 1: YRzp1d3o0RpzQn3o/FM/9aUMtR+n23hstz6pckURluAY
Recovery Key 2: w5P6cx7dZdJRsoY0vFV5kRAjVZkgFhIWQ/+KVxVBQB6L
Recovery Key 3: f10lneZFtZrazJpl15cYzUiToUkqgFP9bQs3XS0RGd3C
Recovery Key 4: XfPA/nVK69BgoeKHJ0iU66gaFbXzHHNX2I5xfcJZa7J6
Recovery Key 5: gFakg8sPlU5ZNTdLY2vZ6wxt7xYG5sF74wTaEjCc1Ylt

Initial Root Token: hvs.8ZnAKJlSNdjWvGEmYyvNpNKb

Success! Vault is initialized

Recovery key initialized with 5 key shares and a key threshold of 3. Please
securely distribute the key shares printed above.
```

Распечатал не Unseal, а Recovery ключи, значит все корректно прошло. Проверяем:
```shell
$ kubectl exec -n vault vault-0 -- vault status
Key                      Value
---                      -----
Recovery Seal Type       shamir
Initialized              true
Sealed                   false
Total Recovery Shares    5
Threshold                3
Version                  1.14.1+yckms
Build Date               2023-08-01T20:32:02Z
Storage Type             file
Cluster Name             vault-cluster-7468bf0e
Cluster ID               3efa28e3-5fbc-dfe1-f014-d5d2d649a53b
HA Enabled               false
```

## Задание сo ⭐ (Настроить lease временных секретов для доступа к БД)

Для примера настроим динамически изменяемые секреты для MySQL. Действуем по инструкции [https://developer.hashicorp.com/vault/docs/secrets/databases/mysql-maria](https://developer.hashicorp.com/vault/docs/secrets/databases/mysql-maria)

Включаем движок database:  
```shell
$ vault secrets enable database
Success! Enabled the database secrets engine at: database/
```
Деплоим MySQl здесь же в кластере:
```shell
$ helm install mysql oci://registry-1.docker.io/bitnamicharts/mysql
Pulled: registry-1.docker.io/bitnamicharts/mysql:9.12.3
Digest: sha256:d0c52a9e2b892a9385c263b1785c338e4fe8175ada662e0737df4b25d4bb1d82
NAME: mysql
LAST DEPLOYED: Sat Oct  7 02:49:23 2023
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
CHART NAME: mysql
CHART VERSION: 9.12.3
APP VERSION: 8.0.34
```
Конфигурируем плагин подключения к серверу MySQL:
```shell
$ vault write database/config/my-mysql-database \
    plugin_name=mysql-database-plugin \
    connection_url="{{username}}:{{password}}@tcp(mysql.default.svc.cluster.local:3306)/" \
    allowed_roles="my-role" \
    username="root" \
    password="0RnSuOxqn4"
Success! Data written to: database/config/my-mysql-database
```
Настраиваем роль:
```shell
$  vault write database/roles/my-role \
    db_name=my-mysql-database \
    creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';" \
    default_ttl="1h" \
    max_ttl="24h"
Success! Data written to: database/roles/my-role
```
Генерируем временные credentials:
```shell
$ vault read database/creds/my-role
Key                Value
---                -----
lease_id           database/creds/my-role/FT8Z3Tw6L2iTnOxOVJpp9vA4
lease_duration     1h
lease_renewable    true
password           22R-GPXWVzYsAuvIxvvO
username           v-root-my-role-WEELOmBg5RqUNgpHY
```
Подключаемся к MySQL под сгенерированными credentials:
```shell
mysql -h 127.0.0.1 -uv-root-my-role-WEELOmBg5RqUNgpHY -p"22R-GPXWVzYsAuvIxvvO"
mysql: [Warning] Using a password on the command line interface can be insecure.
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 460
Server version: 8.0.34 Source distribution
```
Смотрим свои права:
```shell
mysql> SHOW GRANTS;
+---------------------------------------------------------------+
| Grants for v-root-my-role-WEELOmBg5RqUNgpHY@%                 |
+---------------------------------------------------------------+
| GRANT SELECT ON *.* TO `v-root-my-role-WEELOmBg5RqUNgpHY`@`%` |
+---------------------------------------------------------------+
1 row in set (0.13 sec)
```
Меняем credentials:
```shell
$ vault read database/creds/my-role
Key                Value
---                -----
lease_id           database/creds/my-role/FXlFiqAWHIi7WpFNEGsbQ43B
lease_duration     1h
lease_renewable    true
password           v54yx-zLW-7lyDrg-dAw
username           v-root-my-role-DmudG5PGnDEXGZ4it
```
Заходим под новыми credentials. Все работает, в базу пускает, пользователь изменился:
```shell
$ mysql -h 127.0.0.1 -uv-root-my-role-DmudG5PGnDEXGZ4it -p"v54yx-zLW-7lyDrg-dAw"
mysql: [Warning] Using a password on the command line interface can be insecure.
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 599
Server version: 8.0.34 Source distribution

mysql> SHOW GRANTS;
+---------------------------------------------------------------+
| Grants for v-root-my-role-DmudG5PGnDEXGZ4it@%                 |
+---------------------------------------------------------------+
| GRANT SELECT ON *.* TO `v-root-my-role-DmudG5PGnDEXGZ4it`@`%` |
+---------------------------------------------------------------+
1 row in set (0.04 sec)
```


### Удаление инфраструктуры

Для удаления **Production** инфраструктуры, запускаем пайплайн, а в нем вручную запускаем Destroy Job, инфраструктура удаляется.
Для удаления **Development** инфраструктуры, пайплайн не получится задействовать, так как собственно в ней запущен Gitlab Runner. Запускаем Terraform Destroy в каталоге проекта Infrastructure/3-Development

## Как проверить работоспособность:
 - см. выше
## PR checklist:
 - [x] Выставлен label с темой домашнего задания
