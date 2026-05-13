variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type for the batch processor. Right-sized to m5.large for staging (~$70/mo). Override for production workloads after load testing."
  type        = string
  default     = "m5.large"

  validation {
    condition     = can(regex("^(t3|t3a|m5|m5a|m6i|m6a)\\.", var.instance_type))
    error_message = "Instance type must be a current-gen general-purpose family (t3, t3a, m5, m5a, m6i, m6a)."
  }
}
