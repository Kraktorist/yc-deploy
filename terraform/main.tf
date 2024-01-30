locals {
  config = yamldecode(file("${var.env_folder}/${var.env_config_filename}"))
}

provider "yandex" {
  # folder_id = local.config.folder_id
}