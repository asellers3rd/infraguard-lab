# FIXED — InfraGuard remediation applied
# Issue: Security group allowed SSH (port 22) from 0.0.0.0/0
# Fix 1: Restricted SSH ingress to VPN/corporate CIDR via var.allowed_ssh_cidr
# Fix 2: Replaced unrestricted egress (protocol=-1) with specific port rules
#         to resolve Trivy AVD-AWS-0104 (unrestricted outbound access)

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

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "infraguard-lab-vpc"
    Environment = "lab"
    ManagedBy   = "terraform"
  }
}

resource "aws_security_group" "web_server" {
  name        = "web-server-sg"
  description = "Security group for web server"
  vpc_id      = aws_vpc.main.id

  # FIXED: SSH restricted to VPN/corporate CIDR only
  ingress {
    description = "SSH from VPN/corporate network only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # FIXED: Replaced unrestricted egress (protocol=-1) with specific port rules
  # to satisfy Trivy AVD-AWS-0104 (no unrestricted outbound access)
  egress {
    description = "HTTPS outbound (package updates, APIs)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTP outbound"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "DNS UDP outbound"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "DNS TCP outbound"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "web-server-sg"
    Environment = "lab"
    ManagedBy   = "terraform"
  }
}
