output "id" {
  description = "VPC subnet ID"
  value       = data.yandex_vpc_subnet.subnet.subnet_id
}