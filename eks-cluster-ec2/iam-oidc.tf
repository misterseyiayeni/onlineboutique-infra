# You can associate an IAM role with a Kubernetes service account. 
# This service account can then provide AWS permissions to the containers in any pod that uses that service account. 
# With this feature, you no longer need to provide extended permissions to all Kubernetes 
# nodes so that pods on those nodes can call AWS APIs.

data "tls_certificate" "online-shop-eks-cluster" {
  url = aws_eks_cluster.online-shop-eks-cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "online-shop-eks-cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.online-shop-eks-cluster.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.online-shop-eks-cluster.identity[0].oidc[0].issuer
}
