# Выполнено ДЗ № 13 - CSI. Обзор подсистем хранения данных в Kubernetes

 - [x] Основное ДЗ (установить CSI-драйвер и протестировать функционал снапшотов)
 - [x] Задание со ⭐ (развернуть k8s-кластер, к которому добавить хранилище на iSCSI)

# В процессе сделано:

## Подготовка инфраструктуры

Разворачиваем одноузловой Kubernetes в Vagrant: 
```
git clone https://github.com/maniaque/k1s.git
cd k1s/vagrant/single/
vagrant up
vagrant ssh -c 'cat /home/vagrant/.kube/config' > ~/.kube/config
```

## Решение Д/З № 13

### Основное ДЗ (установить CSI-драйвер и протестировать функционал снапшотов)

#### Устанавливаем External Snapshotter и CSI HostPath Driver:
```shell
$ git clone https://github.com/kubernetes-csi/external-snapshotter.git
$ kubectl kustomize client/config/crd | kubectl create -f -
$ kubectl -n kube-system kustomize deploy/kubernetes/snapshot-controller | kubectl create -f -
$ deploy/kubernetes-latest/deploy.sh
```
Проверяем:
```shell
$ kubectl get pods -A
NAMESPACE      NAME                                   READY   STATUS    RESTARTS   AGE
default        csi-hostpath-socat-0                   1/1     Running   0          70s
default        csi-hostpathplugin-0                   8/8     Running   0          70s
kube-flannel   kube-flannel-ds-7hp6z                  1/1     Running   0          38m
kube-system    coredns-565d847f94-jkxtp               1/1     Running   0          38m
kube-system    coredns-565d847f94-rj97s               1/1     Running   0          38m
kube-system    etcd-k1s                               1/1     Running   0          38m
kube-system    kube-apiserver-k1s                     1/1     Running   0          38m
kube-system    kube-controller-manager-k1s            1/1     Running   0          38m
kube-system    kube-proxy-kx29r                       1/1     Running   0          38m
kube-system    kube-scheduler-k1s                     1/1     Running   0          38m
kube-system    snapshot-controller-554544fbbd-jbjql   1/1     Running   0          10m
kube-system    snapshot-controller-554544fbbd-jzwkz   1/1     Running   0          10m
```

Запустим пример:
```shell
for i in ./examples/csi-storageclass.yaml ./examples/csi-pvc.yaml ./examples/csi-app.yaml; do kubectl apply -f $i; done
```
Проверяем: 
```
$ kubectl get pvc
NAME      STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
csi-pvc   Bound    pvc-27f67b8b-0b33-492c-a47e-28234fdb3287   1Gi        RWO            csi-hostpath-sc   18s

$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM             STORAGECLASS      REASON   AGE
pvc-27f67b8b-0b33-492c-a47e-28234fdb3287   1Gi        RWO            Delete           Bound    default/csi-pvc   csi-hostpath-sc            29s

$ kubectl describe pods/my-csi-app
Name:         my-csi-app
Namespace:    default
Priority:     0
Node:         k1s/192.168.56.110
Start Time:   Thu, 27 Jul 2023 00:08:32 +0200
Labels:       <none>
Annotations:  <none>
Status:       Running
IP:           10.244.0.9
IPs:
  IP:  10.244.0.9
Containers:
  my-frontend:
    Container ID:  containerd://e31e9fec7dfe416b15d2e680882ba6d82e6f2df47a1756a02958ece6b6c77dba
    Image:         busybox
    Image ID:      docker.io/library/busybox@sha256:3fbc632167424a6d997e74f52b878d7cc478225cffac6bc977eedfe51c7f4e79
    Port:          <none>
    Host Port:     <none>
    Command:
      sleep
      1000000
    State:          Running
      Started:      Thu, 27 Jul 2023 00:08:39 +0200
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /data from my-csi-volume (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-mkxnq (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             True 
  ContainersReady   True 
  PodScheduled      True 
Volumes:
  my-csi-volume:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  csi-pvc
    ReadOnly:   false
  kube-api-access-mkxnq:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason                  Age   From                     Message
  ----     ------                  ----  ----                     -------
  Warning  FailedScheduling        64s   default-scheduler        0/1 nodes are available: 1 pod has unbound immediate PersistentVolumeClaims. preemption: 0/1 nodes are available: 1 Preemption is not helpful for scheduling.
  Normal   Scheduled               62s   default-scheduler        Successfully assigned default/my-csi-app to k1s
  Normal   SuccessfulAttachVolume  61s   attachdetach-controller  AttachVolume.Attach succeeded for volume "pvc-27f67b8b-0b33-492c-a47e-28234fdb3287"
  Normal   Pulling                 60s   kubelet                  Pulling image "busybox"
  Normal   Pulled                  55s   kubelet                  Successfully pulled image "busybox" in 4.832148496s
  Normal   Created                 55s   kubelet                  Created container my-frontend
  Normal   Started                 55s   kubelet                  Started container my-frontend
```
Самые интересные секции:
- `Containers.my-frontend.Mounts` - в контейнер замонтирован volume my-csi-volume в директорию /data.
- `Volumes` - my-csi-volume - это persistence volume, созданный через dynamic provisioning PVC
- `Events` - можно увидеть, что volume успешно примонтирован.

Проверим как работает HostPath driver. Создадим файл в /data директории внутри конейнера в поде my-csi-app:
```shell
$ kubectl exec -it my-csi-app -- /bin/sh
$ touch /data/test1.txt
```
Проверяем, что файлик появился в нашем контейнере:
```
$ vagrant ssh k1s
vagrant@k1s:~$ sudo find / -name test1.txt
/var/lib/kubelet/pods/94a7db44-5e8d-4d47-9af7-f02201d9b1ad/volumes/kubernetes.io~csi/pvc-27f67b8b-0b33-492c-a47e-28234fdb3287/mount/test1.txt
/var/lib/csi-hostpath-data/f43e908a-2c00-11ee-8004-8afdbff0d9f1/test1.txt
```

Переходим к ДЗ. 

#### Storage Class, dynamic provisioning PVC
Задание:
* Создать StorageClass для CSI Host Path Driver
* Создать объект PVC c именем `storage-pvc`
* Создать объект Pod c именем `storage-pod`
* Хранилище нужно смонтировать в `/data`

```shell
$ kubectl apply -f hw
storageclass.storage.k8s.io/hostpath-class created
pod/storage-pod created
persistentvolumeclaim/storage-pvc created
```
Проверяем:
```shell
$ kubectl get pvc | grep csi
csi-pvc       Bound    pvc-27f67b8b-0b33-492c-a47e-28234fdb3287   1Gi        RWO            csi-hostpath-sc   16m
andy@test:~/git/otus/kubernetes/voitenkov_platform/kubernetes-storage$ k get pv | grep csi
pvc-27f67b8b-0b33-492c-a47e-28234fdb3287   1Gi        RWO            Delete           Bound    default/csi-pvc       csi-hostpath-sc            16m

$ kubectl describe pod/storage-pod
Name:         storage-pod
Namespace:    default
Priority:     0
Node:         k1s/192.168.56.110
Start Time:   Thu, 27 Jul 2023 00:23:24 +0200
Labels:       <none>
Annotations:  <none>
Status:       Running
IP:           10.244.0.10
IPs:
  IP:  10.244.0.10
Containers:
  app:
    Container ID:  containerd://56f3d2a496b250fcd6ce73615ecf80d9948654effee3da076303748f5d20d507
    Image:         bash
    Image ID:      docker.io/library/bash@sha256:1ea30d9b65797fbae4787f6188796e7189371019031958a167423d347d32eada
    Port:          <none>
    Host Port:     <none>
    Command:
      sleep
      10000000
    State:          Running
      Started:      Thu, 27 Jul 2023 00:23:38 +0200
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /data from data-volume (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-jshd5 (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             True 
  ContainersReady   True 
  PodScheduled      True 
Volumes:
  data-volume:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  storage-pvc
    ReadOnly:   false
  kube-api-access-jshd5:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason                  Age    From                     Message
  ----     ------                  ----   ----                     -------
  Warning  FailedScheduling        2m29s  default-scheduler        0/1 nodes are available: 1 persistentvolumeclaim "storage-pvc" not found. preemption: 0/1 nodes are available: 1 Preemption is not helpful for scheduling.
  Normal   Scheduled               2m27s  default-scheduler        Successfully assigned default/storage-pod to k1s
  Normal   SuccessfulAttachVolume  2m27s  attachdetach-controller  AttachVolume.Attach succeeded for volume "pvc-a60daf7c-2982-4d25-8f56-a9d33445a492"
  Normal   Pulling                 2m19s  kubelet                  Pulling image "bash"
  Normal   Pulled                  2m13s  kubelet                  Successfully pulled image "bash" in 5.75318159s
  Normal   Created                 2m13s  kubelet                  Created container app
  Normal   Started                 2m13s  kubelet                  Started container app 
```

#### Протестируем функционал снапшотов:

Создаем тестовый файлик в Volume:
```shell
$ kubectl exec -it storage-pod -- sh
# echo "test" > /data/test1.txt
# cat /data/test1.txt
test
```

Создаем VolumeSnapshotClass и Snapshot нашего PVC
```shell
$ kubectl apply -f snapshot-class.yaml 
volumesnapshotclass.snapshot.storage.k8s.io/hostpath-snapshot-class created

$ kubectl apply -f storage-pvc-snapshot.yaml 
volumesnapshot.snapshot.storage.k8s.io/storage-pvc-snapshot created

$ kubectl describe volumesnapshot storage-pvc-snapshot
Name:         storage-pvc-snapshot
Namespace:    default
Labels:       <none>
Annotations:  <none>
API Version:  snapshot.storage.k8s.io/v1
Kind:         VolumeSnapshot
Metadata:
  Creation Timestamp:  2023-07-30T10:17:08Z
  Finalizers:
    snapshot.storage.kubernetes.io/volumesnapshot-as-source-protection
    snapshot.storage.kubernetes.io/volumesnapshot-bound-protection
  Generation:  1
  Managed Fields:
    API Version:  snapshot.storage.k8s.io/v1
    Fields Type:  FieldsV1
    fieldsV1:
      f:metadata:
        f:annotations:
          .:
          f:kubectl.kubernetes.io/last-applied-configuration:
      f:spec:
        .:
        f:source:
          .:
          f:persistentVolumeClaimName:
        f:volumeSnapshotClassName:
    Manager:      kubectl-client-side-apply
    Operation:    Update
    Time:         2023-07-30T10:17:08Z
    API Version:  snapshot.storage.k8s.io/v1
    Fields Type:  FieldsV1
    fieldsV1:
      f:metadata:
        f:finalizers:
          .:
          v:"snapshot.storage.kubernetes.io/volumesnapshot-as-source-protection":
          v:"snapshot.storage.kubernetes.io/volumesnapshot-bound-protection":
    Manager:      snapshot-controller
    Operation:    Update
    Time:         2023-07-30T10:17:09Z
    API Version:  snapshot.storage.k8s.io/v1
    Fields Type:  FieldsV1
    fieldsV1:
      f:status:
        .:
        f:boundVolumeSnapshotContentName:
        f:creationTime:
        f:readyToUse:
        f:restoreSize:
    Manager:         snapshot-controller
    Operation:       Update
    Subresource:     status
    Time:            2023-07-30T10:17:09Z
  Resource Version:  6870
  UID:               b39b2256-d4fc-4b47-a6e5-3fd7ef17e002
Spec:
  Source:
    Persistent Volume Claim Name:  storage-pvc
  Volume Snapshot Class Name:      hostpath-snapshot-class
Status:
  Bound Volume Snapshot Content Name:  snapcontent-b39b2256-d4fc-4b47-a6e5-3fd7ef17e002
  Creation Time:                       2023-07-30T10:17:09Z
  Ready To Use:                        true
  Restore Size:                        1Gi
Events:
  Type    Reason            Age   From                 Message
  ----    ------            ----  ----                 -------
  Normal  CreatingSnapshot  44s   snapshot-controller  Waiting for a snapshot default/storage-pvc-snapshot to be created by the CSI driver.
  Normal  SnapshotCreated   43s   snapshot-controller  Snapshot default/storage-pvc-snapshot was successfully created by the CSI driver.
  Normal  SnapshotReady     43s   snapshot-controller  Snapshot default/storage-pvc-snapshot is ready to use.
```

Восстанавливаем снэпшот созданием PVC с указанием снэпшота в качестве dataSource. 
```shell
$ kubectl apply -f storage-pvc-restore.yaml
persistentvolumeclaim/storage-pvc-restore created
```
Создаем новый под с примонтированным восстановленным PVC.
```shell
$ kubectl apply -f storage-pod-restored-pvc.yaml
pod/storage-pod-restore-pvc created
```
Заходим в новый под, видим, что файл на месте:
```shell
$ kubectl exec -it storage-pod-restore-pvc -- sh
# cat /data/test1.txt
test
```

## Задание со ⭐ (развернуть k8s-кластер, к которому добавить хранилище на iSCSI)

### Запускаем еще одну ВМ для iscsi-storage

```shell
cd iscsi
vagrant up
```

### Настраиваем targetcli

Действуем по инструкции [https://kifarunix.com/how-to-install-and-configure-iscsi-storage-server-on-ubuntu-18-04](https://kifarunix.com/how-to-install-and-configure-iscsi-storage-server-on-ubuntu-18-04)

```shell
root@iscsi-storage:~# targetcli
targetcli shell version 2.1.51
Copyright 2011-2013 by Datera, Inc and others.
For help on commands, type 'help'.

/> ls
o- / ......................................................................................................................... [...]
  o- backstores .............................................................................................................. [...]
  | o- block .................................................................................................. [Storage Objects: 0]
  | o- fileio ................................................................................................. [Storage Objects: 0]
  | o- pscsi .................................................................................................. [Storage Objects: 0]
  | o- ramdisk ................................................................................................ [Storage Objects: 0]
  o- iscsi ............................................................................................................ [Targets: 0]
  o- loopback ......................................................................................................... [Targets: 0]
  o- vhost ............................................................................................................ [Targets: 0]
  o- xen-pvscsi ....................................................................................................... [Targets: 0]

/> backstores/block create name=iscsi-disk dev=/dev/vg0/base
Created block storage object iscsi-disk using /dev/vg0/base.

/> /iscsi create
Created target iqn.2003-01.org.linux-iscsi.iscsi-storage.x8664:sn.a8a3b5b09821.
Created TPG 1.
Global pref auto_add_default_portal=true
Created default portal listening on all IPs (0.0.0.0), port 3260.
/> /iscsi/

/iscsi> ls
o- iscsi .............................................................................................................. [Targets: 1]
  o- iqn.2003-01.org.linux-iscsi.iscsi-storage.x8664:sn.a8a3b5b09821 ..................................................... [TPGs: 1]
    o- tpg1 ................................................................................................. [no-gen-acls, no-auth]
      o- acls ............................................................................................................ [ACLs: 0]
      o- luns ............................................................................................................ [LUNs: 0]
      o- portals ...................................................................................................... [Portals: 1]
        o- 0.0.0.0:3260 ....................................................................................................... [OK]

/iscsi> iqn.2003-01.org.linux-iscsi.iscsi-storage.x8664:sn.a8a3b5b09821/tpg1

/iscsi/iqn.20...b5b09821/tpg1> luns/ create /backstores/block/iscsi-disk
Created LUN 0.

/iscsi/iqn.20...b5b09821/tpg1> set attribute authentication=0
Parameter authentication is now '0'.
/iscsi/iqn.20...b5b09821/tpg1> acls/

/iscsi/iqn.20...821/tpg1/acls> create wwn=iqn.2023-10.com.example.srv01.initiator01
Created Node ACL for iqn.2023-10.com.example.srv01.initiator01
Created mapped LUN 0.

/iscsi/iqn.20...821/tpg1/acls> cd /

/> ls
o- / ......................................................................................................................... [...]
  o- backstores .............................................................................................................. [...]
  | o- block .................................................................................................. [Storage Objects: 1]
  | | o- iscsi-disk ................................................................. [/dev/vg0/base (48.0MiB) write-thru activated]
  | |   o- alua ................................................................................................... [ALUA Groups: 1]
  | |     o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | o- fileio ................................................................................................. [Storage Objects: 0]
  | o- pscsi .................................................................................................. [Storage Objects: 0]
  | o- ramdisk ................................................................................................ [Storage Objects: 0]
  o- iscsi ............................................................................................................ [Targets: 1]
  | o- iqn.2003-01.org.linux-iscsi.iscsi-storage.x8664:sn.a8a3b5b09821 ................................................... [TPGs: 1]
  |   o- tpg1 ............................................................................................... [no-gen-acls, no-auth]
  |     o- acls .......................................................................................................... [ACLs: 1]
  |     | o- iqn.2023-10.com.example.srv01.initiator01 ............................................................ [Mapped LUNs: 1]
  |     |   o- mapped_lun0 ............................................................................ [lun0 block/iscsi-disk (rw)]
  |     o- luns .......................................................................................................... [LUNs: 1]
  |     | o- lun0 ............................................................ [block/iscsi-disk (/dev/vg0/base) (default_tg_pt_gp)]
  |     o- portals .................................................................................................... [Portals: 1]
  |       o- 0.0.0.0:3260 ..................................................................................................... [OK]
  o- loopback ......................................................................................................... [Targets: 0]
  o- vhost ............................................................................................................ [Targets: 0]
  o- xen-pvscsi ....................................................................................................... [Targets: 0]

/> saveconfig
Last 10 configs saved in /etc/rtslib-fb-target/backup/.
Configuration saved to /etc/rtslib-fb-target/saveconfig.json

/> exit
Global pref auto_save_on_exit=true
Last 10 configs saved in /etc/rtslib-fb-target/backup/.
Configuration saved to /etc/rtslib-fb-target/saveconfig.json
```
           
## Настраиваем worker-node

Устанавливаем утилиту для работы с iSCSI таргетами:  
`apt -y install open-iscsi`

Настроим конфиг /etc/iscsi/initiatorname.iscsi: 
```shell
## DO NOT EDIT OR REMOVE THIS FILE!
## If you remove this file, the iSCSI daemon will not start.
## If you change the InitiatorName, existing access control lists
## may reject this initiator.  The InitiatorName must be unique
## for each iSCSI initiator.  Do NOT duplicate iSCSI InitiatorNames.
InitiatorName=iqn.2023-10.com.example.srv01.initiator01
```

Добавим open-iscsi в автозагрузку и запустим:
```shell
systemctl restart iscsid open-iscsi
systemctl enable iscsid open-iscsi
```

Запускаем под:
```shell
$ kubectl apply -f iscsi/pod-iscsi.yaml 
pod/my-iscsi-pod created
```
Проверяем подключенный iSCI-target как volume пода:

```shell
$ k describe pod my-iscsi-pod
Name:         my-iscsi-pod
Namespace:    default
Priority:     0
Node:         k1s/192.168.56.110
...
      /mnt from iscsi-test (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-bmqfb (ro)
...
Volumes:
  iscsi-test:
    Type:               ISCSI (an ISCSI Disk resource that is attached to a kubelet's host machine and then exposed to the pod)
    TargetPortal:       192.168.56.111:3260
    IQN:                iqn.2003-01.org.linux-iscsi.iscsi-storage.x8664:sn.a8a3b5b09821
    Lun:                0
    ISCSIInterface      default
    FSType:             ext4
    ReadOnly:           false
    Portals:            []
    DiscoveryCHAPAuth:  false
    SessionCHAPAuth:    false
    SecretRef:          nil
...
Events:
  Type    Reason                  Age   From                     Message
  ----    ------                  ----  ----                     -------
  Normal  Scheduled               15s   default-scheduler        Successfully assigned default/my-iscsi-pod to k1s
  Normal  SuccessfulAttachVolume  15s   attachdetach-controller  AttachVolume.Attach succeeded for volume "iscsi-test"
  Normal  Pulling                 4s    kubelet                  Pulling image "nginx"
  Normal  Pulled                  1s    kubelet                  Successfully pulled image "nginx" in 2.749066132s
  Normal  Created                 1s    kubelet                  Created container my-iscsi-pod
  Normal  Started                 1s    kubelet                  Started container my-iscsi-pod
```

Зайдем на pod:
```shell
$ kubectl exec -it my-iscsi-pod -- /bin/bash
$ echo "ISCSI TEST!" > /mnt/iscsi-test.txt
```

Создадим snapshot:
```shell
vagrant@iscsi-storage:~$ sudo lvcreate --snapshot --size 1G  --name ss-01 /dev/vg0/base
  Reducing COW size 1.00 GiB down to maximum usable size 52.00 MiB.
  Logical volume "ss-01" created.
```
Перейдем обратно в под и удалим данные:
`# rm -rf /mnt/iscsi-test.txt`

Удалим сам pod:
```shell
$ kubectl delete -f iscsi/pod-iscsi.yaml 
pod "my-iscsi-pod" deleted
```

Отключим диск iSCSI:
```shell
root@iscsi-storage:/home/vagrant# targetcli
targetcli shell version 2.1.fb43
Copyright 2011-2013 by Datera, Inc and others.
For help on commands, type 'help'.

/> backstores/block delete iscsi-disk 
Deleted storage object iscsi-disk.

/> saveconfig
Last 10 configs saved in /etc/rtslib-fb-target/backup.
Configuration saved to /etc/rtslib-fb-target/saveconfig.json

/> exit
Global pref auto_save_on_exit=true
Last 10 configs saved in /etc/rtslib-fb-target/backup.
Configuration saved to /etc/rtslib-fb-target/saveconfig.json
```
        
Восстановимся из снапшота:
```shell
vagrant@iscsi-storage:~$ sudo lvconvert --merge /dev/vg0/ss-01 
  Merging of volume vg0/ss-01 started.
  vg0/base: Merged: 100.00%
```

Восстановим диск iSCSI:
```
vagrant@iscsi-storage:~$ sudo targetcli
targetcli shell version 2.1.51
Copyright 2011-2013 by Datera, Inc and others.
For help on commands, type 'help'.

/> backstores/block create name=iscsi-disk dev=/dev/vg0/base
Created block storage object iscsi-disk using /dev/vg0/base.

/iscsi> /iscsi/iqn.2003-01.org.linux-iscsi.iscsi-storage.x8664:sn.a8a3b5b09821/tpg1

/iscsi/iqn.20...b5b09821/tpg1> luns/ create /backstores/block/iscsi-disk
Created LUN 0.
Created LUN 0->0 mapping in node ACL iqn.2023-10.com.example.srv01.initiator01

/iscsi/iqn.20...b5b09821/tpg1> exit
Global pref auto_save_on_exit=true
Configuration saved to /etc/rtslib-fb-target/saveconfig.json
```

Снова запустим и проверим наличие файла
```
$ kubectl apply -f iscsi/pod-iscsi.yaml 
pod/my-iscsi-pod created

$ kubectl exec -it my-iscsi-pod -- /bin/bash
root@my-iscsi-pod:/# cat /mnt/iscsi-test.txt
ISCSI TEST!
```

### Удаление инфраструктуры

`vagrant destroy`

## Как проверить работоспособность:
 - см. выше
## PR checklist:
 - [x] Выставлен label с темой домашнего задания
