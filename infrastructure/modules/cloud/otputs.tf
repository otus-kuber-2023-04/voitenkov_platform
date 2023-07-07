output "tfstate_access_key" {
  value = yandex_iam_service_account_static_access_key.sa-tfstate-static-key.access_key
  sensitive = true
}

output "tfstate_secret_key" {
  value = yandex_iam_service_account_static_access_key.sa-tfstate-static-key.secret_key
  sensitive = true
}