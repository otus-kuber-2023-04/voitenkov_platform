locals {
  cidr_internet = "0.0.0.0/0" # All IPv4 addresses.
}

resource "yandex_vpc_network" "network-momo-store-dev" {
  name                        = "network-${var.project}-${var.environment}"
}

module "a1-subnet" {
  source                      = "../modules/subnet"
  subnet_name                 = "subnet-${var.project}-${var.environment}-a1"
  subnet_network_id           = yandex_vpc_network.network-momo-store-dev.id
  subnet_zone                 = "ru-central1-a"
  subnet_v4_cidr_blocks       = ["192.168.10.0/24"]

  depends_on = [yandex_vpc_network.network-momo-store-dev]
}

resource "yandex_vpc_security_group" "sg-momo-store-dev-instance-linux" {
  description = "Default security group for linux instances"
  name        = "sg-${var.project}-${var.environment}-instance-linux"
  network_id  = yandex_vpc_network.network-momo-store-dev.id

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

  depends_on = [yandex_vpc_network.network-momo-store-dev]
}

resource "yandex_vpc_security_group" "sg-momo-store-dev-instance-webserver" {
  description = "Default security group for web-server instances"
  name        = "sg-${var.project}-${var.environment}-instance-webserver"
  network_id  = yandex_vpc_network.network-momo-store-dev.id

   ingress {
    description    = "Allow HTTP connections to web-server instance"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = [local.cidr_internet]
  }

  ingress {
    description    = "Allow HTTPS connections to web-server instance"
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = [local.cidr_internet]
  }
 
  depends_on = [yandex_vpc_network.network-momo-store-dev]
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
  instance_subnet_id          = module.a1-subnet.id
  instance_nat                = true
  instance_security_group_ids = [
    yandex_vpc_security_group.sg-momo-store-dev-instance-linux.id,    
    yandex_vpc_security_group.sg-momo-store-dev-instance-webserver.id
  ]
  instance_user_data_file     = "ubuntu-devops"
  instance_serial_port_enable = 1

  depends_on = [
    module.a1-subnet,
    module.devops-sa,
    yandex_vpc_security_group.sg-momo-store-dev-instance-linux,    
    yandex_vpc_security_group.sg-momo-store-dev-instance-webserver,
  ]     
}



