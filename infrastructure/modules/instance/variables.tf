variable "instance_project" {
  type        = string
  description = "Instance project (cloud)"
  nullable    = false
}

variable "instance_environment" {
  type        = string
  description = "Instance environment"
  nullable    = false
}

variable "instance_no" {
  type        = number
  description = "Instance No."
  nullable    = false
}

variable "instance_name" {
  type        = string
  description = "Instance name"
  nullable    = false
}

variable "instance_user_data_file" {
  type        = string
  description = "Instance user data file"
  nullable    = false
}

variable "instance_zone" {
  type        = string
  description = "Yandex Cloud compute default zone"
  default     = "ru-central1-a"
}

variable "instance_platform_id" {
  default     = "standard-v3"
  type        = string
  description = "Platform ID for instance"
  nullable    = false
}

variable "instance_service_account_name" {
  type        = string
  description = "Instance service account name"
  nullable    = false
}

variable "instance_preemptible" {
  default     = false
  type        = bool
  description = "Instance scheduling policy"
  nullable    = false
}

variable "instance_cores" {
  default     = 2
  type        = number
  description = "Instance cores quantity"
  nullable    = false
}

variable "instance_core_fraction" {
  default     = 100
  type        = number
  description = "Instance core fraction"
  nullable    = false
}

variable "instance_memory" {
  default     = 2
  type        = number
  description = "Instance memory amount"
  nullable    = false
}

variable "instance_image_id" {
  type        = string
  default     = "fd8emvfmfoaordspe1jr" # ubuntu-22-04-lts-v20230130
  description = "Image ID for boot disk"
}

variable "instance_disk_size" {
  default     = 30
  type        = number
  description = "Instance disk size"
  nullable    = false
}

variable "instance_subnet_id" {
  type        = string
  description = "Instance network interface subnet"
  nullable    = false
}

variable "instance_nat" {
  default     = false
  type        = bool
  description = "Instance NAT enable/disable"
  nullable    = false
}

variable "instance_security_group_ids" {
  type        = list
  description = "Instance security group IDs"
}

variable "instance_serial_port_enable" {
  default     = 0
  type        = number
  description = "Instance serial port enable/disable"
  nullable    = false
}