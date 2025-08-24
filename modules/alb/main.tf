resource "aws_security_group" "alb_sg" {
  name        = "${var.project}-${var.env}-alb-sg"
  description = "Security group for Application Load Balancer - allows HTTP and HTTPS traffic from specified CIDR blocks"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "Allow HTTP traffic from specified CIDR blocks"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "Allow HTTPS traffic from specified CIDR blocks"
  }

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
  protocol = "HTTP"
  vpc_id   = var.vpc_id  # Pass the VPC ID from the parent module

  health_check {
    path                = "/health"  # Adjust the health check path as needed
    interval            = 30
    timeout             = 5
    healthy_threshold  = 2
    unhealthy_threshold = 2
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

# S3 Bucket for ALB Access Logs
resource "aws_s3_bucket" "alb_logs" {
  count  = var.enable_access_logs ? 1 : 0
  bucket = "${var.project}-${var.env}-alb-logs-${random_string.bucket_suffix[0].result}"

  tags = merge(var.tags, {
    Name = "${var.project}-${var.env}-alb-logs"
  })
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "alb_logs" {
  count  = var.enable_access_logs ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  count  = var.enable_access_logs ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.alb_logs_encryption[0].arn
      sse_algorithm     = "aws:kms"
    }
  }
}

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

# S3 Bucket Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  count  = var.enable_access_logs ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id

  rule {
    id     = "alb_logs_lifecycle"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }

    # Abort incomplete multipart uploads after 7 days
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# S3 Bucket Access Logging
resource "aws_s3_bucket_logging" "alb_logs" {
  count  = var.enable_access_logs ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id

  target_bucket = aws_s3_bucket.alb_logs[0].id
  target_prefix = "logs/"
}

# Random string for unique bucket names
resource "random_string" "bucket_suffix" {
  count   = var.enable_access_logs ? 1 : 0
  length  = 8
  special = false
  upper   = false
}

# Data source for current AWS account ID
data "aws_caller_identity" "current" {}

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
