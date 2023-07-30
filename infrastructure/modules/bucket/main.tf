locals {
  bucket = "s3-${var.bucket_project}-${var.bucket_environment}-${var.bucket_name}"
}

resource "yandex_storage_bucket" "bucket" {
  folder_id  = var.bucket_folder_id
  bucket     = local.bucket
  access_key = var.bucket_access_key
  secret_key = var.bucket_secret_key
  
  anonymous_access_flags {
    read        = true
    list        = false
    config_read = false
  }
}

