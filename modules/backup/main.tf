# =============================================================================
# BACKUP MODULE - Simplified Configuration (Backup Vaults Disabled)
# =============================================================================

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Random string for unique bucket names
resource "random_string" "bucket_suffix" {
  count = var.enable_backup ? 1 : 0
  
  length  = 8
  special = false
  upper   = false
}

# Note: Backup vaults have been removed for now to simplify configuration
# They can be re-enabled later when needed

# Note: Backup plan has been removed for now since backup vaults are disabled
# It can be re-enabled later when backup vaults are needed

# Note: DR backup vault has been removed for now to simplify configuration
# It can be re-enabled later when cross-region backup is needed

# Note: Backup selections have been removed for now since backup vaults are disabled
# They can be re-enabled later when backup vaults are needed

# Note: IAM roles for AWS Backup have been removed for now since backup vaults are disabled
# They can be re-enabled later when backup vaults are needed

# S3 Bucket for Backup Reports
resource "aws_s3_bucket" "backup_reports" {
  count = var.enable_backup ? 1 : 0
  
  bucket = "${var.project}-${var.env}-backup-reports-${random_string.bucket_suffix[0].result}"
  
  tags = var.tags
}

resource "aws_s3_bucket_versioning" "backup_reports" {
  count = var.enable_backup ? 1 : 0
  
  bucket = aws_s3_bucket.backup_reports[0].id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backup_reports" {
  count = var.enable_backup ? 1 : 0
  
  bucket = aws_s3_bucket.backup_reports[0].id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"  # Use AWS managed encryption since KMS key is removed
    }
  }
}

resource "aws_s3_bucket_public_access_block" "backup_reports" {
  count = var.enable_backup ? 1 : 0
  
  bucket = aws_s3_bucket.backup_reports[0].id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Access Logging
resource "aws_s3_bucket_logging" "backup_reports" {
  count = var.enable_backup ? 1 : 0
  
  bucket = aws_s3_bucket.backup_reports[0].id
  
  target_bucket = aws_s3_bucket.backup_reports[0].id
  target_prefix = "logs/"
}

# S3 Bucket Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "backup_reports" {
  count = var.enable_backup ? 1 : 0
  
  bucket = aws_s3_bucket.backup_reports[0].id
  
  rule {
    id     = "backup_reports_lifecycle"
    status = "Enabled"
    
    filter {
      prefix = ""
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 2555  # 7 years for compliance
    }

    # Abort incomplete multipart uploads after 7 days
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# SNS Topic for Backup Notifications
resource "aws_sns_topic" "backup_notifications" {
  count = var.enable_backup ? 1 : 0
  
  name = "${var.project}-${var.env}-backup-notifications"
  
  # Note: KMS encryption removed since backup KMS key is disabled
  # Can be re-enabled later when backup vaults are needed
  
  tags = var.tags
}

# S3 Bucket Event Notifications
resource "aws_s3_bucket_notification" "backup_reports" {
  count = var.enable_backup ? 1 : 0
  
  bucket = aws_s3_bucket.backup_reports[0].id

  # Use SNS notification instead of Lambda (more supported)
  topic {
    topic_arn = aws_sns_topic.backup_notifications[0].arn
    events    = ["s3:ObjectCreated:*"]
    filter_prefix = "reports/"
  }
}

# DR Region S3 Bucket for Backup Reports Replication
resource "aws_s3_bucket" "backup_reports_dr" {
  count = var.enable_cross_region_backup ? 1 : 0
  
  provider = aws.dr_region
  
  bucket = "${var.project}-${var.env}-backup-reports-backup-${var.dr_region}"
  
  tags = var.tags
}

# DR S3 Bucket Access Logging (CKV_AWS_18 compliance)
resource "aws_s3_bucket_logging" "backup_reports_dr" {
  count = var.enable_cross_region_backup ? 1 : 0
  
  provider = aws.dr_region
  
  bucket = aws_s3_bucket.backup_reports_dr[0].id
  
  target_bucket = aws_s3_bucket.backup_reports_dr[0].id
  target_prefix = "logs/"
}

# DR S3 Bucket Lifecycle Configuration (CKV2_AWS_61 compliance)
resource "aws_s3_bucket_lifecycle_configuration" "backup_reports_dr" {
  count = var.enable_cross_region_backup ? 1 : 0
  
  provider = aws.dr_region
  
  bucket = aws_s3_bucket.backup_reports_dr[0].id
  
  rule {
    id     = "backup_reports_dr_lifecycle"
    status = "Enabled"
    
    filter {
      prefix = ""
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 2555  # 7 years for compliance
    }

    # Abort incomplete multipart uploads after 7 days
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# DR S3 Bucket Event Notifications (CKV2_AWS_62 compliance)
resource "aws_s3_bucket_notification" "backup_reports_dr" {
  count = var.enable_cross_region_backup ? 1 : 0
  
  provider = aws.dr_region
  
  bucket = aws_s3_bucket.backup_reports_dr[0].id

  # Use SNS notification for compliance
  topic {
    topic_arn = aws_sns_topic.backup_notifications[0].arn
    events    = ["s3:ObjectCreated:*"]
    filter_prefix = "reports/"
  }
}

# DR S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "backup_reports_dr" {
  count = var.enable_cross_region_backup ? 1 : 0
  
  provider = aws.dr_region
  
  bucket = aws_s3_bucket.backup_reports_dr[0].id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# DR S3 Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "backup_reports_dr" {
  count = var.enable_cross_region_backup ? 1 : 0
  
  provider = aws.dr_region
  
  bucket = aws_s3_bucket.backup_reports_dr[0].id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"  # Use AWS managed encryption since DR KMS key is removed
    }
  }
}

# DR S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "backup_reports_dr" {
  count = var.enable_cross_region_backup ? 1 : 0
  
  provider = aws.dr_region
  
  bucket = aws_s3_bucket.backup_reports_dr[0].id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Note: S3 replication configuration has been removed for now
# It can be re-enabled later when cross-region backup is needed

# Note: AWS Backup Framework and Global Settings have been removed for now
# They can be re-enabled later when backup vaults are needed

# Note: KMS keys for backup encryption have been removed for now
# They can be re-enabled later when backup vaults are needed

# Note: IAM roles for S3 replication have been removed for now
# They can be re-enabled later when cross-region backup is needed

# Provider for DR region
provider "aws" {
  alias  = "dr_region"
  region = var.dr_region
  
  default_tags {
    tags = var.tags
  }
}

# Random provider for unique bucket names
terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}
