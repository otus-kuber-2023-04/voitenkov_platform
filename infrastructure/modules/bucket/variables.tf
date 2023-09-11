variable "bucket_folder_id" {
  type        = string
  description = "Bucket folder ID"
  nullable    = false
}

variable "bucket_project" {
  type        = string
  description = "Bucket project (cloud)"
  nullable    = false
}

variable "bucket_environment" {
  type        = string
  description = "Bucket environment"
  nullable    = false
}

variable "bucket_name" {
  type        = string
  description = "Bucket name"
  nullable    = false
}

variable "bucket_access_key" {
  description = "Bucket static access key"
  type        = string
}

variable "bucket_secret_key" {
  description = "Bucket secret for static access key"
  type        = string
}
