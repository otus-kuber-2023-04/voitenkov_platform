variable "k8s_node_group_project" {
  type        = string
  description = "K8s node group project (cloud)"
  nullable    = false
}

variable "k8s_node_group_environment" {
  type        = string
  description = "K8s node group environment"
  nullable    = false
}

variable "k8s_node_group_name" {
  type        = string
  description = "K8s node group name"
  nullable    = false
}

variable "k8s_node_group_cluster" {
  type        = string
  description = "K8s node group cluster name"
  nullable    = false
}

variable "k8s_node_group_cluster_id" {
  type        = string
  description = "K8s node group cluster ID"
  nullable    = false
}

variable "k8s_node_group_version" {
  type        = string
  description = "K8s node group version"
}

variable "k8s_node_group_auto_scale_initial" {
  type        = number
  description = "K8s node auto scale initial number of instances"
  default     = 1
}

variable "k8s_node_group_auto_scale_min" {
  type        = number
  description = "K8s node auto scale minimum number of instances"
  default     = 1
}

variable "k8s_node_group_auto_scale_max" {
  type        = number
  description = "K8s node auto scale maximum number of instances"
  default     = 1
}

variable "k8s_node_group_zone" {
  type        = string
  description = "K8s node group zone"
  default     = "ru-central1-a"
}

variable "k8s_node_group_platform_id" {
  default     = "standard-v3"
  type        = string
  description = "Platform ID for node group"
  nullable    = false
}

variable "k8s_node_group_preemptible" {
  default     = false
  type        = bool
  description = "K8s node group scheduling policy"
  nullable    = false
}

variable "k8s_node_group_cores" {
  default     = 2
  type        = number
  description = "K8s node group cores quantity"
  nullable    = false
}

variable "k8s_node_group_memory" {
  default     = 4
  type        = number
  description = "K8s node group memory amount"
  nullable    = false
}

variable "k8s_node_group_disk_type" {
  default     = "network-hdd"
  type        = string
  description = "K8s node group disk type"
  nullable    = false
}

variable "k8s_node_group_disk_size" {
  default     = 64
  type        = number
  description = "K8s node group disk size"
  nullable    = false
}

variable "k8s_node_group_nat" {
  type        = bool
  description = "K8s_node_group NAT"
  default     = false
  nullable    = false
}

variable "k8s_node_group_subnet_ids" {
  type        = list
  description = "K8s node group network interface subnet IDs"
  nullable    = false
}

variable "k8s_node_group_public_ip" {
  type        = bool
  description = "K8s node group public IP"
  default     = false
  nullable    = false
}

variable "k8s_node_group_security_group_ids" {
  type        = list
  description = "K8s node group security group IDs"
}

variable "k8s_node_group_username" {
  type        = string
  description = "K8s node group username"
  nullable    = false
}

variable "k8s_node_group_ssh_public_key" {
  type        = string
  description = "K8s node ssh public key"
  nullable    = false
}