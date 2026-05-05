locals {
  bucket_tags = merge(
    var.tags,
    {
      Name        = var.bucket_name
      Environment = var.environment
    }
  )
}
# Create the S3 bucket using the provided bucket name and standardized tags.
# force_destroy is configurable so non-production buckets can be cleaned up safely,
# while production buckets can be protected from accidental deletion.
resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = local.bucket_tags

}

# Enforce a secure baseline by blocking all public ACLs and public bucket policies.
# This helps prevent accidental public exposure of objects stored in the bucket.
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable bucket versioning to support recovery from accidental object deletion,
# overwrites, or unintended changes.
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  # Convert the boolean module input into the string value expected by the AWS provider.
  versioning_configuration {
    status = var.enable_bucket_versioning ? "Enabled" : "Suspended"
  }
}

# Require AWS KMS encryption for objects written to this bucket.
# The KMS key is provided by the root module or a dedicated KMS module.
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = var.enable_bucket_key
  }
}

# Apply lifecycle management to reduce storage costs and enforce retention behavior.
# Objects transition to the configured storage class and expire after the configured period.
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = var.enable_lifecycle_rule ? 1 : 0
  bucket = aws_s3_bucket.this.id

  rule {
    id     = var.lifecycle_rule_id
    status = "Enabled"

    filter {
      prefix = var.lifecycle_prefix
    }

    transition {
      days          = var.transition_days
      storage_class = var.transition_storage_class
    }

    expiration {
      days = var.expiration_days
    }
  }

}
