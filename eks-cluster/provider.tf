terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

#configure aws profile
provider "aws" {
  region  = "us-east-2"
}
