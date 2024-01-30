resource "yandex_iam_service_account" "service-account" {
  for_each = local.config.service_accounts
  name     = each.key
}

locals {
  permissions = flatten([
    for name, service_account in local.config.service_accounts : [
      for entry in try(service_account.roles, []) : {
        sa_name = name
        role    = entry
      }
    ]
  ])
}

resource "yandex_resourcemanager_folder_iam_member" "ig-roles" {
  for_each = {
    for entry in try(local.permissions, []) : "${entry.sa_name}-${entry.role}" => entry
  }
  folder_id = [for v in yandex_iam_service_account.service-account : v.folder_id if each.value.sa_name == v.name][0]
  member    = "serviceAccount:${yandex_iam_service_account.service-account[each.value.sa_name].id}"
  role      = each.value.role
}