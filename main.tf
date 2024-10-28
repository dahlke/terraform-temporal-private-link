# Provider configuration
provider "aws" {
  region = var.aws_region
}

# Local variables
locals {
  service_name_map = {
    "ap-northeast-1" = "com.amazonaws.vpce.ap-northeast-1.vpce-svc-08f34c33f9fb8a48a"
    "ap-northeast-2" = "com.amazonaws.vpce.ap-northeast-2.vpce-svc-08c4d5445a5aad308"
    "ap-south-1"     = "com.amazonaws.vpce.ap-south-1.vpce-svc-0ad4f8ed56db15662"
    "ap-south-2"     = "com.amazonaws.vpce.ap-south-2.vpce-svc-08bcf602b646c69c1"
    "ap-southeast-1" = "com.amazonaws.vpce.ap-southeast-1.vpce-svc-05c24096fa89b0ccd"
    "ap-southeast-2" = "com.amazonaws.vpce.ap-southeast-2.vpce-svc-0634f9628e3c15b08"
    "ca-central-1"   = "com.amazonaws.vpce.ca-central-1.vpce-svc-080a781925d0b1d9d"
    "eu-central-1"   = "com.amazonaws.vpce.eu-central-1.vpce-svc-073a419b36663a0f3"
    "eu-west-1"      = "com.amazonaws.vpce.eu-west-1.vpce-svc-04388e89f3479b739"
    "eu-west-2"      = "com.amazonaws.vpce.eu-west-2.vpce-svc-0ac7f9f07e7fb5695"
    "sa-east-1"      = "com.amazonaws.vpce.sa-east-1.vpce-svc-0ca67a102f3ce525a"
    "us-east-1"      = "com.amazonaws.vpce.us-east-1.vpce-svc-0822256b6575ea37f"
    "us-east-2"      = "com.amazonaws.vpce.us-east-2.vpce-svc-01b8dccfc6660d9d4"
    "us-west-2"      = "com.amazonaws.vpce.us-west-2.vpce-svc-0f44b3d7302816b94"
  }
  service_name = local.service_name_map[var.aws_region]
}

# Data source to get the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.prefix}-temporal-cloud-privatelink-vpc"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-temporal-cloud-privatelink-vpc-igw"
  }
}

# Create Subnet
resource "aws_subnet" "privatelink_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.prefix}-temporal-cloud-privatelink-subnet"
  }
}

# Create Route Table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.prefix}-temporal-cloud-privatelink-vpc-route-table"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.privatelink_subnet.id
  route_table_id = aws_route_table.main.id
}

# Generate SSH Key Pair
resource "tls_private_key" "privatelink_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create EC2 Key Pair
resource "aws_key_pair" "privatelink_key" {
  key_name   = "${var.prefix}-temporal-cloud-privatelink-key"
  public_key = tls_private_key.privatelink_key.public_key_openssh
}

# Create Security Group for Temporal Cloud port and SSH
resource "aws_security_group" "temporal_cloud" {
  name = "${var.prefix}-temporal-cloud-privatelink-sg"

  description = "Security group for Temporal Cloud PrivateLink and SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 7233
    to_port     = 7233
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-temporal-cloud-privatelink-sg"
  }
}

# Launch EC2 Instance
resource "aws_instance" "privatelink_test" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.privatelink_key.key_name
  subnet_id     = aws_subnet.privatelink_subnet.id

  vpc_security_group_ids = [aws_security_group.temporal_cloud.id]

  metadata_options {
    http_tokens   = "required" # This sets the requirement for metadata HTTP tokens
    http_endpoint = "enabled"  # Ensure metadata is available
  }

  tags = {
    Name = "${var.prefix}-temporal-cloud-privatelink-test-instance"
  }
}

# Create the VPC Endpoint
resource "aws_vpc_endpoint" "temporal_cloud" {
  vpc_id             = aws_vpc.main.id
  service_name       = local.service_name
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.privatelink_subnet.id]
  security_group_ids = [aws_security_group.temporal_cloud.id]

  # TODO
  # private_dns_enabled = true

  tags = {
    Name = "${var.prefix}-temporal-cloud-privatelink-endpoint"
  }
}

# Create Network ACL
resource "aws_network_acl" "main" {
  vpc_id = aws_vpc.main.id

  # Allow all inbound traffic
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # Block outbound traffic on port 7233
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 7233
    to_port    = 7233
  }

  # Allow all other outbound traffic
  egress {
    protocol   = -1
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "${var.prefix}-temporal-cloud-privatelink-nacl"
  }
}

# Associate NACL with the subnet
resource "aws_network_acl_association" "main" {
  network_acl_id = aws_network_acl.main.id
  subnet_id      = aws_subnet.privatelink_subnet.id
}
