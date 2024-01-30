locals {
  metadata = {
    for ig_name, instance_group in merge(try(local.config.instance_groups, {}), try(local.config.instances, {})) :
    ig_name => {
      docker-compose = coalescelist([for key, entry in instance_group.metadata : file(entry.file) if key == "docker-compose"], [null])[0]
      ssh-keys       = coalescelist([for key, entry in instance_group.metadata : "${entry.username}:${file(entry.file)}" if key == "ssh-keys"], [null])[0]
    }
  }
}

data "yandex_compute_image" "image" {
  for_each = local.config.instances
  family   = try(each.value.image_family, "container-optimized-image")
}

resource "yandex_compute_instance" "instance" {
  for_each    = local.config.instances
  name        = each.key
  platform_id = "standard-v2"
  zone = [for v in yandex_vpc_subnet.network : v.zone if each.value.network.subnet == v.name][0]

  resources {
    cores         = each.value.resources.cores
    memory        = each.value.resources.memory
    core_fraction = try(each.value.resources.core_fraction, 5)
  }

  boot_disk {
    initialize_params {
      type     = try(each.value.resources.disk_type, "network-hdd")
      size     = each.value.resources.disk_size
      image_id = data.yandex_compute_image.image[each.key].id
    }
  }

  dynamic "secondary_disk" {
    for_each = contains(keys(each.value.resources), "secondary_disk_size") ? [1] : []
    content {
      disk_id = yandex_compute_disk.secondary_disk[each.key].id
      auto_delete = true
      device_name = "vdb"
    }
  }

  network_interface {
    subnet_id = [for v in yandex_vpc_subnet.network : v.id if each.value.network.subnet == v.name][0]
    nat       = try(each.value.network.nat, false)
  }

  metadata = local.metadata[each.key]
}

resource "yandex_compute_disk" "secondary_disk" {
  for_each = { for k, v in local.config.instances : k => v if contains(keys(v.resources), "secondary_disk_size")  }
  name     = "${each.key}-secondary-disk"
  type     = "network-ssd"
  size = each.value.resources.secondary_disk_size
  zone = [for v in yandex_vpc_subnet.network : v.zone if each.value.network.subnet == v.name][0]
}