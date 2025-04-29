# Variables
variable "project_name" {
  description = "Project Name"
  type        = string
  default     = "minecraft"  # Update with your desired CIDR block
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"  # Update with your desired CIDR block
}

variable "public_subnet_az1_cidr" {
  description = "CIDR block for public subnet in AZ1"
  type        = string
  default     = "10.0.1.0/24"  # Update with your desired CIDR block
}

variable "public_subnet_az2_cidr" {
  description = "CIDR block for public subnet in AZ2"
  type        = string
  default     = "10.0.2.0/24"  # Update with your desired CIDR block
}

