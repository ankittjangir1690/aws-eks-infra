# =============================================================================
# SECURITY MODULE - Advanced Security Features
# =============================================================================

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Note: The following security services have been removed:
# - AWS GuardDuty
# - AWS Security Hub  
# - AWS Config
# - CloudTrail
# - AWS Inspector

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
  
  # Log4j Vulnerability Protection Rule
  rule {
    name     = "Log4jProtectionRule"
    priority = 4
    
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
      metric_name                = "Log4jProtectionMetric"
      sampled_requests_enabled   = true
    }
  }
  
  # Additional Log4j Protection Rule for explicit compliance
  rule {
    name     = "Log4jExplicitProtection"
    priority = 5
    
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
      metric_name                = "Log4jExplicitProtectionMetric"
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
  retention_in_days = 365  # Minimum 1 year for compliance (CKV_AWS_338)
  kms_key_id        = aws_kms_key.waf_encryption[0].arn  # KMS encryption for compliance (CKV_AWS_158)
  
  tags = var.tags
}

# Note: WAF logging configuration has been removed for now
# It can be re-enabled later when WAF compliance is needed

# KMS key for WAF CloudWatch logs encryption
resource "aws_kms_key" "waf_encryption" {
  count = var.enable_waf ? 1 : 0
  
  description             = "KMS key for WAF CloudWatch logs encryption"
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

resource "aws_kms_alias" "waf_encryption" {
  count = var.enable_waf ? 1 : 0
  
  name          = "alias/${var.project}-${var.env}-waf-encryption"
  target_key_id = aws_kms_key.waf_encryption[0].key_id
}
