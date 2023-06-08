resource "yandex_iam_service_account" "service_account" {
  name        = var.sa_name
  description = var.sa_description
}

resource "yandex_resourcemanager_folder_iam_member" "folder_iam_member" {
  folder_id   = var.sa_folder_id
  role        = var.sa_role
  member      = "serviceAccount:${yandex_iam_service_account.service_account.id}"

  depends_on  = [yandex_iam_service_account.service_account]
}