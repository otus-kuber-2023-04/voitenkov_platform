output "k8s_alb_ip_address" {
  value = yandex_vpc_address.ip-momo-store-prod-k8s-alb.external_ipv4_address.0.address
}