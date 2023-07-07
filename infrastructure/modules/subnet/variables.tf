variable "subnet_name" {
  type        = string
  description = "Subnet name"
}

variable "subnet_zone" {
  type        = string
  description = "Subnet availability zone"
  default     = "ru-central1-a"
}

variable "subnet_network_id" {
  type        = string
  description = "Subnet network ID"
}

variable "subnet_v4_cidr_blocks" {
  type        = list
  description = "Subnet v4 CIDR blocks"
}