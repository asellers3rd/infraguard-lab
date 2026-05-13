# Fixed by InfraGuard — previously INSECURE
# Changes:
#   - Removed public-read ACL (aws_s3_bucket_acl)
#   - Added aws_s3_bucket_ownership_controls (BucketOwnerEnforced disables ACLs)
#   - Added aws_s3_bucket_public_access_block with all four block flags = true

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

# FIX 1: Enforce bucket-owner object ownership and disable ACLs entirely.
# BucketOwnerEnforced is the current AWS-recommended setting; it supersedes
# and replaces any bucket ACL, so the old aws_s3_bucket_acl resource is removed.
resource "aws_s3_bucket_ownership_controls" "static_assets_ownership" {
  bucket = aws_s3_bucket.static_assets.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# FIX 2: Block all forms of public access at the bucket level.
# All four flags must be true to fully close the public-access surface:
#   block_public_acls       — reject PutBucketAcl / PutObjectAcl calls that grant public access
#   ignore_public_acls      — ignore any pre-existing public ACLs on the bucket/objects
#   block_public_policy     — reject PutBucketPolicy calls that grant public access
#   restrict_public_buckets — restrict access to principals in the bucket owner's account
resource "aws_s3_bucket_public_access_block" "static_assets_pab" {
  bucket = aws_s3_bucket.static_assets.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true

  # Ownership controls must exist before the public-access block is applied.
  depends_on = [aws_s3_bucket_ownership_controls.static_assets_ownership]
}

resource "aws_s3_bucket_versioning" "static_assets_versioning" {
  bucket = aws_s3_bucket.static_assets.id

  versioning_configuration {
    status = "Enabled"
  }
}
