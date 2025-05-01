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
  region = "us-west-2"

  default_tags {
    tags = {
      Name = "minecraft"
    }
  }
}
