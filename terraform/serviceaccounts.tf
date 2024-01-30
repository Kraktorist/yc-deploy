# resource "yandex_iam_service_account" "service-account" {
#   for_each = local.config.service_accounts
#   name     = each.key
# }

# locals {
#   permissions = flatten([
#     for name, service_account in local.config.service_accounts : [
#       for entry in service_account.roles : {
#         sa_name = name
#         role    = entry
#       }
#     ]
#   ])
# }

# resource "yandex_resourcemanager_folder_iam_member" "ig-roles" {
#   for_each = {
#     for entry in local.permissions : "${entry.sa_name}-${entry.role}" => entry
#   }
#   folder_id = local.config.folder_id
#   member    = "serviceAccount:${yandex_iam_service_account.service-account[each.value.sa_name].id}"
#   role      = each.value.role
# }