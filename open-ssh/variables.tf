variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "ssh_allowed_cidr" {
  description = "CIDR block permitted to reach SSH (port 22). Must NOT be 0.0.0.0/0. Restrict to your VPN or bastion host range."
  type        = string
  default     = "10.0.0.0/8"

  validation {
    condition     = var.ssh_allowed_cidr != "0.0.0.0/0"
    error_message = "ssh_allowed_cidr must not be 0.0.0.0/0. SSH must be restricted to a trusted CIDR range."
  }
}
