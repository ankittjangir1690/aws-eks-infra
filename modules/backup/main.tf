# =============================================================================
# BACKUP MODULE - Advanced Backup and Disaster Recovery
# =============================================================================

# AWS Backup Vault
resource "aws_backup_vault" "main" {
  count = var.enable_backup ? 1 : 0
  
  name = "${var.project}-${var.env}-backup-vault"
  
  # Enable encryption with KMS CMK (required for security compliance)
  encryption_key_arn = aws_kms_key.backup_default[0].arn
  
  # Enable point-in-time recovery
  force_destroy = false
  
  tags = var.tags
}

# AWS Backup Plan
resource "aws_backup_plan" "main" {
  count = var.enable_backup ? 1 : 0
  
  name = "${var.project}-${var.env}-backup-plan"
  
  rule {
    rule_name         = "daily_backup"
    target_vault_name = aws_backup_vault.main[0].name
    
    schedule = "cron(0 5 ? * * *)"  # Daily at 5 AM UTC
    
    lifecycle {
      delete_after = var.backup_retention_days
    }
    
    copy_action {
      destination_vault_arn = var.enable_cross_region_backup ? aws_backup_vault.dr[0].arn : null
    }
  }
  
  rule {
    rule_name         = "weekly_backup"
    target_vault_name = aws_backup_vault.main[0].name
    
    schedule = "cron(0 6 ? * SUN *)"  # Weekly on Sunday at 6 AM UTC
    
    lifecycle {
      delete_after = var.weekly_backup_retention_days
    }
    
    copy_action {
      destination_vault_arn = var.enable_cross_region_backup ? aws_backup_vault.dr[0].arn : null
    }
  }
  
  rule {
    rule_name         = "monthly_backup"
    target_vault_name = aws_backup_vault.main[0].name
    
    schedule = "cron(0 7 1 * ? *)"  # Monthly on 1st at 7 AM UTC
    
    lifecycle {
      delete_after = var.monthly_backup_retention_days
    }
    
    copy_action {
      destination_vault_arn = var.enable_cross_region_backup ? aws_backup_vault.dr[0].arn : null
    }
  }
  
  tags = var.tags
}

# Cross-Region Disaster Recovery Vault
resource "aws_backup_vault" "dr" {
  count = var.enable_cross_region_backup ? 1 : 0
  
  provider = aws.dr_region
  
  name = "${var.project}-${var.env}-dr-backup-vault"
  
  # Enable encryption with KMS CMK (required for security compliance)
  encryption_key_arn = aws_kms_key.backup_default[0].arn
  
  tags = var.tags
}

# AWS Backup Selection - EKS Resources
resource "aws_backup_selection" "eks_resources" {
  count = var.enable_backup ? 1 : 0
  
  name         = "${var.project}-${var.env}-eks-backup-selection"
  iam_role_arn = aws_iam_role.backup_role[0].arn
  plan_id      = aws_backup_plan.main[0].id
  
  resources = [
    "arn:aws:eks:${var.region}:${data.aws_caller_identity.current.account_id}:cluster/${var.project}-${var.env}-eks",
    "arn:aws:efs:${var.region}:${data.aws_caller_identity.current.account_id}:file-system/${var.efs_file_system_id}"
  ]
  
  tags = var.tags
}

# AWS Backup Selection - VPC Resources
resource "aws_backup_selection" "vpc_resources" {
  count = var.enable_backup ? 1 : 0
  
  name         = "${var.project}-${var.env}-vpc-backup-selection"
  iam_role_arn = aws_iam_role.backup_role[0].arn
  plan_id      = aws_backup_plan.main[0].id
  
  resources = [
    "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:vpc/${var.vpc_id}"
  ]
  
  tags = var.tags
}

# IAM Role for AWS Backup
resource "aws_iam_role" "backup_role" {
  count = var.enable_backup ? 1 : 0
  
  name = "${var.project}-${var.env}-backup-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })
  
  tags = var.tags
}

# Attach AWS Backup service role policy
resource "aws_iam_role_policy_attachment" "backup_policy" {
  count = var.enable_backup ? 1 : 0
  
  role       = aws_iam_role.backup_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# Attach AWS Backup service role policy for restore
resource "aws_iam_role_policy_attachment" "backup_restore_policy" {
  count = var.enable_backup ? 1 : 0
  
  role       = aws_iam_role.backup_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

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
      sse_algorithm = "AES256"
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

# AWS Backup Report Plan
resource "aws_backup_report_plan" "main" {
  count = var.enable_backup ? 1 : 0
  
  name        = "${var.project}-${var.env}-backup-report-plan"
  description = "Backup reporting for ${var.project}-${var.env}"
  
  report_delivery_channel {
    formats = ["CSV", "JSON"]
    s3_bucket_name = aws_s3_bucket.backup_reports[0].bucket
    s3_key_prefix  = "reports/"
  }
  
  report_setting {
    report_template = "BACKUP_JOB_REPORT"
    report_groups  = ["arn:aws:backup:${var.region}:${data.aws_caller_identity.current.account_id}:backup-vault/${aws_backup_vault.main[0].name}"]
  }
  
  tags = var.tags
}

# AWS Backup Framework
resource "aws_backup_framework" "main" {
  count = var.enable_backup ? 1 : 0
  
  name        = "${var.project}-${var.env}-backup-framework"
  description = "Backup framework for ${var.project}-${var.env}"
  
  control {
    name = "BACKUP_RECOVERY_POINT_MINIMUM_RETENTION_CHECK"
    
    input_parameter {
      name  = "minimumRetentionDays"
      value = tostring(var.backup_retention_days)
    }
  }
  
  control {
    name = "BACKUP_RECOVERY_POINT_ENCRYPTED"
  }
  
  control {
    name = "BACKUP_RESOURCES_PROTECTED_BY_BACKUP_PLAN"
  }
  
  control {
    name = "BACKUP_RECOVERY_POINT_MANUAL_DELETION_DISABLED"
  }
  
  tags = var.tags
}

# AWS Backup Global Settings
resource "aws_backup_global_settings" "main" {
  count = var.enable_backup ? 1 : 0
  
  global_settings = {
    "isCrossAccountBackupEnabled" = var.enable_cross_account_backup
  }
}

# Random string for bucket names
resource "random_string" "bucket_suffix" {
  count = var.enable_backup ? 1 : 0
  
  length  = 8
  special = false
  upper   = false
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Default KMS key for backup encryption (if no custom key provided)
resource "aws_kms_key" "backup_default" {
  count = var.enable_backup ? 1 : 0
  
  description             = "Default KMS key for ${var.project}-${var.env} backup encryption"
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
        Sid    = "Allow AWS Backup to use the key"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "backup.amazonaws.com"
          }
        }
      }
    ]
  })
  
  tags = var.tags
}

resource "aws_kms_alias" "backup_default" {
  count = var.enable_backup ? 1 : 0
  
  name          = "alias/${var.project}-${var.env}-backup-default"
  target_key_id = aws_kms_key.backup_default[0].key_id
}

# Provider for DR region
provider "aws" {
  alias  = "dr_region"
  region = var.dr_region
  
  default_tags {
    tags = var.tags
  }
}
