# we need to create the AWS VPC itself. Here it's very important to enable dns support 
# and hostnames, especially if you are planning to use the EFS file system in your cluster. 
# Otherwise, the CSI driver will fail to resolve the EFS endpoint. Currently, 
# AWS Fargate does not support EBS volumes, so EFS is the only option for you if you want to run 
# stateful workloads in your Kubernetes cluster.

# Create a vpc resouce
resource "aws_vpc" "online-shop-eks-cluster-main" {
  cidr_block = "10.20.0.0/16"

  # Must be enabled for EFS
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "online-shop-VPC"
  }
}


## Create an IGW. It is used to provide internet access directly from the public subnets 
# and indirectly from private subnets by using a NAT gateway.

resource "aws_internet_gateway" "online-shop-eks-cluster-igw" {
  vpc_id = aws_vpc.online-shop-eks-cluster-main.id

  tags = {
    Name = "online-shop-igw"
  }
}


# Now we need to create four subnets. Two private subnets and two public subnets. 
# If you are using a different region, you need to update availability zones. Also, 
# it's very important to tag your subnets with the following labels. 
# Internal-elb tag used by EKS to select subnets to create private load balancers and elb tag for public load balancers. 
# Also, you need to have a cluster tag with owned or shared value.

resource "aws_subnet" "private-us-west-2a" {
  vpc_id            = aws_vpc.online-shop-eks-cluster-main.id
  cidr_block        = "10.20.0.0/24"
  availability_zone = "us-west-2a"

  tags = {
    "Name"                                      = "private-us-west-2a"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

resource "aws_subnet" "private-us-west-2b" {
  vpc_id            = aws_vpc.online-shop-eks-cluster-main.id
  cidr_block        = "10.20.32.0/24"
  availability_zone = "us-west-2b"

  tags = {
    "Name"                                      = "private-us-west-2b"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

resource "aws_subnet" "public-us-west-2a" {
  vpc_id                  = aws_vpc.online-shop-eks-cluster-main.id
  cidr_block              = "10.20.64.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true

  tags = {
    "Name"                                      = "public-us-west-2a"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

resource "aws_subnet" "public-us-west-2b" {
  vpc_id                  = aws_vpc.online-shop-eks-cluster-main.id
  cidr_block              = "10.20.96.0/20"
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = true

  tags = {
    "Name"                                      = "public-us-west-2b"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}


resource "aws_eip" "online-shop-eks-cluster-nat" {
  domain = "vpc"

  tags = {
    Name = "online-shop-nat"
  }
}

# Create a NAT gateway

resource "aws_nat_gateway" "online-shop-eks-cluster-nat" {
  allocation_id = aws_eip.online-shop-eks-cluster-nat.id
  subnet_id     = aws_subnet.public-us-west-2a.id

  tags = {
    Name = "online-shop-nat"
  }

  depends_on = [aws_internet_gateway.online-shop-eks-cluster-igw]
}



# The last components that we need to create before we can start provisioning EKS are route tables.
# The first is the private route table with the default route to the NAT Gateway. 
# The second is a public route table with the default route to the Internet Gateway. 
# Finally, we need to associate previously created subnets with these route tables. 
# Two private subnets and two public subnets.

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.online-shop-eks-cluster-main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.online-shop-eks-cluster-nat.id
  }

  tags = {
    Name = "online-shop-private"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.online-shop-eks-cluster-main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.online-shop-eks-cluster-igw.id
  }

  tags = {
    Name = "online-shop-public"
  }
}

resource "aws_route_table_association" "private-us-west-2a" {
  subnet_id      = aws_subnet.private-us-west-2a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private-us-west-2b" {
  subnet_id      = aws_subnet.private-us-west-2b.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "public-us-west-2a" {
  subnet_id      = aws_subnet.public-us-west-2a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public-us-west-2b" {
  subnet_id      = aws_subnet.public-us-west-2b.id
  route_table_id = aws_route_table.public.id
}
