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

variable "access_key" {
  description = "static access key"
  type        = string
}

variable "secret_key" {
  description = "secret for static access key"
  type        = string
}