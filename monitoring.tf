resource "time_sleep" "wait_for_kubernetes" {
  depends_on = [
    module.eks
  ]

  create_duration = "20s"
}

resource "kubernetes_namespace" "kube-namespace" {
  depends_on = [time_sleep.wait_for_kubernetes]
  metadata {
    name = "prometheus"
  }
}

resource "helm_release" "prometheus" {
  depends_on = [kubernetes_namespace.kube-namespace, time_sleep.wait_for_kubernetes]
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.kube-namespace.id
  create_namespace = false
  version    = "51.3.0"
  values = [
    file("values.yaml")
  ]
  timeout = 2000

  set {
    name  = "podSecurityPolicy.enabled"
    value = true
  }

  set {
    name  = "prometheus.server.persistentVolume.enabled"
    value = false
  }

  # Map values using yamlencode for Prometheus resource limits and requests
  set {
    name  = "prometheus.server.resources"
    value = yamlencode({
      limits = {
        cpu    = "200m"
        memory = "50Mi"
      }
      requests = {
        cpu    = "100m"
        memory = "30Mi"
      }
    })
  }
}
