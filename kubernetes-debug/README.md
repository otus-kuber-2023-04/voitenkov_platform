# Выполнено ДЗ № 13

 - [x] kubectl debug - не работает на Kubernetes v1.24, использовал Ephemeral Containers
 - [x] iptables-tailer
 - [ ] Задание со ⭐ (Исправьте ошибку в нашей сетевой политике, чтобы Netperf снова начал работать)
 - [ ] Задание со ⭐ (Поправьте манифест DaemonSet из репозитория, чтобы в логах отображались имена Podов, а не их IP-адреса)


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
    - default-pool - от 1 до 2     
    
![Yandex.Cloud](/images/hw09-yandex-cloud.png)  

Подробнее по инфраструктурной части см. https://github.com/otus-kuber-2023-04/voitenkov_platform/blob/kubernetes-templating/infrastructure/README.md

## Решение Д/З № 13

### Kubectl-debug

Оригинальный проект https://github.com/aylei/kubectl-debug остановлен в 2020 г. 
См. релизы https://github.com/aylei/kubectl-debug/releases:  
Последняя стабильная версия 0.1.1 не поддерживает Containerd Runtime.  
В следующей (она же последняя в репозитории) версии 0.2.0-rc заявлена поддержка Containerd, но сваливается с ошибкой:  
```shell
$ kubectl-debug nginx --agentless=false
Forwarding from 127.0.0.1:10027 -> 10027
Forwarding from [::1]:10027 -> 10027
Handling connection for 10027
error execute remote, Internal error occurred: error attaching to container: failed to mount /tmp/containerd-mount294894376: no such file or directory
error: Internal error occurred: error attaching to container: failed to mount /tmp/containerd-mount294894376: no such file or directory
E0730 18:34:24.852573   15758 attach.go:52] error attaching to container: failed to mount /tmp/containerd-mount294894376: no such file or directory 
```
Проект форкнул другой разработчик https://github.com/JamesTGrant/kubectl-debug, он выпустил стабильную и единственнную версию 1.0.0, но она тоже не работает.
Выводит ошибку монтирования LXCFS, отключение LXCFS через ключ запуска не помогло:
```shell
$ kubectl-debug --enable-lxcfs=false nginx

2023/07/30 21:32:15 Getting user name from default kubectl context 'yc-k8s-otus-kuber-prod-cluster-1'
2023/07/30 21:32:15 User name 'yc-managed-k8s-catnn7po912e1eov3a83' received from kubectl context
Agent Pod info: [Name:debug-agent-pod-ca6a4052-2f0f-11ee-9a58-00155d0b9f50, Namespace:default, Image:jamesgrantmediakind/debug-agent:latest, HostPort:10027, ContainerPort:10027]
Waiting for pod debug-agent-pod-ca6a4052-2f0f-11ee-9a58-00155d0b9f50 to run...
Forwarding from 127.0.0.1:10027 -> 10027
Forwarding from [::1]:10027 -> 10027
Handling connection for 10027
deleting debug-agent container from pod: nginx
an error occured executing remote command(s), Internal error occurred: error attaching to container: /var/lib/lxc/lxcfs is not a mount point, please run " lxcfs /var/lib/lxc/lxcfs " before debug
error: Internal error occurred: error attaching to container: /var/lib/lxc/lxcfs is not a mount point, please run " lxcfs /var/lib/lxc/lxcfs " before debug
```

### Ephemeral Containers

Сам разработчик ссылается на то, что Kubectl-debug заменен **Ephemeral Containers**, которые включены в Kubernetes как штатный функционал. Так что пытаемся выполнить задание штатными средствами.

Стартуем пустой pause container:  
`kubectl run ephemeral-demo --image=registry.k8s.io/pause:3.1 --restart=Never`

Пытаемся зайти в него и получаем ошибку, так как там нет shell оболочки:
```shell
kubectl exec -it ephemeral-demo -- sh
OCI runtime exec failed: exec failed: container_linux.go:346: starting container process caused "exec: \"sh\": executable file not found in $PATH": unknown
```

Запускаем отладку:
```shell
$ kubectl debug -it ephemeral-demo --image=busybox:1.28 --target=ephemeral-demo
Targeting container "ephemeral-demo". If you don't see processes from this container it may be because the container runtime doesn't support this feature.
Defaulting debug container name to debugger-sbrnp.
If you don't see a command prompt, try pressing enter.
/ # top
Mem: 3234552K used, 4914144K free, 2336K shrd, 76532K buff, 2610632K cached
CPU:  0.9% usr  0.1% sys  0.0% nic 98.8% idle  0.0% io  0.0% irq  0.0% sirq
Load average: 0.00 0.03 0.00 4/428 26
  PID  PPID USER     STAT   VSZ %VSZ CPU %CPU COMMAND
   20     0 root     S     1240  0.0   0  0.0 sh
   26    20 root     R     1236  0.0   1  0.0 top
    1     0 root     S     1020  0.0   1  0.0 /pause
```

Теперь отладим контейнер с Nginx:
```shell
$ kubectl run ephemeral-nginx --image=nginx --restart=Never
$ kubectl debug -it ephemeral-nginx --image=alpine:latest --target=ephemeral-nginx
Targeting container "ephemeral-demo". If you don't see processes from this container it may be because the container runtime doesn't support this feature.
Defaulting debug container name to debugger-drk8c.
If you don't see a command prompt, try pressing enter.
```
Поставим в Ephemeral Container утилиту **strace**:
```shell
/ # apk --update add strace
fetch https://dl-cdn.alpinelinux.org/alpine/v3.18/main/x86_64/APKINDEX.tar.gz
fetch https://dl-cdn.alpinelinux.org/alpine/v3.18/community/x86_64/APKINDEX.tar.gz
(1/6) Installing libbz2 (1.0.8-r5)
(2/6) Installing musl-fts (1.2.7-r5)
(3/6) Installing xz-libs (5.4.3-r0)
(4/6) Installing zstd-libs (1.5.5-r4)
(5/6) Installing libelf (0.189-r2)
(6/6) Installing strace (6.3-r1)
Executing busybox-1.36.1-r0.trigger
OK: 10 MiB in 21 packages
/ # strace ls
execve("/bin/ls", ["ls"], 0x7fffed3ac7f0 /* 14 vars */) = 0
arch_prctl(ARCH_SET_FS, 0x7fce7fc30b48) = 0
set_tid_address(0x7fce7fc30fb8)         = 74
brk(NULL)                               = 0x560471271000
brk(0x560471273000)                     = 0x560471273000
mmap(0x560471271000, 4096, PROT_NONE, MAP_PRIVATE|MAP_FIXED|MAP_ANONYMOUS, -1, 0) = 0x560471271000
mprotect(0x7fce7fc2d000, 4096, PROT_READ) = 0
mprotect(0x560470103000, 16384, PROT_READ) = 0
getuid()                                = 0
ioctl(0, TIOCGWINSZ, {ws_row=51, ws_col=209, ws_xpixel=0, ws_ypixel=0}) = 0
ioctl(1, TIOCGWINSZ, {ws_row=51, ws_col=209, ws_xpixel=0, ws_ypixel=0}) = 0
ioctl(1, TIOCGWINSZ, {ws_row=51, ws_col=209, ws_xpixel=0, ws_ypixel=0}) = 0
stat(".", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
open(".", O_RDONLY|O_LARGEFILE|O_CLOEXEC|O_DIRECTORY) = 3
fcntl(3, F_SETFD, FD_CLOEXEC)           = 0
mmap(NULL, 8192, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7fce7fb95000
getdents64(3, 0x7fce7fb95038 /* 19 entries */, 2048) = 464
lstat("./home", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
lstat("./bin", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
lstat("./mnt", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
lstat("./run", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
lstat("./proc", {st_mode=S_IFDIR|0555, st_size=0, ...}) = 0
lstat("./dev", {st_mode=S_IFDIR|0755, st_size=380, ...}) = 0
lstat("./usr", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
lstat("./root", {st_mode=S_IFDIR|0700, st_size=4096, ...}) = 0
lstat("./sys", {st_mode=S_IFDIR|0555, st_size=0, ...}) = 0
lstat("./sbin", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
lstat("./tmp", {st_mode=S_IFDIR|S_ISVTX|0777, st_size=4096, ...}) = 0
lstat("./srv", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
lstat("./etc", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
lstat("./media", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
lstat("./lib", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
lstat("./var", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
lstat("./opt", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
getdents64(3, 0x7fce7fb95038 /* 0 entries */, 2048) = 0
close(3)                                = 0
munmap(0x7fce7fb95000, 8192)            = 0
ioctl(1, TIOCGWINSZ, {ws_row=51, ws_col=209, ws_xpixel=0, ws_ypixel=0}) = 0
writev(1, [{iov_base="\33[1;34mbin\33[m    \33[1;34mdev\33[m  "..., iov_len=285}, {iov_base="\n", iov_len=1}], 2bin    dev    etc    home   lib    media  mnt    opt    proc   root   run    sbin   srv    sys
 tmp    usr    var
) = 286
exit_group(0)                           = ?
+++ exited with 0 +++
```

### iptables-tailer

Устанавливаю CRD. Этот проект прекратил свое развитие даже в 2018 г. Переписываю CRD с API v1beta1 на v1, деплою.
Запускаю тест (кластер был без Calico):
```shell
$ k describe netperf
Name:         example
Namespace:    default
Labels:       <none>
Annotations:  <none>
API Version:  app.example.com/v1alpha1
Kind:         Netperf
Metadata:
  Creation Timestamp:  2023-10-09T20:35:49Z
  Generation:          4
  Resource Version:    14375
  UID:                 0d492197-9c79-46a0-a3ad-9c2e0d565153
Spec:
  Client Node:
  Server Node:
Status:
  Client Pod:          netperf-client-9c2e0d565153
  Server Pod:          netperf-server-9c2e0d565153
  Speed Bits Per Sec:  9872.22
  Status:              Done
Events:                <none>
```
Однако с установленным Calico netperf-client не видит порт netperf-server, используемый для теста, но IP пингуются, сетевая политика еще не включена.
Проверяю тогда на пинге. Включаю сетевую политику, вижу, что пинг блокируется
Также установил kube-iptables-tailer. Выполнил кастомизацию согласно методичке, но в Ivents Kubernetes и в Ivents Netperf подов ничего не появилось.
Так что как работать с сетевыми политиками понятно, как мерить производительность Netperf'ом тоже понятно. Как запустить тест Netperf при включенном Calico или добиться доставки логов kube-iptables-tailer непонятно.

### Удаление инфраструктуры

Для удаления **Production** инфраструктуры, запускаем пайплайн, а в нем вручную запускаем Destroy Job, инфраструктура удаляется.
Для удаления **Development** инфраструктуры, пайплайн не получится задействовать, так как собственно в ней запущен Gitlab Runner. Запускаем Terraform Destroy в каталоге проекта Infrastructure/3-Development

## Как проверить работоспособность:
 - см. выше
## PR checklist:
 - [x] Выставлен label с темой домашнего задания
