

resource "kubernetes_namespace" "aws_load_balancer_controller" {
  metadata {
    labels = {
      app = "online-shop-app"
    }
    name = "aws-load-balancer-controller"
  }
}

resource "kubernetes_namespace" "online-shop-application" {
  metadata {
    labels = {
      app = "online-shop-app"
    }
    name = "test-env"
  }
}

resource "kubernetes_namespace" "online-shop-applications" {
  metadata {
    labels = {
      app = "online-shop-app"
    }
    name = "prod-env"
  }
}