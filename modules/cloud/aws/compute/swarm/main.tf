# in modules/cloud/aws/compute/swarm/main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.13.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.4"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.4.0"
    }
  }
}

data "aws_vpc" "main" {
  filter {
    name   = "isDefault"
    values = ["true"]
  }
}

data "aws_subnets" "main_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

# RSA key with 4096 rsa bits
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "local_sensitive_file" "private_key" {
  filename        = var.private_key_path
  content         = tls_private_key.rsa.private_key_pem
  file_permission = "0400"
}

resource "aws_key_pair" "deployer_key" {
  key_name   = "swarm-key"
  public_key = tls_private_key.rsa.public_key_openssh
}

data "aws_ami" "amazon_linux_docker" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amazon-linux-docker*"]
  }

  owners = ["779171867781"]
}

resource "aws_instance" "my_swarm" {
  ami               = data.aws_ami.amazon_linux_docker.id
  availability_zone = "us-east-1d"
  instance_type     = "t2.micro"
  key_name          = aws_key_pair.deployer_key.key_name
  subnet_id         = data.aws_subnets.main_subnets.ids[0]
  user_data         = <<-EOF
              #!/usr/bin/env bash

              docker swarm init
              EOF
  tags = {
    "Name" = "docker-swarm-manager"
  }
  vpc_security_group_ids = [
    aws_security_group.swarm_sg.id
  ]
}

resource "aws_security_group" "swarm_sg" {
  description = "launch-wizard-1 created 2025-03-21T13:25:21.924Z"
  egress = [
    {
      cidr_blocks = [
        "0.0.0.0/0",
      ]
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = false
      to_port          = 0
    },
  ]
  ingress = [
    {
      cidr_blocks = [
        "0.0.0.0/0",
      ]
      description      = ""
      from_port        = 22
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 22
    },
    {
      cidr_blocks = [
        "0.0.0.0/0",
      ]
      description      = ""
      from_port        = 4000
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 4000
    },
  ]
  name     = "launch-wizard-1"
  tags     = {}
  tags_all = {}
  vpc_id   = data.aws_vpc.main.id
}
