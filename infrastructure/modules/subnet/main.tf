data "yandex_vpc_subnet" "subnet" {
  name           = var.subnet_name
  
  depends_on     = [yandex_vpc_subnet.subnet] 
} 

resource "yandex_vpc_subnet" "subnet" {
  name           = var.subnet_name
  zone           = var.subnet_zone
  network_id     = var.subnet_network_id
  v4_cidr_blocks = var.subnet_v4_cidr_blocks
}
