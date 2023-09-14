locals {
  cloud_id                          = yandex_resourcemanager_cloud.cloud.id
  folder_id                         = yandex_resourcemanager_folder.folder.id
  folder_name                       = "adm-folder"
  folder_description                = "Folder for S3 backend for ${var.cloud_project} cloud Terraform state and administrative entities"
  sa_tfstate_name                   = "sa-${var.cloud_project}-adm-tfstate"
  sa_tfstate_description            = "Service account for S3 backend for ${var.cloud_project} cloud Terraform state"
  sa_tfstate_static_key_description = "Static access key for S3 backend for ${var.cloud_project} cloud Terraform state"
  s3_tfstate_bucket                 = "s3-${var.cloud_project}-adm-tfstate"
}

resource "yandex_resourcemanager_cloud" "cloud" {
  name            = var.cloud_project
  organization_id = var.cloud_organization_id
}

resource "yandex_billing_cloud_binding" "cloud_binding" {
  billing_account_id = var.cloud_billing_account_id
  cloud_id           = local.cloud_id

  depends_on = [yandex_resourcemanager_cloud.cloud]    
}

resource "yandex_resourcemanager_folder" "folder" {
  cloud_id    = local.cloud_id
  name        = local.folder_name
  description = local.folder_description

  depends_on = [yandex_billing_cloud_binding.cloud_binding]
}

resource "yandex_iam_service_account" "sa-tfstate" {
  folder_id   = local.folder_id
  name        = local.sa_tfstate_name
  description = local.sa_tfstate_description

  depends_on = [yandex_resourcemanager_folder.folder]
}

resource "yandex_resourcemanager_folder_iam_member" "sa-tfstate-storage-admin" {
  folder_id   = local.folder_id
  role        = "storage.admin" # admin role is need for bucket versioning
  member      = "serviceAccount:${yandex_iam_service_account.sa-tfstate.id}"

  depends_on  = [yandex_iam_service_account.sa-tfstate]
}

resource "yandex_iam_service_account_static_access_key" "sa-tfstate-static-key" {
  service_account_id = yandex_iam_service_account.sa-tfstate.id
  description        = local.sa_tfstate_static_key_description

  depends_on = [yandex_iam_service_account.sa-tfstate]
}

resource "yandex_storage_bucket" "s3-tfstate" {
  folder_id  = local.folder_id
  bucket     = local.s3_tfstate_bucket
  access_key = yandex_iam_service_account_static_access_key.sa-tfstate-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-tfstate-static-key.secret_key
  
  versioning {
    enabled = true
  }

  depends_on = [yandex_iam_service_account_static_access_key.sa-tfstate-static-key]  
}
