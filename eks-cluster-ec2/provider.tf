# We need to declare aws terraform provider. You may want to update the aws region

# terraform {
#   backend "s3" {
#     bucket = "online-shop"
#     key    = "online-shop/terraform.tfstate"
#     region = "us-west-2"
#     # dynamodb_table = "online-shop"  # commented out to disable locking
#   }

#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "4.67.0"
#     }
#   }
# }



provider "aws" {
  region = "us-west-2"

  default_tags {
    tags = {
      Name = "minecraft"
    }
  }
}


# Create an S3 bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = "online-shop-application-bucket"
}


# Create an SQS queue
resource "aws_sqs_queue" "my_queue" {
  name = "online-shop-application-queue"
}


data "aws_eks_cluster_auth" "online-shop-eks-cluster" {
  name = aws_eks_cluster.online-shop-eks-cluster.id
}

data "aws_eks_cluster" "online-shop-eks-cluster" {
  name = aws_eks_cluster.online-shop-eks-cluster.id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.online-shop-eks-cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.online-shop-eks-cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.online-shop-eks-cluster.token
  # load_config_file       = false
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.online-shop-eks-cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.online-shop-eks-cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.online-shop-eks-cluster.token
    # load_config_file       = false
  }
}
