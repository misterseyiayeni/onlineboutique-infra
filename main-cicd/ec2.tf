#configure aws profile
provider "aws" {
  region  = "us-east-1"
  profile = "minecraft"
}

# create vpc
# terraform aws create vpc
resource "aws_vpc" "vpc" {
  cidr_block              = var.vpc_cidr
  instance_tenancy        = "default"
  enable_dns_hostnames    = true

  tags      = {
    Name    = "${var.project_name}-vpc"
  }
}

# create internet gateway and attach it to vpc
# terraform aws create internet gateway
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id    = aws_vpc.vpc.id 

  tags      = {
    Name    = "${var.project_name}-igw"
  }
}

# create public subnet az1
# terraform aws create subnet
resource "aws_subnet" "public_subnet_az1" {
  vpc_id                  = aws_vpc.vpc.id 
  cidr_block              = var.public_subnet_az1_cidr
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags      = {
    Name    = "${var.project_name}-public-subnet-az1"
  }
}

# create public subnet az2
# terraform aws create subnet
resource "aws_subnet" "public_subnet_az2" {
  vpc_id                  = aws_vpc.vpc.id 
  cidr_block              = var.public_subnet_az2_cidr
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags      = {
    Name    = "${var.project_name}-public-subnet-az2"
  }
}

# create route table and add public route
# terraform aws create route table
resource "aws_route_table" "public_route_table" {
  vpc_id       = aws_vpc.vpc.id 

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags       = {
    Name     = "${var.project_name}-public-route-table"
  }
}

# associate public subnet az1 to "public route table"
# terraform aws associate subnet with route table
resource "aws_route_table_association" "public_subnet_az1_route_table_association" {
  subnet_id           = aws_subnet.public_subnet_az1.id 
  route_table_id      = aws_route_table.public_route_table.id 
}

# associate public subnet az2 to "public route table"
# terraform aws associate subnet with route table
resource "aws_route_table_association" "public_subnet_2_route_table_association" {
  subnet_id           = aws_subnet.public_subnet_az2.id 
  route_table_id      = aws_route_table.public_route_table.id 
}

# use data source to get a registered amazon linux 2 ami
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

# use data source to get a registered Ubuntu 2 ami

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical account ID for Ubuntu AMIs

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

###JENKINS SERVERS PUBLIC SUBNETS
# EC2 Instance with IAM Role
resource "aws_instance" "jenkins_server" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.large"
  subnet_id              = aws_subnet.public_subnet_az2.id
  key_name               = "postgreskey"
  user_data              = file("jenkins-maven-ansible-setup.sh")
  vpc_security_group_ids = [aws_security_group.jenkins_security_group.id]
  iam_instance_profile = aws_iam_instance_profile.jenkins_instance_profile.name

  tags = {
    Name        = "jenkins server"
    Application = "jenkins"
  }
}

# Network Interface
resource "aws_network_interface" "main_network_interface_jenkins" {
  subnet_id = aws_subnet.public_subnet_az2.id
  tags      = {
    Name = "jenkins_network_interface"
  }
}

# Ensure the IAM role is attached to the instance
# resource "aws_instance_iam_instance_profile" "jenkins_instance_iam_profile" {
#   instance_id = aws_instance.jenkins-server.id
#   # iam_instance_profile = aws_iam_instance_profile.jenkins_instance_profile.name

#   depends_on = [aws_iam_instance_profile.jenkins_instance_profile]
# }


resource "aws_iam_role" "jenkins_role" {
  name               = "jenkins_role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"  # Assuming Jenkins is running on EC2 instance
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "jenkins_policy" {
  name   = "jenkins_policy"
  description = "Policy to access Jenkins server"
  
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:StartInstances",
          "ec2:StopInstances"
          # Add additional permissions as needed for Jenkins access
        ],
        "Resource" : "*"  # Adjust resource scope accordingly
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "jenkins_policy_attachment" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = aws_iam_policy.jenkins_policy.arn
}

# Attach the policy to the EC2 instance
resource "aws_iam_instance_profile" "jenkins_instance_profile" {
  name = "jenkins_instance_profile"
  role = aws_iam_role.jenkins_role.name
}


### NEXUS SERVERS PUBLIC SUBNETS
resource "aws_instance" "Nexus_server" {
  ami = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.medium"
  subnet_id = aws_subnet.public_subnet_az1.id
  key_name = "postgreskey"
  vpc_security_group_ids = [aws_security_group.jenkins_security_group.id]
  user_data              = file("nexus-setup.sh")
  tags = {
    Name = "Nexus server"
  }
}

resource "aws_network_interface" "main_network_interface-Nexus" {
  subnet_id   = aws_subnet.public_subnet_az1.id

  tags = {
    Name = "Nexus_network_interface"
  }
}

### Prometheus SERVERS PUBLIC SUBNETS
###SERVERS PUBLIC SUBNETS
resource "aws_instance" "Prometheus_server" {
  ami = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public_subnet_az2.id
  key_name = "postgreskey"
  vpc_security_group_ids = [aws_security_group.jenkins_security_group.id]
  user_data              = file("prometheus-setup.sh")
  tags = {
    Name = "Prometheus server"
  }
}

resource "aws_network_interface" "main_network_interface-Prometheus" {
  subnet_id   = aws_subnet.public_subnet_az2.id

  tags = {
    Name = "Prometheus_network_interface"
  }
}

###Grafana SERVERS PUBLIC SUBNETS
resource "aws_instance" "Grafana_server" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public_subnet_az1.id
  key_name = "postgreskey"
  vpc_security_group_ids = [aws_security_group.jenkins_security_group.id]
  user_data              = file("grafana-setup.sh")
  tags = {
    Name = "Grafana server"
  }
}

resource "aws_network_interface" "main_network_interface-Grafana" {
  subnet_id   = aws_subnet.public_subnet_az1.id

  tags = {
    Name = "Grafana_network_interface"
  }
}

##SonarQube SERVERS PUBLIC SUBNETS
resource "aws_instance" "SonaQube_server" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.medium"
  subnet_id = aws_subnet.public_subnet_az2.id
  key_name = "postgreskey"
  vpc_security_group_ids = [aws_security_group.jenkins_security_group.id]
  user_data              = file("SonaQube-setup.sh")
  tags = {
    Name = "SonaQube server"
  }
}

resource "aws_network_interface" "main_network_interface-SonaQube" {
  subnet_id   = aws_subnet.public_subnet_az2.id

  tags = {
    Name = "SonaQube_network_interface"
  }
}


# Create security group for the Jenkins instance
resource "aws_security_group" "jenkins_security_group" {
  name        = "jenkins security group"
  description = "Enable Jenkins/Maven access on port 8080/9100"
  vpc_id      = aws_vpc.vpc.id 

  # Ingress rules for Jenkins, Maven, Prometheus, Grafana, SonarQube, and Nexus access
  ingress {
    description = "Jenkins access"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Maven access"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "Prometheus access"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Grafana access"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SonarQube access"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Nexus access"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Common ingress rules for HTTP, HTTPS, and SSH access
  ingress {
    description = "HTTP Access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS Access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Tags
  tags = {
    Name = "jenkins security group"
  }
}