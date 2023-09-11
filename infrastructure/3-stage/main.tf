locals {
  cidr_internet = "0.0.0.0/0" # All IPv4 addresses.
}

resource "yandex_vpc_network" "network-otus-kuber-stage" {
  name                        = "network-${var.project}-${var.environment}"
}

resource "yandex_vpc_gateway" "gateway-otus-kuber-stage" {
  name = "gateway-${var.project}-${var.environment}"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "rt-otus-kuber-stage" {
  name       = "rt-${var.project}-${var.environment}"
  network_id = yandex_vpc_network.network-otus-kuber-stage.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.gateway-otus-kuber-stage.id
  }
  depends_on = [
    yandex_vpc_network.network-otus-kuber-stage,
    yandex_vpc_gateway.gateway-otus-kuber-stage,
    ]
}

resource "yandex_vpc_subnet" "subnet-otus-kuber-stage-a1" {
  folder_id      =  var.folder_id
  name           = "subnet-${var.project}-${var.environment}-a1"
  v4_cidr_blocks = ["192.168.10.0/24"]
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-otus-kuber-stage.id
  route_table_id = yandex_vpc_route_table.rt-otus-kuber-stage.id

  depends_on = [
    yandex_vpc_network.network-otus-kuber-stage,
    yandex_vpc_route_table.rt-otus-kuber-stage,
  ]

}

resource "yandex_vpc_security_group" "sg-otus-kuber-stage-instance-linux" {
  description = "Default security group for linux instances"
  name        = "sg-${var.project}-${var.environment}-instance-linux"
  network_id  = yandex_vpc_network.network-otus-kuber-stage.id


  egress {
    description    = "Allow any outgoing traffic to the Internet"
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = [local.cidr_internet]
  }
  ingress {
    description    = "Allow SSH connections to the instance"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = [local.cidr_internet]
  }

  depends_on = [yandex_vpc_network.network-otus-kuber-stage]
}

resource "yandex_vpc_security_group" "sg-otus-kuber-stage-k8s-main" {
  name        = "sg-${var.project}-${var.environment}-k8s-main"
  description = "Правила группы обеспечивают базовую работоспособность кластера. Примените ее к кластеру и группам узлов."
  network_id  = yandex_vpc_network.network-otus-kuber-stage.id

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
    v4_cidr_blocks = ["10.244.0.0/16"]
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

module "cluster-sa" {
  source                      = "../modules/sa"
  sa_name                     = "sa-${var.project}-${var.environment}-cluster"
  sa_description              = "Service account for cluster instances in ${var.project} ${var.environment} environment"
  sa_folder_id                = var.folder_id
  sa_role                     = "viewer"
}

module "master-instance" {
  source                      = "../modules/instance"
  count                       = 1
  instance_no                 = count.index + 1
  instance_name               = "master${count.index + 1}"
  instance_project            = var.project
  instance_environment        = var.environment
  instance_service_account_name = module.cluster-sa.name
  instance_preemptible        = true
  instance_core_fraction      = 100
  instance_memory             = 8
  instance_subnet_id          = yandex_vpc_subnet.subnet-otus-kuber-stage-a1.id
  instance_nat                = false
  instance_security_group_ids = [
    yandex_vpc_security_group.sg-otus-kuber-stage-instance-linux.id,
    yandex_vpc_security_group.sg-otus-kuber-stage-k8s-main.id,
  ]
  instance_user_data_file     = "ubuntu-k8s"
  instance_serial_port_enable = 1
  instance_image_id           = "fd81n0sfjm6d5nq6l05g" # ubuntu-20-04-lts-v20230904

  depends_on = [
    yandex_vpc_subnet.subnet-otus-kuber-stage-a1,
    module.cluster-sa,
    yandex_vpc_security_group.sg-otus-kuber-stage-instance-linux,    
  ]     
}

module "worker-instance" {
  source                      = "../modules/instance"
  count                       = 3
  instance_no                 = count.index + 1
  instance_name               = "worker${count.index + 1}"
  instance_project            = var.project
  instance_environment        = var.environment
  instance_service_account_name = module.cluster-sa.name
  instance_preemptible        = true
  instance_core_fraction      = 100
  instance_memory             = 8
  instance_subnet_id          = yandex_vpc_subnet.subnet-otus-kuber-stage-a1.id
  instance_nat                = false
  instance_security_group_ids = [
    yandex_vpc_security_group.sg-otus-kuber-stage-instance-linux.id,
    yandex_vpc_security_group.sg-otus-kuber-stage-k8s-main.id,
  ]
  instance_user_data_file     = "ubuntu-k8s"
  instance_serial_port_enable = 1
  instance_image_id           = "fd81n0sfjm6d5nq6l05g" # ubuntu-20-04-lts-v20230904

  depends_on = [
    yandex_vpc_subnet.subnet-otus-kuber-stage-a1,
    module.cluster-sa,
    yandex_vpc_security_group.sg-otus-kuber-stage-instance-linux,    
  ]     
}

module "devops-sa" {
  source                      = "../modules/sa"
  sa_name                     = "sa-${var.project}-${var.environment}-devops"
  sa_description              = "Service account for DevOps instance in ${var.project} ${var.environment} environment"
  sa_folder_id                = var.folder_id
  sa_role                     = "viewer"
}

module "devops-instance" {
  source                      = "../modules/instance"
  count                       = 1
  instance_no                 = count.index + 1
  instance_name               = "devops${count.index + 1}"
  instance_project            = var.project
  instance_environment        = var.environment
  instance_service_account_name = module.devops-sa.name
  instance_preemptible        = true
  instance_core_fraction      = 50
  instance_memory             = 4
  instance_subnet_id          = yandex_vpc_subnet.subnet-otus-kuber-stage-a1.id
  instance_nat                = true
  instance_security_group_ids = [
    yandex_vpc_security_group.sg-otus-kuber-stage-instance-linux.id
  ]
  instance_user_data_file     = "ubuntu-devops"
  instance_serial_port_enable = 1

  depends_on = [
    yandex_vpc_subnet.subnet-otus-kuber-stage-a1,
    module.devops-sa,
    yandex_vpc_security_group.sg-otus-kuber-stage-instance-linux,    
  ]     
}