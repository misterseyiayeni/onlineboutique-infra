variable "cluster_name" {
  default = "online-shop-eks-cluster"
}

variable "cluster_version" {
  default = "1.32"
}

variable "region" {
  default = "us-west-2"
}

variable "ingress_ports" {
  description = "Managed node groups use this security group for control-plane-to-data-plane communication."
  default     = ["22", "80", "443", "8080", "9090", "9093", "9443", "2049" , "30090"]
}
