variable "cloud_id" {
  type        = string
  description = "YC Cloud ID"
}

variable "folder_id" {
  type        = string
  description = "YC Folder ID"
}

variable "project" {
  type        = string
  description = "Name of project (cloud)"
}

variable "environment" {
  type        = string
  description = "Name of environment"
}

variable "domain1" {
  type        = string
  description = "Name of domain 1"
}

variable "subdomain1_1" {
  type        = string
  description = "Name of subdomain 1 of domain 1"
}

variable "external_ip1" {
  type        = string
  description = "External IP for ingress controller service of cluster 1"
}

variable "region_name" {
  description = "The Yandex.Cloud Cloud Region name."
  type        = string
  default     = "ru-central1"
}

variable "cluster_name" {
  description = "The Yandex.Cloud K8s cluster name."
  type        = string
}

# S3 Bucket Variables
variable "log_bucket_name" {
  type = string
}

variable "s3_expiration" {
  type = map(string)
  default = {
    "enabled" = true
    "days"    = 10
  }
  description = "Enable or disable delete indicies backup from bucket after days"
}

# Yandex Message Queue Variables
variable "timer_for_mq" {
  description = "Timer for add permission for create mq"
  type        = string
  default     = "10s"
}

# Elastic Server
variable "elastic_pw" {
  type = string
}

variable "elastic_user" {
  type = string
}

variable "elastic_server" {
  type = string
}

# Common Variables for Chart
variable "create_namespace" {
  description = "Create the namespace if it does not yet exists."
  type        = bool
}

variable "value" {
  description = "Values for the chart."
  default     = ""
}

variable "set" {
  type        = map(any)
  default     = {}
  description = "Additional values set"
}

variable "set_sensitive" {
  type        = map(any)
  default     = {}
  description = "Additional sensitive values set"
}

# Worker Settings
variable "worker_docker_image" {
  type = string
}

# AUDIT LOG
variable "auditlog_enabled" {
  type = bool
}

variable "auditlogs_prefix" {
  type = string
}

variable "auditlog_worker_chart_name" {
  description = "The name of the auditlog worker helm release"
  type        = string
}

variable "auditlog_worker_namespace" {
  description = "The namespace in which the worker chart will be deployed."
  type        = string
}

variable "auditlog_worker_replicas_count" {
  description = "Count of replicas for audit worker."
  type        = number
}

# FALCO
variable "falco_enabled" {
  type = bool
}

variable "falco_prefix" {
  type = string
}

variable "falco_worker_chart_name" {
  description = "The name of the falco worker helm release"
  type        = string
}

variable "falco_worker_namespace" {
  description = "The namespace in which the worker chart will be deployed."
  type        = string
}

variable "falco_worker_replicas_count" {
  description = "Count of replicas for falco worker."
  type        = number
}

variable "falco_helm_namespace" {
  description = "The namespace in which the helm will be deployed."
  type        = string
}

# KYVERNO
variable "kyverno_enabled" {
  type = bool
}

variable "kyverno_prefix" {
  type = string
}

variable "kyverno_worker_chart_name" {
  description = "The name of the kyverno worker helm release"
  type        = string
}

variable "kyverno_worker_namespace" {
  description = "The namespace in which the worker chart will be deployed."
  type        = string
}

variable "kyverno_worker_replicas_count" {
  description = "Count of replicas for kyverno worker."
  type        = number
}

variable "kyverno_helm_namespace" {
  description = "The namespace in which the helm will be deployed."
  type        = string
}

# Variables for Export

variable "fakeeventgenerator_enabled" {
  type = bool
}

variable "podSecurityStandard" {
  type    = string
  default = "restricted"
}

variable "validationFailureAction" {
  type    = string
  default = "audit"
}

# FALCO Helm
variable "falco_version" {
  type = string
}

variable "falcosidekick_version" {
  type = string
}

# KYVERNO Helm
variable "kyverno_version" {
  type = string
}
variable "kyverno_policies_version" {
  type = string
}

variable "policy_reporter_version" {
  type = string
}