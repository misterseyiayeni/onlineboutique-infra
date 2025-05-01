# We need to declare aws terraform provider. You may want to update the aws region

# terraform {
#   backend "s3" {
#     # Replace this with your bucket name!
#     bucket         = "minecraft"
#     key            = "minecraft/terraform.tfstate"
#     region         = "us-east-2"

#     # Replace this with your DynamoDB table name!
#     dynamodb_table = "minecraft"
#   }
  
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "4.67.0"
#     }
#   }
# }

#configure aws profile
provider "aws" {
  region  = "us-east-2"
}

# Create an S3 bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = "minecraft-application-bucket"
  acl    = "private"
}

# Create an SQS queue
resource "aws_sqs_queue" "my_queue" {
  name = "minecraft-application-queue"
}


data "aws_eks_cluster_auth" "minecraft-eks-cluster" {
  name = aws_eks_cluster.minecraft-eks-cluster.id
}

data "aws_eks_cluster" "minecraft-eks-cluster" {
  name = aws_eks_cluster.minecraft-eks-cluster.id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.minecraft-eks-cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.minecraft-eks-cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.minecraft-eks-cluster.token
  # load_config_file       = false
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.minecraft-eks-cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.minecraft-eks-cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.minecraft-eks-cluster.token
    # load_config_file       = false
  }
}
