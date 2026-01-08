terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  profile = "tf"
  #  Possible to pass those variables directly with the following values
  #  region     = var.region
  #  access_key = var.access_key
  #  secret_key = var.secret_key
}

# Network configuration, creating a vpc with subnets, an internet gateway and the appropriate routing.
# TO MODIFY TO USE A LOAD BALANCER INSTEAD OF PUBLIC IPs?
resource "aws_vpc" "asa-demo-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name      = "asa-demo-vpc"
    I_Owner   = var.owner
    I_Purpose = "VPC for demo env."
  }
}

resource "aws_subnet" "asa-demo-subnet-private" {
  vpc_id     = aws_vpc.asa-demo-vpc.id
  cidr_block = "10.0.128.0/24"
  tags = {
    Name      = "asa-demo-subnet-private"
    I_Owner   = var.owner
    I_Purpose = "Private subnet for demo env."
  }
}

resource "aws_subnet" "asa-demo-subnet-public" {
  vpc_id                  = aws_vpc.asa-demo-vpc.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name      = "asa-demo-subnet-public"
    I_Owner   = var.owner
    I_Purpose = "Public subnet for demo env."
  }
}

resource "aws_internet_gateway" "asa-demo-igw" {
  vpc_id = aws_vpc.asa-demo-vpc.id
  tags = {
    Name      = "asa-demo-igw"
    I_Owner   = var.owner
    I_Purpose = "Internet gateway for the demo env."
  }
}

resource "aws_route_table" "asa-demo-route-table-public" {
  vpc_id = aws_vpc.asa-demo-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.asa-demo-igw.id
  }
  tags = {
    Name      = "asa-demo-route-table-public"
    I_Owner   = var.owner
    I_Purpose = "Route table for demo environment, in particular the public subnet."
  }
}

resource "aws_route_table_association" "asa-demo-route-table-association" {
  subnet_id      = aws_subnet.asa-demo-subnet-public.id
  route_table_id = aws_route_table.asa-demo-route-table-public.id
}

# Creating the security group for the different instances. Egress is ALLOW ALL by default but ingress is not.
resource "aws_security_group" "asa-demo-security-group" {
  name        = "asa-demo-security-group"
  description = "Allow ssh from mainly used IP and HTTPS from everywhere"
  vpc_id      = aws_vpc.asa-demo-vpc.id
  ingress {
    description = "SSH from France Gateway"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.source_ip]
  }
  ingress {
    description = "HTTPS from everywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name                = "asa-demo-security-group"
    I_Owner             = var.owner
    I_Purpose           = "Security group for HTTPS and SSH access."
    AllowFromEverywhere = "yes"
  }
}

# Creating the different instances
