# The next step is to create an EKS control plane without any additional nodes. 
# This control plane can be used to attach self-managed, 
# and aws managed nodes as well as you can create Fargate profiles.

resource "aws_security_group" "online-shop-eks-cluster" {
  name        = "online-shop-EKS-cluster-sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.online-shop-eks-cluster-main.id

  dynamic "ingress" {
    for_each = var.ingress_ports
    iterator = ports
    content {
      from_port   = ports.value
      to_port     = ports.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]

    }
  }
# Allow NodePort range (30000-32767)
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow NodePort range for Kubernetes services"
  }

  #outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
}


# First of all, let's create an IAM role for EKS. It will use it to make API calls to AWS services, 
# for example, to create managed node pools.


resource "aws_iam_role" "online-shop-eks-cluster" {
  name = "eks-cluster-${var.cluster_name}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# Then we need to attach AmazonEKSClusterPolicy to this role.

resource "aws_iam_role_policy_attachment" "online-shop-eks-cluster-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.online-shop-eks-cluster.name
}


# specify two private and two public subnets. AWS Fargate can only use private subnets with NAT gateway to deploy your pods. 
# Public subnets can be used for load balancers to expose your application to the internet.

resource "aws_eks_cluster" "online-shop-eks-cluster" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.online-shop-eks-cluster.arn

  vpc_config {
    security_group_ids      = [aws_security_group.online-shop-eks-cluster.id]
    endpoint_private_access = false
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]

    subnet_ids = [
      aws_subnet.private-us-west-2a.id,
      aws_subnet.private-us-west-2b.id,
      aws_subnet.public-us-west-2a.id,
      aws_subnet.public-us-west-2b.id
    ]
  }

  depends_on = [aws_iam_role_policy_attachment.online-shop-eks-cluster-policy]
}
