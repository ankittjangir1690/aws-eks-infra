# =============================================================================
# SECURITY MODULE - Advanced Security Features
# =============================================================================

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# AWS GuardDuty - Threat Detection
resource "aws_guardduty_detector" "main" {
  count = var.enable_guardduty ? 1 : 0
  
  enable = true
  
  # Enable for specific organization and region
  finding_publishing_frequency = "SIX_HOURS"
  
  tags = var.tags
}

# GuardDuty Organization Configuration (if in an organization)
resource "aws_guardduty_organization_admin_account" "main" {
  count = var.enable_guardduty ? 1 : 0
  
  admin_account_id = data.aws_caller_identity.current.account_id
}

# AWS Security Hub - Security Findings
resource "aws_securityhub_account" "main" {
  count = var.enable_security_hub ? 1 : 0
}

# AWS Config - Compliance Monitoring
resource "aws_config_configuration_recorder" "main" {
  count = var.enable_config ? 1 : 0
  
  name     = "${var.project}-${var.env}-config-recorder"
  role_arn = aws_iam_role.config_role[0].arn
  
  recording_group {
    all_supported = true
  }
}

resource "aws_config_delivery_channel" "main" {
  count = var.enable_config ? 1 : 0
  
  name           = "${var.project}-${var.env}-config-delivery"
  s3_bucket_name = aws_s3_bucket.config_bucket[0].bucket
  
  depends_on = [aws_config_configuration_recorder.main]
}

# S3 Bucket for Config logs
resource "aws_s3_bucket" "config_bucket" {
  count = var.enable_config ? 1 : 0
  
  bucket = "${var.project}-${var.env}-config-logs-${random_string.bucket_suffix[0].result}"
  
  tags = var.tags
}

resource "aws_s3_bucket_versioning" "config_bucket" {
  count = var.enable_config ? 1 : 0
  
  bucket = aws_s3_bucket.config_bucket[0].id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config_bucket" {
  count = var.enable_config ? 1 : 0
  
  bucket = aws_s3_bucket.config_bucket[0].id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "config_bucket" {
  count = var.enable_config ? 1 : 0
  
  bucket = aws_s3_bucket.config_bucket[0].id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Config bucket lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "config_bucket" {
  count = var.enable_config ? 1 : 0
  
  bucket = aws_s3_bucket.config_bucket[0].id
  
  rule {
    id     = "config_lifecycle"
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

# IAM Role for Config
resource "aws_iam_role" "config_role" {
  count = var.enable_config ? 1 : 0
  
  name = "${var.project}-${var.env}-config-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })
  
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "config_policy" {
  count = var.enable_config ? 1 : 0
  
  role       = aws_iam_role.config_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/ConfigRole"
}

# Config bucket access logging
resource "aws_s3_bucket_logging" "config_bucket" {
  count = var.enable_config ? 1 : 0
  
  bucket = aws_s3_bucket.config_bucket[0].id
  
  target_bucket = aws_s3_bucket.config_bucket[0].id
  target_prefix = "logs/"
}

# CloudTrail - API Call Logging
resource "aws_cloudtrail" "main" {
  count = var.enable_cloudtrail ? 1 : 0
  
  name                          = "${var.project}-${var.env}-cloudtrail"
  s3_bucket_name               = aws_s3_bucket.cloudtrail_bucket[0].bucket
  include_global_service_events = true
  is_multi_region_trail        = true
  enable_logging               = true
  
  # Enable log file validation
  enable_log_file_validation = true
  
  # Enable KMS encryption
  kms_key_id = aws_kms_key.cloudtrail_encryption[0].arn
  
  # Enable CloudWatch integration (CKV2_AWS_10 compliance)
  cloud_watch_logs_group_arn = aws_cloudwatch_log_group.cloudtrail[0].arn
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_cloudwatch[0].arn
  
  # SNS topic for notifications
  sns_topic_name = aws_sns_topic.cloudtrail_alerts[0].name
  
  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    exclude_management_event_sources = []
  }
  
  tags = var.tags
}

# KMS key for CloudTrail encryption
resource "aws_kms_key" "cloudtrail_encryption" {
  count = var.enable_cloudtrail ? 1 : 0
  
  description             = "KMS key for CloudTrail encryption"
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
        Sid    = "Allow CloudTrail to use the key"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "cloudtrail.amazonaws.com"
          }
        }
      },
      {
        Sid    = "Allow CloudWatch Logs to use the key"
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "logs.amazonaws.com"
          }
        }
      }
    ]
  })
  
  tags = var.tags
}

resource "aws_kms_alias" "cloudtrail_encryption" {
  count = var.enable_cloudtrail ? 1 : 0
  
  name          = "alias/${var.project}-${var.env}-cloudtrail-encryption"
  target_key_id = aws_kms_key.cloudtrail_encryption[0].key_id
}

# CloudWatch Log Group for CloudTrail
resource "aws_cloudwatch_log_group" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0
  
  name              = "/aws/cloudtrail/${var.project}-${var.env}"
  retention_in_days = 365  # Minimum 1 year for compliance
  kms_key_id        = aws_kms_key.cloudtrail_encryption[0].arn
  
  tags = var.tags
}

# IAM Role for CloudTrail CloudWatch integration
resource "aws_iam_role" "cloudtrail_cloudwatch" {
  count = var.enable_cloudtrail ? 1 : 0
  
  name = "${var.project}-${var.env}-cloudtrail-cloudwatch-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
      }
    ]
  })
  
  tags = var.tags
}

# Attach CloudWatch Logs policy
resource "aws_iam_role_policy_attachment" "cloudtrail_cloudwatch" {
  count = var.enable_cloudtrail ? 1 : 0
  
  role       = aws_iam_role.cloudtrail_cloudwatch[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/CloudTrail-CloudWatchLogsRole"
}

# SNS Topic for CloudTrail alerts
resource "aws_sns_topic" "cloudtrail_alerts" {
  count = var.enable_cloudtrail ? 1 : 0
  
  name = "${var.project}-${var.env}-cloudtrail-alerts"
  
  # Enable KMS encryption
  kms_master_key_id = aws_kms_key.cloudtrail_encryption[0].arn
  
  tags = var.tags
}

# S3 Bucket for CloudTrail logs
resource "aws_s3_bucket" "cloudtrail_bucket" {
  count = var.enable_cloudtrail ? 1 : 0
  
  bucket = "${var.project}-${var.env}-cloudtrail-logs-${random_string.bucket_suffix[0].result}"
  
  tags = var.tags
}

resource "aws_s3_bucket_versioning" "cloudtrail_bucket" {
  count = var.enable_cloudtrail ? 1 : 0
  
  bucket = aws_s3_bucket.cloudtrail_bucket[0].id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_bucket" {
  count = var.enable_cloudtrail ? 1 : 0
  
  bucket = aws_s3_bucket.cloudtrail_bucket[0].id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_bucket" {
  count = var.enable_cloudtrail ? 1 : 0
  
  bucket = aws_s3_bucket.cloudtrail_bucket[0].id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudTrail bucket policy
resource "aws_s3_bucket_policy" "cloudtrail_bucket" {
  count = var.enable_cloudtrail ? 1 : 0
  
  bucket = aws_s3_bucket.cloudtrail_bucket[0].id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_bucket[0].arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_bucket[0].arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# CloudTrail bucket access logging
resource "aws_s3_bucket_logging" "cloudtrail_bucket" {
  count = var.enable_cloudtrail ? 1 : 0
  
  bucket = aws_s3_bucket.cloudtrail_bucket[0].id
  
  target_bucket = aws_s3_bucket.cloudtrail_bucket[0].id
  target_prefix = "logs/"
}

# CloudTrail bucket lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail_bucket" {
  count = var.enable_cloudtrail ? 1 : 0
  
  bucket = aws_s3_bucket.cloudtrail_bucket[0].id
  
  rule {
    id     = "cloudtrail_lifecycle"
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

# CloudTrail bucket event notifications
resource "aws_s3_bucket_notification" "cloudtrail_bucket" {
  count = var.enable_cloudtrail ? 1 : 0
  
  bucket = aws_s3_bucket.cloudtrail_bucket[0].id

  # Use SNS notification instead of Lambda (more supported)
  topic {
    topic_arn = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.project}-${var.env}-cloudtrail-notifications"
    events    = ["s3:ObjectCreated:*"]
    filter_prefix = "cloudtrail/"
  }
}

# Random string for bucket names
resource "random_string" "bucket_suffix" {
  count = (var.enable_config || var.enable_cloudtrail) ? 1 : 0
  
  length  = 8
  special = false
  upper   = false
}

# AWS WAF Web ACL for Application Load Balancer
resource "aws_wafv2_web_acl" "main" {
  count = var.enable_waf ? 1 : 0
  
  name        = "${var.project}-${var.env}-waf-web-acl"
  description = "WAF Web ACL for ${var.project}-${var.env}"
  scope       = "REGIONAL"
  
  default_action {
    allow {}
  }
  
  # Rate limiting rule
  rule {
    name     = "RateLimitRule"
    priority = 1
    
    override_action {
      none {}
    }
    
    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRuleMetric"
      sampled_requests_enabled   = true
    }
  }
  
  # SQL injection rule
  rule {
    name     = "SQLInjectionRule"
    priority = 2
    
    override_action {
      none {}
    }
    
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "SQLInjectionRuleMetric"
      sampled_requests_enabled   = true
    }
  }
  
  # XSS rule
  rule {
    name     = "XSSRule"
    priority = 3
    
    override_action {
      none {}
    }
    
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "XSSRuleMetric"
      sampled_requests_enabled   = true
    }
  }
  
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "WAFWebACLMetric"
    sampled_requests_enabled   = true
  }
  
  tags = var.tags
}

# CloudWatch Log Group for WAF
resource "aws_cloudwatch_log_group" "waf" {
  count = var.enable_waf ? 1 : 0
  
  name              = "/aws/wafv2/${var.project}-${var.env}"
  retention_in_days = 30
  
  tags = var.tags
}

# WAF Logging Configuration
resource "aws_wafv2_web_acl_logging_configuration" "main" {
  count = var.enable_waf ? 1 : 0
  
  log_destination_configs = [aws_cloudwatch_log_group.waf[0].arn]
  resource_arn            = aws_wafv2_web_acl.main[0].arn
}

# AWS Inspector - Vulnerability Assessment
resource "aws_inspector2_enabler" "main" {
  count = var.enable_inspector ? 1 : 0
  
  account_ids    = [data.aws_caller_identity.current.account_id]
  resource_types = ["EC2", "ECR", "LAMBDA"]
}
