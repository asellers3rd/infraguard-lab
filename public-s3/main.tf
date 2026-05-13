# Fixed by InfraGuard
# Changes:
#   1. Changed ACL from "public-read" to "private"
#   2. Added aws_s3_bucket_public_access_block with all four block settings enabled

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

resource "aws_s3_bucket" "static_assets" {
  bucket = "infraguard-lab-static-assets"

  tags = {
    Name        = "static-assets"
    Environment = "lab"
    ManagedBy   = "terraform"
  }
}

# FIX 1: ACL changed from "public-read" to "private"
resource "aws_s3_bucket_acl" "static_assets_acl" {
  bucket = aws_s3_bucket.static_assets.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.static_assets_ownership]
}

# Required for ACL to work with newer AWS provider versions
resource "aws_s3_bucket_ownership_controls" "static_assets_ownership" {
  bucket = aws_s3_bucket.static_assets.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# FIX 2: Block all public access at the bucket level
resource "aws_s3_bucket_public_access_block" "static_assets_pab" {
  bucket = aws_s3_bucket.static_assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "static_assets_versioning" {
  bucket = aws_s3_bucket.static_assets.id

  versioning_configuration {
    status = "Enabled"
  }
}
