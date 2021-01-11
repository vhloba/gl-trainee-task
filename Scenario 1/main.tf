terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>3.22"
    }
  }
}

provider "aws" {
  profile = var.profile
  region  = var.region
}

# Creating a VPC

resource "aws_vpc" "network" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "Server Network"
  }
}

# Creating an Internet Gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.network.id

  tags = {
    Name = "Server Network IGW"
  }
}

# Creating Public Subnets

resource "aws_subnet" "subnet_a" {
  vpc_id                  = aws_vpc.network.id
  cidr_block              = var.subnet_a_cidr_block
  availability_zone       = var.subnet_a_az
  map_public_ip_on_launch = var.map_public_ip

  tags = {
    Name = "Server Subnet A"
  }
}

resource "aws_subnet" "subnet_b" {
  vpc_id                  = aws_vpc.network.id
  cidr_block              = var.subnet_b_cidr_block
  availability_zone       = var.subnet_b_az
  map_public_ip_on_launch = var.map_public_ip

  tags = {
    Name = "Server Subnet B"
  }
}

# Adding an Internet Gateway Route to a Default Routing Table

resource "aws_route" "igw_route" {
  route_table_id         = aws_vpc.network.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Creating association between a route table and the subnet A

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_vpc.network.default_route_table_id
}

# Creating association between a route table and the subnet B

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_vpc.network.default_route_table_id
}

# Getting "my" IP address to allow WinRM connection from it only

data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

# Creating Security Group for EC2 Instances

resource "aws_security_group" "server_sg" {
  name        = "HTTP-WinRM"
  description = "Allow HTTP, WinRM traffic"
  vpc_id      = aws_vpc.network.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5985
    to_port     = 5985
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "HTTP-WinRM"
  }
}

# Creating two EC2 Instances

resource "aws_instance" "server_a" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.subnet_a.id
  user_data              = file("user_data.ps1")
  vpc_security_group_ids = [aws_security_group.server_sg.id]
  key_name               = var.key_name

  tags = {
    "Name" = "Server A"
  }
}

resource "aws_instance" "server_b" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.subnet_b.id
  user_data              = file("user_data.ps1")
  vpc_security_group_ids = [aws_security_group.server_sg.id]
  key_name               = var.key_name

  tags = {
    "Name" = "Server B"
  }
}

# Creating a Target Group

resource "aws_lb_target_group" "server_tg" {
  name                 = "Server-TG"
  target_type          = "instance"
  port                 = 80
  protocol             = "TCP"
  vpc_id               = aws_vpc.network.id
  deregistration_delay = 10

  tags = {
    "Name" = "Server TG"
  }
}

# Attaching created EC2 instances to the Target Group 

resource "aws_lb_target_group_attachment" "attach_server_a" {
  target_group_arn = aws_lb_target_group.server_tg.arn
  target_id        = aws_instance.server_a.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "attach_server_b" {
  target_group_arn = aws_lb_target_group.server_tg.arn
  target_id        = aws_instance.server_b.id
  port             = 80
}

# Creating Elastic IP addresses for the Network Load Balancer

resource "aws_eip" "eip_a" {

}

resource "aws_eip" "eip_b" {

}

# Creating Network Load Balancer

resource "aws_lb" "nlb" {
  name                             = "Server-NLB"
  internal                         = false
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = true

  subnet_mapping {
    subnet_id     = aws_subnet.subnet_a.id
    allocation_id = aws_eip.eip_a.id
  }

  subnet_mapping {
    subnet_id     = aws_subnet.subnet_b.id
    allocation_id = aws_eip.eip_b.id
  }

  tags = {
    "Name" = "Server NLB"
  }
}

# Creating a Listener

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.server_tg.arn
  }
}
