locals {
  k8s_node_group_name        = "k8s-${var.k8s_node_group_project}-${var.k8s_node_group_environment}-${var.k8s_node_group_cluster}-${var.k8s_node_group_name}"
  k8s_node_group_description = "Node group for Managed Service for Kubernetes cluster in ${var.k8s_node_group_project} ${var.k8s_node_group_environment} environment (${var.k8s_node_group_cluster}/${var.k8s_node_group_name})"
  k8s_node_group_ssh_keys    = "${var.k8s_node_group_username}:${var.k8s_node_group_ssh_public_key}"
}

resource "yandex_kubernetes_node_group" "k8s-node-group" {
  name        = local.k8s_node_group_name
  description = local.k8s_node_group_description
  cluster_id  = var.k8s_node_group_cluster_id
  version     = var.k8s_node_group_version
  
  node_labels = {
    "node-group" = var.k8s_node_group_name
  }
  
  node_taints = var.k8s_node_group_node_taints
  
  scale_policy {
    auto_scale {
      initial = var.k8s_node_group_auto_scale_initial
      min     = var.k8s_node_group_auto_scale_min
      max     = var.k8s_node_group_auto_scale_max
    }
  }

  allocation_policy {
    location {
      zone = var.k8s_node_group_zone
    }
  }

  instance_template {
    platform_id = var.k8s_node_group_platform_id

    scheduling_policy {
      preemptible = var.k8s_node_group_preemptible
    }

    resources {
      memory = var.k8s_node_group_memory
      cores  = var.k8s_node_group_cores
    }

    boot_disk {
      type = var.k8s_node_group_disk_type
      size = var.k8s_node_group_disk_size
    }

    network_interface {
      nat                = var.k8s_node_group_nat
      subnet_ids         = var.k8s_node_group_subnet_ids
      security_group_ids = var.k8s_node_group_security_group_ids
    }

    metadata = {
      ssh-keys = local.k8s_node_group_ssh_keys
    }
  }
}
