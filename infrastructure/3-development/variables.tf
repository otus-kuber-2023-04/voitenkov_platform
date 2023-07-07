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