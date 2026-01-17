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
  #  Possible to pass those variables directly from AWS config files
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
  token      = var.session_token
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

data "aws_availability_zones" "available-zones" {
  state = "available"
}

resource "aws_subnet" "asa-demo-public-subnet" {
  vpc_id            = aws_vpc.asa-demo-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available-zones.names[0]

  tags = {
    Name      = "asa-demo-public-subnet"
    I_Owner   = var.owner
    I_Purpose = "Public subnet for demo env."
  }
}

resource "aws_subnet" "asa-demo-private-subnet" {
  vpc_id            = aws_vpc.asa-demo-vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available-zones.names[0]

  tags = {
    Name      = "asa-demo-private-subnet"
    I_Owner   = var.owner
    I_Purpose = "Private subnet for demo env."
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


resource "aws_eip" "asa-demo-eip-nat-gateway" {
  domain = "vpc"

  tags = {
    Name      = "asa-demo-eip-nat-gateway"
    I_Owner   = var.owner
    I_Purpose = "Elastic IP for the NAT gateway."
  }

  depends_on = [aws_vpc.asa-demo-vpc]
}


resource "aws_nat_gateway" "asa-demo-nat-gateway" {
  subnet_id         = aws_subnet.asa-demo-public-subnet.id
  allocation_id     = aws_eip.asa-demo-eip-nat-gateway.id
  availability_mode = "zonal"
  connectivity_type = "public"

  tags = {
    Name      = "asa-demo-nat-gateway"
    I_Owner   = var.owner
    I_Purpose = "NAT gateway."
  }
  depends_on = [aws_internet_gateway.asa-demo-igw]
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

resource "aws_route_table_association" "asa-demo-route-table-association-public" {
  subnet_id      = aws_subnet.asa-demo-public-subnet.id
  route_table_id = aws_route_table.asa-demo-route-table-public.id
}

resource "aws_route_table" "asa-demo-route-table-private" {
  vpc_id = aws_vpc.asa-demo-vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.asa-demo-nat-gateway.id
  }

  tags = {
    Name      = "asa-demo-route-table-private"
    I_Owner   = var.owner
    I_Purpose = "Route table for demo environment, in particular the private subnet."
  }
}

resource "aws_route_table_association" "asa-demo-route-table-association-private" {
  subnet_id      = aws_subnet.asa-demo-private-subnet.id
  route_table_id = aws_route_table.asa-demo-route-table-private.id
}


# Network Load Balancer configuration
resource "aws_eip" "asa-demo-eip-network-load-balancer" {
  domain = "vpc"
  tags = {
    Name      = "asa-demo-eip-network-load-balancer"
    I_Owner   = var.owner
    I_Purpose = "Elastic IP for the Network Load Balancer."
  }

  depends_on = [aws_vpc.asa-demo-vpc]
}

resource "aws_security_group" "asa-demo-security-group-nlb" {
  name        = "asa-demo-security-group-nlb"
  description = "Allow SSH and HTTPS from mainly used IPs"
  vpc_id      = aws_vpc.asa-demo-vpc.id
  dynamic "ingress" {
    for_each = var.source_ips
    content {
      description = "SSH from known IPs"
      from_port   = 10221
      to_port     = 10221
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }
  dynamic "ingress" {
    for_each = var.source_ips
    content {
      description = "HTTPS from known IPs"
      from_port   = 10441
      to_port     = 10441
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }
  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name      = "asa-demo-security-group-nlb"
    I_Owner   = var.owner
    I_Purpose = "Security group for specific port access to the NLB."
    #AllowFromEverywhere = "yes"
  }
}

resource "aws_lb" "asa-demo-network-load-balancer" {
  name               = "asa-demo-network-load-balancer"
  security_groups    = [aws_security_group.asa-demo-security-group-nlb.id]
  load_balancer_type = "network"
  internal           = false
  ip_address_type    = "ipv4"
  subnet_mapping {
    subnet_id     = aws_subnet.asa-demo-public-subnet.id
    allocation_id = aws_eip.asa-demo-eip-network-load-balancer.id
  }

  tags = {
    Name      = "asa-demo-network-load-balancer"
    I_Owner   = var.owner
    I_Purpose = "Network Load Balancer for incoming traffic"
  }
}

# Creating the security group for the different instances. Egress is ALLOW ALL by default but ingress is not.
resource "aws_security_group" "asa-demo-security-group-instances" {
  name        = "asa-demo-security-group-instances"
  description = "Allow ssh from mainly used IP and HTTPS from everywhere"
  vpc_id      = aws_vpc.asa-demo-vpc.id
  dynamic "ingress" {
    for_each = var.source_ips
    content {
      description = "SSH from known IPs"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }
  dynamic "ingress" {
    for_each = var.source_ips
    content {
      description = "HTTPS from known IPs"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }
  ingress {
    description = "All traffic within private subnet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.asa-demo-vpc.cidr_block]
  }
  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name                = "asa-demo-security-group-instances"
    I_Owner             = var.owner
    I_Purpose           = "Security group for HTTPS, SSH access and in cluster communication."
    AllowFromEverywhere = "yes"
  }
}


# Creating the NGINX intance instances
resource "aws_instance" "asa-demo-nginx-vm" {
  ami                         = "ami-0a0ff88d0f3f85a14"
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.asa-demo-private-subnet.id
  key_name                    = var.ec2_key_name
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.asa-demo-security-group-instances.id]

  tags = {
    Name      = "asa-demo-nginx-vm"
    I_Owner   = var.owner
    I_Purpose = "Linux VM for Nginx."
  }
}

# Forwarding traffic from 10441 to 443
resource "aws_lb_target_group" "asa-demo-target-group-nginx-https" {
  name     = "asa-demo-tg-nginx-https"
  port     = 443
  vpc_id   = aws_vpc.asa-demo-vpc.id
  protocol = "TCP"
  health_check {
    protocol = "TCP"
  }
  target_type        = "instance"
  preserve_client_ip = true

  tags = {
    Name      = "asa-demo-tg-nginx-https"
    I_Owner   = var.owner
    I_Purpose = "Target group for HTTPS access to the nginx VM."
  }
}

# Attaching the target group to the Nginx instance
resource "aws_lb_target_group_attachment" "asa-demo-target-group-nginx-https-attachment" {
  target_group_arn = aws_lb_target_group.asa-demo-target-group-nginx-https.arn
  target_id        = aws_instance.asa-demo-nginx-vm.id
  #port             = 443 not mandatory, should be inherited from the resource above
}

resource "aws_lb_listener" "asa-demo-nlb-listener-nginx-https" {
  load_balancer_arn = aws_lb.asa-demo-network-load-balancer.arn
  port              = 10441
  protocol          = "TCP"
  default_action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.asa-demo-target-group-nginx-https.arn
        weight = 1
      }
    }
  }
  tags = {
    Name      = "asa-demo-nlb-listener-nginx-https"
    I_Owner   = var.owner
    I_Purpose = "Listener for HTTPS access to the Nginx VM."
  }
}

# Forwarding traffic from 10221 to 22
resource "aws_lb_target_group" "asa-demo-target-group-nginx-ssh" {
  name     = "asa-demo-target-group-nginx-ssh"
  port     = 22
  vpc_id   = aws_vpc.asa-demo-vpc.id
  protocol = "TCP"
  health_check {
    protocol = "TCP"
  }
  target_type        = "instance"
  preserve_client_ip = true

  tags = {
    Name      = "asa-demo-target-group-nginx-ssh"
    I_Owner   = var.owner
    I_Purpose = "Target group for SSH access to the nginx VM."
  }
}

# Attaching the target group to the Nginx instance
resource "aws_lb_target_group_attachment" "asa-demo-target-group-nginx-ssh-attachment" {
  target_group_arn = aws_lb_target_group.asa-demo-target-group-nginx-ssh.arn
  target_id        = aws_instance.asa-demo-nginx-vm.id
  #port             = 443 not mandatory, should be inherited from the resource above
}

resource "aws_lb_listener" "asa-demo-nlb-listener-nginx-ssh" {
  load_balancer_arn = aws_lb.asa-demo-network-load-balancer.arn
  port              = 10221
  protocol          = "TCP"
  default_action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.asa-demo-target-group-nginx-ssh.arn
        weight = 1
      }
    }
  }
  tags = {
    Name      = "asa-demo-nlb-listener-nginx-ssh"
    I_Owner   = var.owner
    I_Purpose = "Listener for SSH access to the Nginx VM."
  }
}
