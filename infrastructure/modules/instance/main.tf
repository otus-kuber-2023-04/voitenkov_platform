locals {
  instance_name		        = "vm-${var.instance_project}-${var.instance_environment}-${var.instance_name}"
  instance_description    = "DevOps workstation No. ${var.instance_no} in ${var.instance_project} ${var.instance_environment} environment"
  instance_ssh_public_key = file("./.secrets/${var.instance_name}/id_rsa.pub")
}

data "yandex_iam_service_account" "service_account" {
  name = var.instance_service_account_name 
} 

data "template_file" "user_data" {
  template = file("../templates/${var.instance_user_data_file}.yml.tftpl")

  vars = {
    username       = var.instance_name
    ssh_public_key = local.instance_ssh_public_key
  }
}

resource "yandex_compute_instance" "instance" {
  name               = local.instance_name
  description        = local.instance_description
  hostname           = var.instance_name
  zone               = var.instance_zone
  platform_id        = var.instance_platform_id
  service_account_id = data.yandex_iam_service_account.service_account.service_account_id
    
  scheduling_policy {
    preemptible = var.instance_preemptible
  }

  resources {
    cores         = var.instance_cores
    core_fraction = var.instance_core_fraction
    memory        = var.instance_memory
  }

  boot_disk {
    initialize_params {
      image_id = var.instance_image_id
      size     = var.instance_disk_size
    }
  }

  network_interface {
    subnet_id          = var.instance_subnet_id
    nat                = var.instance_nat
    security_group_ids = var.instance_security_group_ids

  }

  metadata = {
    user-data = data.template_file.user_data.rendered
    serial-port-enable = var.instance_serial_port_enable
  }
}
