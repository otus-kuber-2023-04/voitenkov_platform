locals {
  project_environment               = "${var.folder_project} ${var.folder_environment}"
  cloud_id                          = "${data.yandex_resourcemanager_cloud.cloud.cloud_id}"
  cloud_name                        = var.folder_project
  folder_id                         = "${yandex_resourcemanager_folder.folder.id}"
  folder_name                       = "${var.folder_environment}-folder"
  folder_description                = "Folder for ${local.project_environment} environment"
  sa_tf_name                        = "sa-${var.folder_project}-${var.folder_environment}-tf"
  sa_tf_description                 = "Service account for Terraform deploy in ${local.project_environment} environment"
  sa_tfstate_name                   = "sa-${var.folder_project}-${var.folder_environment}-tfstate"
  sa_tfstate_description            = "Service account for S3 backend for Terraform state in ${local.project_environment} environment"
  sa_tfstate_static_key_description = "Static access key for S3 backend for Terraform state in ${local.project_environment} environment"
  s3_tfstate_bucket                 = "s3-${var.folder_project}-${var.folder_environment}-tfstate"
}

data "yandex_resourcemanager_cloud" "cloud" {
  name = local.cloud_name
}

resource "yandex_resourcemanager_folder" "folder" {
  cloud_id    = local.cloud_id
  name        = local.folder_name
  description = local.folder_description
}

resource "yandex_iam_service_account" "sa-tf" {
  folder_id   = local.folder_id
  name        = local.sa_tf_name
  description = local.sa_tf_description

  depends_on = [yandex_resourcemanager_folder.folder]  
}

resource "yandex_resourcemanager_folder_iam_binding" "folder-admin" {
  folder_id   = local.folder_id
  role        = "admin"
  members = [
    "serviceAccount:${yandex_iam_service_account.sa-tf.id}"
  ]

  depends_on  = [yandex_iam_service_account.sa-tf]
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

  depends_on = [
    yandex_iam_service_account_static_access_key.sa-tfstate-static-key]  
}