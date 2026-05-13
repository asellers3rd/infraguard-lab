# Fixed by InfraGuard
# Changes:
#   1. Replaced always-on aws_instance (m5.4xlarge) with a Launch Template +
#      Auto Scaling Group so capacity can reach zero outside business hours.
#   2. Right-sized instance from m5.4xlarge (~$560/mo) → m5.large (~$70/mo).
#   3. Added scheduled scale-up (Mon–Fri 08:00 UTC) and scale-down (20:00 UTC)
#      actions — nights and weekends run at 0 instances.
#   4. Reduced EBS data volume from 500 GB → 100 GB for staging workload.

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

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# ── Launch Template ────────────────────────────────────────────────────────────
# Right-sized: m5.large (2 vCPU / 8 GB RAM, ~$70/mo on-demand us-east-1)
# was: m5.4xlarge (16 vCPU / 64 GB RAM, ~$560/mo)
resource "aws_launch_template" "batch_processor" {
  name_prefix   = "batch-processor-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type   # m5.large — see variables.tf

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 50
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "batch-processor"
      Environment = "staging"
      ManagedBy   = "terraform"
    }
  }

  tags = {
    Name        = "batch-processor-lt"
    Environment = "staging"
    ManagedBy   = "terraform"
  }
}

# ── Auto Scaling Group ─────────────────────────────────────────────────────────
# min=0 allows the group to scale to zero (no cost) outside business hours.
resource "aws_autoscaling_group" "batch_processor" {
  name_prefix         = "batch-processor-"
  min_size            = 0
  max_size            = 1
  desired_capacity    = 1
  availability_zones  = ["${var.aws_region}a"]

  launch_template {
    id      = aws_launch_template.batch_processor.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "batch-processor"
    propagate_at_launch = true
  }
  tag {
    key                 = "Environment"
    value               = "staging"
    propagate_at_launch = true
  }
  tag {
    key                 = "ManagedBy"
    value               = "terraform"
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

# ── Scheduled Scaling: Business Hours Only ─────────────────────────────────────
# Scale UP  — Mon–Fri 08:00 UTC (desired=1)
resource "aws_autoscaling_schedule" "scale_up" {
  scheduled_action_name  = "batch-processor-scale-up"
  autoscaling_group_name = aws_autoscaling_group.batch_processor.name

  recurrence       = "0 8 * * 1-5"   # 08:00 UTC, Monday–Friday
  min_size         = 0
  max_size         = 1
  desired_capacity = 1
}

# Scale DOWN — Mon–Fri 20:00 UTC (desired=0, no cost overnight)
resource "aws_autoscaling_schedule" "scale_down" {
  scheduled_action_name  = "batch-processor-scale-down"
  autoscaling_group_name = aws_autoscaling_group.batch_processor.name

  recurrence       = "0 20 * * 1-5"  # 20:00 UTC, Monday–Friday
  min_size         = 0
  max_size         = 1
  desired_capacity = 0
}

# ── EBS Data Volume ────────────────────────────────────────────────────────────
# Right-sized: 100 GB (was 500 GB) — appropriate for staging batch workloads.
# IOPS and throughput kept at gp3 defaults; tune upward if profiling shows need.
resource "aws_ebs_volume" "data_volume" {
  availability_zone = "${var.aws_region}a"
  size              = 100      # was 500 GB
  type              = "gp3"
  encrypted         = true     # added: encrypt data at rest

  tags = {
    Name        = "batch-data-volume"
    Environment = "staging"
    ManagedBy   = "terraform"
  }
}
