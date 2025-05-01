variable "cluster_name" {
  default = "minecraft-eks-cluster"
}

variable "cluster_version" {
  default = "5.0"
}

variable "region" {
  default = "us-east-2"
}

variable "ingress_ports" {
  description = "Managed node groups use this security group for control-plane-to-data-plane communication."
  default     = ["22", "80", "443", "8080", "9090", "9443", "2049"]
}
