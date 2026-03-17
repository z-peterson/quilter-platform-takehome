resource "kubernetes_namespace" "app" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_deployment" "app" {
  metadata {
    name      = "quilter-api"
    namespace = kubernetes_namespace.app.metadata[0].name

    labels = {
      "app.kubernetes.io/name"       = "quilter-api"
      "app.kubernetes.io/version"    = var.app_version
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "quilter-api"
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"    = "quilter-api"
          "app.kubernetes.io/version" = var.app_version
        }
      }

      spec {
        container {
          name  = "quilter-api"
          image = "${var.image}:${var.app_version}"

          image_pull_policy = "Never"

          port {
            container_port = 8080
          }

          env {
            name  = "APP_VERSION"
            value = var.app_version
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/healthz"
              port = 8080
            }
            initial_delay_seconds = 3
            period_seconds        = 5
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "128Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "app" {
  metadata {
    name      = "quilter-api"
    namespace = kubernetes_namespace.app.metadata[0].name

    labels = {
      "app.kubernetes.io/name"       = "quilter-api"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  spec {
    type = "ClusterIP"

    selector = {
      "app.kubernetes.io/name" = "quilter-api"
    }

    port {
      port        = 80
      target_port = 8080
    }
  }
}
