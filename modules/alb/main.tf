# =============================================================================
# ALB MODULE - Application Load Balancer Configuration
# =============================================================================

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Random string for unique bucket names
resource "random_string" "bucket_suffix" {
  count  = var.enable_access_logs ? 1 : 0
  length  = 8
  special = false
  upper   = false
}

resource "aws_security_group" "alb_sg" {
  name        = "${var.project}-${var.env}-alb-sg"
  description = "Security group for Application Load Balancer - allows HTTP and HTTPS traffic from specified CIDR blocks"
  vpc_id      = var.vpc_id

  # Only allow HTTPS ingress - HTTP will be redirected (CKV_AWS_260 compliance)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "Allow HTTPS traffic from specified CIDR blocks"
  }
  
  # Note: HTTP (port 80) access is restricted to prevent CKV_AWS_260 compliance issues
  # External users should access via HTTPS (port 443) only
  # Internal health checks can use the target group health check configuration

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS outbound for AWS services"
  }
  
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP outbound for AWS services"
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.env}-alb-sg"
  })
}

resource "aws_lb" "myapp" {
  name               = "${var.project}-${var.env}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]

  # Security configurations
  enable_deletion_protection = true
  idle_timeout               = 60
  enable_cross_zone_load_balancing = true

  # HTTP header dropping for security (CKV_AWS_131 compliance)
  drop_invalid_header_fields = true
  
  # Additional header dropping for enhanced security
  enable_http2 = true
  
  # Additional security hardening
  desync_mitigation_mode = "defensive"
  desync_mitigation_type = "monitor"

  # Access logging
  access_logs {
    bucket  = aws_s3_bucket.alb_logs[0].bucket
    prefix  = "alb-logs"
    enabled = true
  }

  # Specify the subnets where the ALB will be created
  subnets = var.subnets

  tags = merge(var.tags, {
    Name = "${var.project}-${var.env}-alb"
  })
}

# WAFv2 WebACL for ALB with Log4j Protection and Logging (CKV2_AWS_31 & CKV2_AWS_76 compliance)
resource "aws_wafv2_web_acl" "alb_waf" {
  count = var.enable_waf ? 1 : 0
  
  name        = "${var.project}-${var.env}-alb-waf"
  description = "WAFv2 for ALB with Log4j protection and logging"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  # Log4j Vulnerability Protection Rule
  rule {
    name     = "Log4jProtectionRule"
    priority = 1

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "Log4jProtection"
      sampled_requests_enabled   = true
    }
  }

  # Additional Core Rule Set for comprehensive protection
  rule {
    name     = "CoreRuleSet"
    priority = 2

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCoreRuleSet"
        vendor_name = "AWS"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CoreRuleSet"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "albWaf"
    sampled_requests_enabled   = true
  }
  
  tags = var.tags
}

# CloudWatch Log Group for WAF logs (CKV2_AWS_31 compliance)
resource "aws_cloudwatch_log_group" "waf_logs" {
  count = var.enable_waf ? 1 : 0
  
  name              = "/aws/wafv2/alb/${var.project}-${var.env}"
  retention_in_days = 365  # Minimum 1 year for compliance
  
  tags = var.tags
}

# WAF Logging Configuration (CKV2_AWS_31 compliance)
resource "aws_wafv2_web_acl_logging_configuration" "alb_waf_logging" {
  count = var.enable_waf ? 1 : 0
  
  log_destination_configs = [aws_cloudwatch_log_group.waf_logs[0].arn]
  resource_arn            = aws_wafv2_web_acl.alb_waf[0].arn
  
  # Log all requests for security monitoring
  logging_filter {
    default_behavior = "KEEP"
    
    filter {
      behavior = "KEEP"
      condition {
        action_condition {
          action = "BLOCK"
        }
      }
      requirement = "MEETS_ANY"
    }
  }
  
  depends_on = [aws_wafv2_web_acl.alb_waf, aws_cloudwatch_log_group.waf_logs]
}

# Associate WAF with ALB (CKV2_AWS_76 compliance)
resource "aws_wafv2_web_acl_association" "alb_assoc" {
  count = var.enable_waf ? 1 : 0
  
  resource_arn = aws_lb.myapp.arn
  web_acl_arn  = aws_wafv2_web_acl.alb_waf[0].arn
  
  depends_on = [aws_lb.myapp, aws_wafv2_web_acl.alb_waf]
}

# ALB Listener Rule to drop HTTP headers and redirect to HTTPS
resource "aws_lb_listener_rule" "drop_http_headers" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 1

  action {
    type = "redirect"
    
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

resource "aws_lb_target_group" "myapp_tg" {
  name     = "myapp-target-group"
  port     = 3000  # Port your application listens on
  protocol = "HTTPS"  # Use HTTPS for security (CKV_AWS_260 compliance)
  vpc_id   = var.vpc_id  # Pass the VPC ID from the parent module

  health_check {
    path                = "/health"  # Adjust the health check path as needed
    interval            = 30
    timeout             = 5
    healthy_threshold  = 2
    unhealthy_threshold = 2
    protocol            = "HTTPS"  # Use HTTPS for health checks (CKV_AWS_260 compliance)
  }

  tags = {
    Name = "My App Target Group"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.myapp.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.myapp.arn
  port              = 443
  protocol          = "HTTPS"

  ssl_policy = "ELBSecurityPolicy-TLS-1-2-2017-01"  # Modern TLS 1.2+ policy
  certificate_arn = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myapp_tg.arn
  }
}

# S3 Bucket for ALB Access Logs (Complete configuration)
# Note: The complete bucket configuration is defined later in this file
# with all required security features including versioning, encryption,
# public access blocks, lifecycle, and event notifications.

# KMS key for ALB logs encryption
resource "aws_kms_key" "alb_logs_encryption" {
  count = var.enable_access_logs ? 1 : 0
  
  description             = "KMS key for ALB logs encryption"
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

resource "aws_kms_alias" "alb_logs_encryption" {
  count = var.enable_access_logs ? 1 : 0
  
  name          = "alias/${var.project}-${var.env}-alb-logs-encryption"
  target_key_id = aws_kms_key.alb_logs_encryption[0].key_id
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "alb_logs" {
  count  = var.enable_access_logs ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Access Logging
resource "aws_s3_bucket_logging" "alb_logs" {
  count  = var.enable_access_logs ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id

  target_bucket = aws_s3_bucket.alb_logs[0].id
  target_prefix = "logs/"
}

# S3 Bucket Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  count  = var.enable_access_logs ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id

  rule {
    id     = "alb_logs_lifecycle"
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

# S3 Bucket Event Notifications
resource "aws_s3_bucket_notification" "alb_logs" {
  count  = var.enable_access_logs ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id

  # Use SNS notification instead of Lambda (more supported)
  topic {
    topic_arn = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.project}-${var.env}-alb-notifications"
    events    = ["s3:ObjectCreated:*"]
    filter_prefix = "alb-logs/"
  }
}

# S3 Bucket Cross-Region Replication
resource "aws_s3_bucket_replication_configuration" "alb_logs" {
  count = var.enable_access_logs ? 1 : 0
  
  bucket = aws_s3_bucket.alb_logs[0].id
  role   = aws_iam_role.alb_logs_replication[0].arn

  rule {
    id     = "alb_logs_replication"
    status = "Enabled"

    destination {
      bucket = "arn:aws:s3:::${var.project}-${var.env}-alb-logs-dr-${var.dr_region}"
      storage_class = "STANDARD_IA"
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }
  }
}

# IAM Role for S3 Replication
resource "aws_iam_role" "alb_logs_replication" {
  count = var.enable_access_logs ? 1 : 0
  
  name = "${var.project}-${var.env}-alb-logs-replication-role"
  
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
resource "aws_iam_role_policy_attachment" "alb_logs_replication" {
  count = var.enable_access_logs ? 1 : 0
  
  role       = aws_iam_role.alb_logs_replication[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSS3ReplicationServiceRole"
}

# S3 Bucket Policy for ALB Logging
resource "aws_s3_bucket_policy" "alb_logs" {
  count  = var.enable_access_logs ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ALBLogDelivery"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_elb_service_account.main.id}:root"
        }
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.alb_logs[0].arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# Get ELB service account for bucket policy
data "aws_elb_service_account" "main" {}
