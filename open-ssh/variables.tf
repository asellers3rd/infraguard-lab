variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block permitted to reach SSH (port 22). Must NOT be 0.0.0.0/0. Use your VPN or corporate egress CIDR."
  type        = string
  default     = "10.0.0.0/8"

  validation {
    condition     = var.allowed_ssh_cidr != "0.0.0.0/0"
    error_message = "allowed_ssh_cidr must not be 0.0.0.0/0 — open SSH ingress is a critical security violation."
  }
}
