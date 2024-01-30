resource "yandex_kubernetes_cluster" "cluster" {
  depends_on = [ yandex_iam_service_account.service-account ]
  for_each = try(local.config.kubernetes, {})
  name        = each.key

  network_id = [for v in yandex_vpc_subnet.network : v.network_id if each.value.subnet == v.name][0]

  master {
    version = each.value.version

    master_location {
        zone = [for v in yandex_vpc_subnet.network : v.zone if each.value.subnet == v.name][0]
    }

    public_ip = each.value.public_ip

    # security_group_ids = ["${yandex_vpc_security_group.security_group_name.id}"]

#     maintenance_policy {
#       auto_upgrade = true

#       maintenance_window {
#         start_time = "15:00"
#         duration   = "3h"
#       }
#     }

#     master_logging {
#       enabled = true
#       log_group_id = "${yandex_logging_group.log_group_resoruce_name.id}"
#       kube_apiserver_enabled = true
#       cluster_autoscaler_enabled = true
#       events_enabled = true
#       audit_enabled = true
#     }
   }

  service_account_id      = [for v in yandex_iam_service_account.service-account : v.id if each.value.service_account_name == v.name][0]
  node_service_account_id = [for v in yandex_iam_service_account.service-account : v.id if each.value.node_service_account_name == v.name][0]

#   labels = {
#     my_key       = "my_value"
#     my_other_key = "my_other_value"
#   }

  release_channel = "RAPID"
  network_policy_provider = "CALICO"

#   kms_provider {
#     key_id = "${yandex_kms_symmetric_key.kms_key_resource_name.id}"
#   }
}


resource "yandex_kubernetes_node_group" "node_group" {
  for_each = try(local.config.kubernetes, {})
  cluster_id = [for v in yandex_kubernetes_cluster.cluster : v.id if each.key == v.name][0]
  name        = each.value.instance_template.name
  version     = try(each.value.node_version, each.value.version)

  instance_template {
    platform_id = "standard-v2"

    network_interface {
      nat                = try(each.value.instance_template.nat, false)
      subnet_ids         = [for v in yandex_vpc_subnet.network : v.id if each.value.subnet == v.name]
    }

    resources {
      memory = each.value.instance_template.memory
      cores  = each.value.instance_template.cores
    }

    boot_disk {
      type = try(each.value.resources.disk_type, "network-hdd")
      size = try(each.value.resources.disk_size, 64)
    }

    scheduling_policy {
      preemptible = false
    }

    container_runtime {
      type = each.value.instance_template.container_runtime
    }
  }

  scale_policy {
    fixed_scale {
      size = each.value.instance_template.count
    }
  }

#   allocation_policy {
#     location {
#       zone = "ru-central1-a"
#     }
#   }

#   maintenance_policy {
#     auto_upgrade = true
#     auto_repair  = true

#     maintenance_window {
#       day        = "monday"
#       start_time = "15:00"
#       duration   = "3h"
#     }

#     maintenance_window {
#       day        = "friday"
#       start_time = "10:00"
#       duration   = "4h30m"
#     }
#   }
}