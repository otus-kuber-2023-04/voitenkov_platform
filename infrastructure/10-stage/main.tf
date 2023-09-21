locals {
  cidr_internet = "0.0.0.0/0" # All IPv4 addresses.
}

resource "yandex_vpc_network" "network-otus-kuber-stage" {
  name                        = "network-${var.project}-${var.environment}"
}

module "a1-subnet" {
  source                      = "../modules/subnet"
  subnet_name                 = "subnet-${var.project}-${var.environment}-a1"
  subnet_network_id           = yandex_vpc_network.network-otus-kuber-stage.id
  subnet_zone                 = "ru-central1-a"
  subnet_v4_cidr_blocks       = ["192.168.10.0/24"]

  depends_on = [yandex_vpc_network.network-otus-kuber-stage]
}

resource "yandex_vpc_security_group" "sg-otus-kuber-stage-k8s-main" {
  name        = "sg-${var.project}-${var.environment}-k8s-main"
  description = "Правила группы обеспечивают базовую работоспособность кластера. Примените ее к кластеру и группам узлов."
  network_id  = yandex_vpc_network.network-otus-kuber-stage.id

  ingress {
    protocol          = "TCP"
    description       = "Правило разрешает проверки доступности с диапазона адресов балансировщика нагрузки. Нужно для работы отказоустойчивого кластера и сервисов балансировщика."
    predefined_target = "loadbalancer_healthchecks"
    from_port         = 0
    to_port           = 65535
  }
  ingress {
    protocol          = "ANY"
    description       = "Правило разрешает взаимодействие мастер-узел и узел-узел внутри группы безопасности."
    predefined_target = "self_security_group"
    from_port         = 0
    to_port           = 65535
  }
  ingress {
    protocol       = "ANY"
    description    = "Правило разрешает взаимодействие под-под и сервис-сервис. Укажите подсети вашего кластера и сервисов."
    v4_cidr_blocks = ["10.96.0.0/16", "10.112.0.0/16"]
    from_port      = 0
    to_port        = 65535
  }
  ingress {
    protocol       = "ICMP"
    description    = "Правило разрешает отладочные ICMP-пакеты из внутренних подсетей."
    v4_cidr_blocks = ["172.16.0.0/12", "10.0.0.0/8", "192.168.0.0/16"]
  }
  egress {
    protocol       = "ANY"
    description    = "Правило разрешает весь исходящий трафик. Узлы могут связаться с Yandex Container Registry, Object Storage, Docker Hub и т. д."
    v4_cidr_blocks = [local.cidr_internet]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_vpc_security_group" "sg-otus-kuber-stage-k8s-public-services" {
  name        = "sg-${var.project}-${var.environment}-k8s-public-services"
  description = "Правила группы разрешают подключение к сервисам из интернета. Примените правила только для групп узлов."
  network_id  = yandex_vpc_network.network-otus-kuber-stage.id

  ingress {
    protocol       = "TCP"
    description    = "Правило разрешает входящий трафик из интернета на диапазон портов NodePort. Добавьте или измените порты на нужные вам."
    v4_cidr_blocks = [local.cidr_internet]
    from_port      = 30000
    to_port        = 32767
  }
}

resource "yandex_vpc_security_group" "sg-otus-kuber-stage-k8s-nodes-ssh-access" {
  name        = "sg-${var.project}-${var.environment}-k8s-nodes-ssh-access"
  description = "Правила группы разрешают подключение к узлам кластера по SSH. Примените правила только для групп узлов."
  network_id  = yandex_vpc_network.network-otus-kuber-stage.id

  ingress {
    protocol       = "TCP"
    description    = "Правило разрешает подключение к узлам по SSH с указанных IP-адресов."
    v4_cidr_blocks = ["172.16.0.0/12", "10.0.0.0/8", "192.168.0.0/16"]
    port           = 22
  }
}

resource "yandex_vpc_security_group" "sg-otus-kuber-stage-k8s-master-whitelist" {
  name        = "sg-${var.project}-${var.environment}-k8s-master-whitelist"
  description = "Правила группы разрешают доступ к API Kubernetes из интернета. Примените правила только к кластеру."
  network_id  = yandex_vpc_network.network-otus-kuber-stage.id

  ingress {
    protocol       = "TCP"
    description    = "Правило разрешает подключение к API Kubernetes через порт 6443 из указанной сети."
    v4_cidr_blocks = [local.cidr_internet]
    port           = 6443
  }

  ingress {
    protocol       = "TCP"
    description    = "Правило разрешает подключение к API Kubernetes через порт 443 из указанной сети."
    v4_cidr_blocks = [local.cidr_internet]
    port           = 443
  }
}

resource "yandex_vpc_security_group" "sg-otus-kuber-stage-k8s-master-public-services" {
  name        = "sg-${var.project}-${var.environment}-k8s-master-public-services"
  description = "Правила из курса Деплой инфраструктуры по модели GitOps."
  network_id  = yandex_vpc_network.network-otus-kuber-stage.id

  ingress {
    protocol       = "TCP"
    description    = "Правило из курса Деплой инфраструктуры по модели GitOps"
    v4_cidr_blocks = [local.cidr_internet]
    port           = 443
  }
  ingress {
    protocol       = "TCP"
    description    = "Правило из курса Деплой инфраструктуры по модели GitOps"
    v4_cidr_blocks = [local.cidr_internet]
    port           = 80
  }
  ingress {
    protocol       = "tcp"
    description    = "Правило из курса Деплой инфраструктуры по модели GitOps"
    v4_cidr_blocks = ["198.18.235.0/24","198.18.248.0/24"]
    from_port      = 0
    to_port        = 65535
  }
}

module "k8s-cluster-sa" {
  source                      = "../modules/sa"
  sa_name                     = "sa-${var.project}-${var.environment}-k8s-cluster"
  sa_description              = "Service account for Kubernetes cluster in ${var.project} ${var.environment} environment"
  sa_folder_id                = var.folder_id
  sa_role                     = "editor"
}

module "k8s-node-group-sa" {
  source                      = "../modules/sa"
  sa_name                     = "sa-${var.project}-${var.environment}-k8s-node-group"
  sa_description              = "Service account for Node group of Kubernetes cluster in ${var.project} ${var.environment} environment"
  sa_folder_id                = var.folder_id
  sa_role                     = "container-registry.images.puller"
}

module "c1-k8s-cluster" {
  source                                = "../modules/k8s-cluster"
  k8s_cluster_name                      = "cluster-1"
  k8s_cluster_project                   = var.project
  k8s_cluster_environment               = var.environment
  k8s_cluster_network_id                = yandex_vpc_network.network-otus-kuber-stage.id
  k8s_cluster_version                   = "1.24"
  k8s_cluster_subnet_id                 = module.a1-subnet.id
  k8s_cluster_public_ip                 = true
  k8s_cluster_security_group_ids        = [
    yandex_vpc_security_group.sg-otus-kuber-stage-k8s-main.id,
    yandex_vpc_security_group.sg-otus-kuber-stage-k8s-master-whitelist.id
  ]
  k8s_cluster_service_account_name      = module.k8s-cluster-sa.name
  k8s_cluster_node_service_account_name = module.k8s-node-group-sa.name
  
  depends_on = [
    module.a1-subnet,
    module.k8s-cluster-sa,
    module.k8s-node-group-sa,
    yandex_vpc_security_group.sg-otus-kuber-stage-k8s-main,    
    yandex_vpc_security_group.sg-otus-kuber-stage-k8s-master-whitelist,
  ]     
}

module "default-pool-k8s-node-group" {
  source                            = "../modules/k8s-node-group"
  k8s_node_group_name               = "default-pool"
  k8s_node_group_project            = var.project
  k8s_node_group_environment        = var.environment
  k8s_node_group_cluster            = "cluster-1"
  k8s_node_group_cluster_id         = module.c1-k8s-cluster.id
  k8s_node_group_version            = "1.24"
  k8s_node_group_auto_scale_max     = 1
  k8s_node_group_preemptible        = true
  k8s_node_group_memory             = 8
  k8s_node_group_nat                = true
  k8s_node_group_subnet_ids         = [module.a1-subnet.id]
  k8s_node_group_security_group_ids = [
    yandex_vpc_security_group.sg-otus-kuber-stage-k8s-main.id,
    yandex_vpc_security_group.sg-otus-kuber-stage-k8s-nodes-ssh-access.id,
    yandex_vpc_security_group.sg-otus-kuber-stage-k8s-public-services.id
  ]
  k8s_node_group_username           = "devops1"
  k8s_node_group_ssh_public_key     = file("./.secrets/devops1/id_rsa.pub")
 
  depends_on = [
    module.c1-k8s-cluster,
    module.a1-subnet,
    yandex_vpc_security_group.sg-otus-kuber-stage-k8s-main,
    yandex_vpc_security_group.sg-otus-kuber-stage-k8s-nodes-ssh-access,
    yandex_vpc_security_group.sg-otus-kuber-stage-k8s-public-services,
  ]     
}

module "infra-pool-k8s-node-group" {
  source                            = "../modules/k8s-node-group"
  k8s_node_group_name               = "infra-pool"
  k8s_node_group_project            = var.project
  k8s_node_group_environment        = var.environment
  k8s_node_group_cluster            = "cluster-1"
  k8s_node_group_cluster_id         = module.c1-k8s-cluster.id
  k8s_node_group_version            = "1.24"
  k8s_node_group_node_taints        = ["node-role=infra:NoSchedule"]
  k8s_node_group_auto_scale_max     = 3
  k8s_node_group_preemptible        = true
  k8s_node_group_memory             = 8
  k8s_node_group_nat                = true
  k8s_node_group_subnet_ids         = [module.a1-subnet.id]
  k8s_node_group_security_group_ids = [
    yandex_vpc_security_group.sg-otus-kuber-stage-k8s-main.id,
    yandex_vpc_security_group.sg-otus-kuber-stage-k8s-nodes-ssh-access.id,
    yandex_vpc_security_group.sg-otus-kuber-stage-k8s-public-services.id
  ]
  k8s_node_group_username           = "devops1"
  k8s_node_group_ssh_public_key     = file("./.secrets/devops1/id_rsa.pub")
 
  depends_on = [
    module.c1-k8s-cluster,
    module.a1-subnet,
    yandex_vpc_security_group.sg-otus-kuber-stage-k8s-main,
    yandex_vpc_security_group.sg-otus-kuber-stage-k8s-nodes-ssh-access,
    yandex_vpc_security_group.sg-otus-kuber-stage-k8s-public-services,
  ]     
}

resource "yandex_iam_service_account" "sa-otus-kuber-stage-auditlogs" {
  name        = "sa-${var.project}-${var.environment}-auditlogs"
  description = "Service account for YC auditlogs exporter solution in ${var.project} ${var.environment} environment"
}

resource "yandex_resourcemanager_folder_iam_binding" "auditlogs-functions-invoker" {
  folder_id   = var.folder_id
  role        = "serverless.functions.invoker"
  members = [
    "serviceAccount:${yandex_iam_service_account.sa-otus-kuber-stage-auditlogs.id}"
  ]

  depends_on  = [yandex_iam_service_account.sa-otus-kuber-stage-auditlogs]
}

resource "yandex_resourcemanager_folder_iam_binding" "auditlogs-storage-editor" {
  folder_id   = var.folder_id
  role        = "storage.editor"
  members = [
    "serviceAccount:${yandex_iam_service_account.sa-otus-kuber-stage-auditlogs.id}"
  ]

  depends_on  = [yandex_iam_service_account.sa-otus-kuber-stage-auditlogs]
}

resource "yandex_resourcemanager_folder_iam_binding" "auditlogs-ymq-editor" {
  folder_id   = var.folder_id
  role        = "ymq.writer"
  members = [
    "serviceAccount:${yandex_iam_service_account.sa-otus-kuber-stage-auditlogs.id}"
  ]

  depends_on  = [yandex_iam_service_account.sa-otus-kuber-stage-auditlogs]
}

module "security-events-to-siem-importer" {
  source                         = "../modules/auditlogs-k8s-ELK"
  folder_id                      = var.folder_id
  cloud_id                       = var.cloud_id
  cluster_name                   = var.cluster_name
  elastic_server                 = var.elastic_server
  elastic_pw                     = var.elastic_pw
  elastic_user                   = var.elastic_user
  service_account_id             = yandex_iam_service_account.sa-otus-kuber-stage-auditlogs.id
  log_bucket_name                = var.log_bucket_name
  create_namespace               = var.create_namespace
  worker_docker_image            = var.worker_docker_image
  auditlog_enabled               = var.auditlog_enabled
  auditlogs_prefix               = var.auditlogs_prefix
  auditlog_worker_chart_name     = var.auditlog_worker_chart_name
  auditlog_worker_namespace      = var.auditlog_worker_namespace
  auditlog_worker_replicas_count = var.auditlog_worker_replicas_count
  falco_enabled                  = var.falco_enabled
  falco_prefix                   = var.falco_prefix
  falco_worker_chart_name        = var.falco_worker_chart_name
  falco_worker_namespace         = var.falco_worker_namespace
  falco_worker_replicas_count    = var.falco_worker_replicas_count
  falco_helm_namespace           = var.falco_helm_namespace
  falco_version                  = var.falco_version
  falcosidekick_version          = var.falcosidekick_version
  kyverno_enabled                = var.kyverno_enabled
  kyverno_prefix                 = var.kyverno_prefix
  kyverno_version                = var.kyverno_version
  kyverno_worker_chart_name      = var.kyverno_worker_chart_name
  kyverno_worker_namespace       = var.kyverno_worker_namespace
  kyverno_worker_replicas_count  = var.kyverno_worker_replicas_count
  kyverno_helm_namespace         = var.kyverno_helm_namespace
  kyverno_policies_version       = var.kyverno_policies_version
  policy_reporter_version        = var.policy_reporter_version
  fakeeventgenerator_enabled     = var.fakeeventgenerator_enabled
}
