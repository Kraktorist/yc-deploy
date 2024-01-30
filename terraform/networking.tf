resource "yandex_vpc_network" "network" {
  name = local.config.network.name
}

resource "yandex_vpc_gateway" "egress-gateway" {
  name = "egress-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "rt" {
  network_id = yandex_vpc_network.network.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.egress-gateway.id
  }
}

resource "yandex_vpc_subnet" "network" {
  for_each       = local.config.network.subnets
  network_id     = yandex_vpc_network.network.id
  name           = each.key
  v4_cidr_blocks = each.value.v4_cidr_blocks
  zone           = each.value.zone
  route_table_id = yandex_vpc_route_table.rt.id
}

resource "yandex_vpc_address" "addr" {
  for_each       = local.config.network.ip_addresses
  name = each.key
  external_ipv4_address  {
    zone_id = each.value.zone
  }
}