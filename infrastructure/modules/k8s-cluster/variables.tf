variable "k8s_cluster_project" {
  type        = string
  description = "K8s cluster project (cloud)"
  nullable    = false
}

variable "k8s_cluster_environment" {
  type        = string
  description = "K8s cluster environment"
  nullable    = false
}

variable "k8s_cluster_name" {
  type        = string
  description = "K8s cluster name"
  nullable    = false
}

variable "k8s_cluster_network_id" {
  type        = string
  description = "K8s_cluster network interface subnet"
  nullable    = false
}

variable "k8s_cluster_version" {
  type        = string
  description = "K8s cluster version"
}

variable "k8s_cluster_release_channel" {
  type        = string
  description = "K8s cluster release channel"
  default     = "STABLE"
}

variable "k8s_cluster_zone" {
  type        = string
  description = "K8s cluster zone"
  default     = "ru-central1-a"
}

variable "k8s_cluster_subnet_id" {
  type        = string
  description = "K8s cluster network interface subnet"
  nullable    = false
}

variable "k8s_cluster_public_ip" {
  type        = bool
  description = "K8s cluster public IP"
  default     = false
  nullable    = false
}

variable "k8s_cluster_security_group_ids" {
  type        = list
  description = "K8s cluster security group IDs"
}

variable "k8s_cluster_service_account_name" {
  type        = string
  description = "K8s cluster service account name"
  nullable    = false
}

variable "k8s_cluster_node_service_account_name" {
  type        = string
  description = "K8s cluster node service account name"
  nullable    = false
}

variable "k8s_cluster_cluster_ipv4_range" {
  default     = "10.96.0.0/16"
  type        = string
  description = "K8s cluster ipv4 CIDR"
  nullable    = false
}

variable "k8s_cluster_service_ipv4_range" {
  default     = "10.112.0.0/16"
  type        = string
  description = "K8s service ipv4 CIDR"
  nullable    = false
}
