output "kube_api" {
    value = [for v in yandex_kubernetes_cluster.cluster : v.master.0.external_v4_endpoint ]
}