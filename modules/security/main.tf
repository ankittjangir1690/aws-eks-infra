# =============================================================================
# SECURITY MODULE - Advanced Security Features
# =============================================================================

# AWS GuardDuty - Threat Detection
resource "aws_guardduty_detector" "main" {
  count = var.enable_guardduty ? 1 : 0
  
  enable = true
  
  tags = var.tags
}

# AWS Security Hub - Security Findings
resource "aws_securityhub_account" "main" {
  count = var.enable_security_hub ? 1 : 0
  
  enable_default_standards = true
  
  tags = var.tags
}

# AWS Config - Compliance Monitoring
resource "aws_config_configuration_recorder" "main" {
  count = var.enable_config ? 1 : 0
  
  name     = "${var.project}-${var.env}-config-recorder"
  role_arn = aws_iam_role.config_role[0].arn
  
  recording_group {
    all_supported = true
    include_global_resources = true
  }
  
  depends_on = [aws_config_delivery_channel.main]
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

# CloudTrail - API Call Logging
resource "aws_cloudtrail" "main" {
  count = var.enable_cloudtrail ? 1 : 0
  
  name                          = "${var.project}-${var.env}-cloudtrail"
  s3_bucket_name               = aws_s3_bucket.cloudtrail_bucket[0].bucket
  include_global_service_events = true
  is_multi_region_trail        = true
  enable_logging               = true
  
  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    exclude_management_event_sources = []
  }
  
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

# Inspector Assessment Template
resource "aws_inspector_assessment_template" "main" {
  count = var.enable_inspector ? 1 : 0
  
  name       = "${var.project}-${var.env}-assessment"
  target_arn = aws_inspector_target.main[0].arn
  arn        = aws_inspector_target.main[0].arn
  
  duration = 3600
  
  rules_package_arns = [
    "arn:aws:inspector:us-east-1:316112463485:rulespackage/0-9hgA516p",
    "arn:aws:inspector:us-east-1:316112463485:rulespackage/0-H5hpSawc",
    "arn:aws:inspector:us-east-1:316112463485:rulespackage/0-JJOtZiqQ",
    "arn:aws:inspector:us-east-1:316112463485:rulespackage/0-vg5GGHSD"
  ]
  
  depends_on = [aws_inspector2_enabler.main]
}

# Inspector Target
resource "aws_inspector_target" "main" {
  count = var.enable_inspector ? 1 : 0
  
  name = "${var.project}-${var.env}-target"
  
  resource_group_arn = aws_inspector_resource_group.main[0].arn
}

# Inspector Resource Group
resource "aws_inspector_resource_group" "main" {
  count = var.enable_inspector ? 1 : 0
  
  name = "${var.project}-${var.env}-resource-group"
  
  tags = var.tags
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}
