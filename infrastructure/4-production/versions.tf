terraform {
  required_version = ">= 1.1.6"
  
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.87.0"
    }
  }

  backend "s3" {
    endpoint                    = "storage.yandexcloud.net"
    bucket                      = "s3-momo-store-prod-tfstate"
    region                      = "ru-central-1a"
    key                         = "terraform/momo-store-prod.tfstate"
    skip_region_validation      = true
    skip_credentials_validation = true
  }
}