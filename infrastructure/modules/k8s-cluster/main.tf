locals {
  k8s_cluster_name		               = "k8s-${var.k8s_cluster_project}-${var.k8s_cluster_environment}-${var.k8s_cluster_name}"
  k8s_cluster_description            = "Managed Service for Kubernetes cluster in ${var.k8s_cluster_project} ${var.k8s_cluster_environment} environment (${var.k8s_cluster_name})"
  k8s_cluster_node_group_name        = "k8s-${var.k8s_cluster_project}-${var.k8s_cluster_environment}-${var.k8s_cluster_name}"
  k8s_cluster_node_group_description = "Node group for Managed Service for Kubernetes cluster in ${var.k8s_cluster_project} ${var.k8s_cluster_environment} environment (${var.k8s_cluster_name})"
}

data "yandex_iam_service_account" "service_account" {
  name = var.k8s_cluster_service_account_name 
} 

data "yandex_iam_service_account" "node_service_account" {
  name = var.k8s_cluster_node_service_account_name 
} 

resource "yandex_kubernetes_cluster" "k8s-cluster" {
  name        = local.k8s_cluster_name
  description = local.k8s_cluster_description
  network_id  = var.k8s_cluster_network_id
  
  master {
    version = var.k8s_cluster_version
    
    zonal {
      zone      = var.k8s_cluster_zone
      subnet_id = var.k8s_cluster_subnet_id
    }

    public_ip          = var.k8s_cluster_public_ip
    security_group_ids = var.k8s_cluster_security_group_ids
  }

  service_account_id      = data.yandex_iam_service_account.service_account.service_account_id
  node_service_account_id = data.yandex_iam_service_account.node_service_account.service_account_id
  cluster_ipv4_range      = var.k8s_cluster_cluster_ipv4_range
  service_ipv4_range      = var.k8s_cluster_service_ipv4_range

}

