provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# Jenkins Deployment using Helm
resource "helm_release" "jenkins" {
  name       = "jenkins"
  chart      = "jenkins/jenkins"
  namespace  = "jenkins"
  create_namespace = true

  values = [
    file("k8s/jenkins_values.yaml")
  ]

  set {
    name  = "controller.ingress.enabled"
    value = "true"
  }

  set {
    name  = "controller.ingress.hosts[0]"
    value = "jenkins.k8s.mgrant.in"  # Replace with your Route 53 domain
  }

  set {
    name  = "controller.ingress.annotations.\"alb.ingress.kubernetes.io/scheme\""
    value = "internet-facing"
  }

  set {
    name  = "controller.ingress.annotations.\"alb.ingress.kubernetes.io/group.name\""
    value = "devops-ingress"
  }

  set {
    name  = "controller.ingress.annotations.\"alb.ingress.kubernetes.io/target-type\""
    value = "ip"
  }
}

# ArgoCD Deployment using Helm
resource "helm_release" "argocd" {
  name       = "argocd"
  chart      = "argo-cd/argo-cd"
  namespace  = "argocd"
  create_namespace = true

  values = [
    file("k8s/argocd_values.yaml")
  ]

  set {
    name  = "server.ingress.enabled"
    value = "true"
  }

  set {
    name  = "server.ingress.hosts[0]"
    value = "argocd.k8s.mgrant.in"  # Replace with your Route 53 domain
  }

  set {
    name  = "server.ingress.annotations.\"alb.ingress.kubernetes.io/scheme\""
    value = "internet-facing"
  }

  set {
    name  = "server.ingress.annotations.\"alb.ingress.kubernetes.io/group.name\""
    value = "devops-ingress"
  }

  set {
    name  = "server.ingress.annotations.\"alb.ingress.kubernetes.io/target-type\""
    value = "ip"
  }
}

# Grafana Deployment using Helm
resource "helm_release" "grafana" {
  name       = "grafana"
  chart      = "grafana/grafana"
  namespace  = "monitoring"
  create_namespace = true

  values = [
    file("k8s/grafana_values.yaml")
  ]

  set {
    name  = "ingress.enabled"
    value = "true"
  }

  set {
    name  = "ingress.hosts[0]"
    value = "grafana.k8s.mgrant.in"  # Replace with your Route 53 domain
  }

  set {
    name  = "ingress.annotations.\"alb.ingress.kubernetes.io/scheme\""
    value = "internet-facing"
  }

  set {
    name  = "ingress.annotations.\"alb.ingress.kubernetes.io/group.name\""
    value = "devops-ingress"
  }

  set {
    name  = "ingress.annotations.\"alb.ingress.kubernetes.io/target-type\""
    value = "ip"
  }
}

# Prometheus Deployment using Helm
resource "helm_release" "prometheus" {
  name       = "prometheus"
  chart      = "prometheus-community/prometheus"
  namespace  = "monitoring"
  create_namespace = true

  values = [
    file("k8s/prometheus_values.yaml")
  ]

  set {
    name  = "server.ingress.enabled"
    value = "true"
  }

  set {
    name  = "server.ingress.hosts[0]"
    value = "prometheus.k8s.mgrant.in"  # Replace with your Route 53 domain
  }

  set {
    name  = "server.ingress.annotations.\"alb.ingress.kubernetes.io/scheme\""
    value = "internet-facing"
  }

  set {
    name  = "server.ingress.annotations.\"alb.ingress.kubernetes.io/group.name\""
    value = "devops-ingress"
  }

  set {
    name  = "server.ingress.annotations.\"alb.ingress.kubernetes.io/target-type\""
    value = "ip"
  }
}

# Outputs for all DevOps tools URLs
output "jenkins_url" {
  description = "URL for Jenkins"
  value       = "https://jenkins.k8s.mgrant.in"  # Replace with your actual domain
}

output "argocd_url" {
  description = "URL for ArgoCD"
  value       = "https://argocd.k8s.mgrant.in"  # Replace with your actual domain
}

output "grafana_url" {
  description = "URL for Grafana"
  value       = "https://grafana.k8s.mgrant.in"  # Replace with your actual domain
}

output "prometheus_url" {
  description = "URL for Prometheus"
  value       = "https://prometheus.k8s.mgrant.in"  # Replace with your actual domain
}
