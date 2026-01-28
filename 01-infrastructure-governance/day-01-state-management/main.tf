# ----------------------------------------------------------------------------------
# Day 01: Multi-Account Remote State Governance
# Purpose: Bootstrapping S3 + DynamoDB for enterprise-grade state management.
# ----------------------------------------------------------------------------------

provider "aws" {
  region = "us-east-1"
}

# Data source to ensure the bucket name is unique by including your Account ID
data "aws_caller_identity" "current" {}

locals {
  account_id  = data.aws_caller_identity.current.account_id
  project_tag = "modern-infrastructure-playbook"
}

# 1. S3 Bucket: Durable storage for the .tfstate file
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "tf-state-storage-${local.account_id}"
  force_destroy = false # Senior safeguard: Do not allow deletion if it contains files

  lifecycle {
    prevent_destroy = true 
  }

  tags = {
    Name        = "Terraform State Bucket"
    Project     = local.project_tag
    ManagedBy   = "Terraform"
  }
}

# 2. S3 Versioning: Essential for Disaster Recovery (Rollback capability)
resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 3. Server-Side Encryption: Ensures state secrets are encrypted at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "state_encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 4. Public Access Block: Security hardening
resource "aws_s3_bucket_public_access_block" "state_privacy" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 5. DynamoDB: Distributed locking to prevent state corruption
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "tf-state-lock-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name    = "Terraform Lock Table"
    Project = local.project_tag
  }
}

# --- Outputs for Reference ---
output "state_bucket_name" {
  value = aws_s3_bucket.terraform_state.id
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.terraform_locks.name
}
