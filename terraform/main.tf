terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  project_name       = "seat-booking-devops"
  ssh_key_name       = var.existing_key_pair_name != null ? var.existing_key_pair_name : aws_key_pair.imported[0].key_name
  enable_prometheus  = var.allowed_prometheus_cidr != ""
  common_name_prefix = "${local.project_name}-${var.environment}"
  public_ip          = var.existing_eip_allocation_id != null ? data.aws_eip.existing[0].public_ip : aws_eip.app[0].public_ip
}

data "aws_eip" "existing" {
  count = var.existing_eip_allocation_id != null ? 1 : 0

  id = var.existing_eip_allocation_id
}

resource "aws_key_pair" "imported" {
  count = var.existing_key_pair_name == null ? 1 : 0

  key_name_prefix = "${local.common_name_prefix}-"
  public_key      = file(pathexpand(var.public_key_path))

  tags = {
    Name        = "${local.common_name_prefix}-key"
    Project     = local.project_name
    Environment = var.environment
  }
}

resource "aws_security_group" "app" {
  name        = "${local.common_name_prefix}-sg"
  description = "Security group for the World Cup seat booking server"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.allowed_grafana_cidr]
  }

  dynamic "ingress" {
    for_each = local.enable_prometheus ? [var.allowed_prometheus_cidr] : []

    content {
      description = "Prometheus"
      from_port   = 9090
      to_port     = 9090
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    description = "Outbound internet access"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.common_name_prefix}-sg"
    Project     = local.project_name
    Environment = var.environment
  }
}

resource "aws_instance" "app" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.app.id]
  key_name                    = local.ssh_key_name
  associate_public_ip_address = true
  user_data                   = file("${path.module}/user_data.sh")

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }

  tags = {
    Name        = "${local.common_name_prefix}-server"
    Project     = local.project_name
    Environment = var.environment
  }
}

resource "aws_eip" "app" {
  count = var.existing_eip_allocation_id == null ? 1 : 0

  domain = "vpc"

  tags = {
    Name        = "${local.common_name_prefix}-eip"
    Project     = local.project_name
    Environment = var.environment
  }
}

resource "aws_eip_association" "app" {
  allocation_id = var.existing_eip_allocation_id != null ? var.existing_eip_allocation_id : aws_eip.app[0].id
  instance_id   = aws_instance.app.id
}
