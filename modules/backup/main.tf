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
      kms_master_key_id = aws_kms_key.backup_encryption[0].arn
      sse_algorithm     = "aws:kms"
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

# S3 Bucket Access Logging - Disabled to prevent circular logging
# resource "aws_s3_bucket_logging" "backup_reports" {
#   count = var.enable_backup ? 1 : 0
#   
#   bucket = aws_s3_bucket.backup_reports[0].id
#   
#   target_bucket = aws_s3_bucket.backup_reports[0].id
#   target_prefix = "logs/"
# }

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

# S3 Bucket Event Notifications for compliance (CKV2_AWS_62)
resource "aws_s3_bucket_notification" "backup_reports" {
  count = var.enable_backup ? 1 : 0
  
  bucket = aws_s3_bucket.backup_reports[0].id
  
  # Use SNS notification for compliance
  topic {
    topic_arn = aws_sns_topic.backup_notifications[0].arn
    events    = ["s3:ObjectCreated:*"]
    filter_prefix = "backup-reports/"
  }
}

# SNS Topic for Backup Notifications
resource "aws_sns_topic" "backup_notifications" {
  count = var.enable_backup ? 1 : 0
  
  name = "${var.project}-${var.env}-backup-notifications"
  
  # KMS encryption for compliance (CKV_AWS_26)
  kms_master_key_id = aws_kms_key.backup_encryption[0].arn
  
  tags = var.tags
}

# Note: S3 bucket notification is already defined above

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
      kms_master_key_id = aws_kms_key.backup_encryption[0].arn
      sse_algorithm     = "aws:kms"
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

# S3 Bucket Cross-Region Replication for Backup Reports (CKV_AWS_144 compliance)
resource "aws_s3_bucket_replication_configuration" "backup_reports" {
  count = var.enable_backup ? 1 : 0
  
  bucket = aws_s3_bucket.backup_reports[0].id
  
  role = aws_iam_role.s3_replication_role[0].arn
  
  rule {
    id     = "backup_reports_replication"
    status = "Enabled"
    
    destination {
      bucket = aws_s3_bucket.backup_reports_dr[0].arn
    }
  }
}

# Note: AWS Backup Framework and Global Settings have been removed for now
# They can be re-enabled later when backup vaults are needed

# KMS key for backup encryption (required for SNS and S3 compliance)
resource "aws_kms_key" "backup_encryption" {
  count = var.enable_backup ? 1 : 0
  
  description             = "KMS key for ${var.project}-${var.env} backup encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow SNS to use the key"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "sns.amazonaws.com"
          }
        }
      },
      {
        Sid    = "Allow S3 to use the key"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "s3.amazonaws.com"
          }
        }
      }
    ]
  })
  
  tags = var.tags
}

resource "aws_kms_alias" "backup_encryption" {
  count = var.enable_backup ? 1 : 0
  
  name          = "alias/${var.project}-${var.env}-backup-encryption"
  target_key_id = aws_kms_key.backup_encryption[0].key_id
}

# IAM Role for S3 Cross-Region Replication (CKV_AWS_144 compliance)
resource "aws_iam_role" "s3_replication_role" {
  count = var.enable_backup ? 1 : 0
  
  name = "${var.project}-${var.env}-s3-replication-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
  
  tags = var.tags
}

# Attach S3 replication policy
resource "aws_iam_role_policy" "s3_replication_policy" {
  count = var.enable_backup ? 1 : 0
  
  name = "${var.project}-${var.env}-s3-replication-policy"
  role = aws_iam_role.s3_replication_role[0].id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = [aws_s3_bucket.backup_reports[0].arn]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl"
        ]
        Resource = "${aws_s3_bucket.backup_reports[0].arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete"
        ]
        Resource = "${aws_s3_bucket.backup_reports_dr[0].arn}/*"
      }
    ]
  })
}

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
