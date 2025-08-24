# =============================================================================
# EFS MODULE - Secure EFS File System Configuration
# =============================================================================

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# EFS File System
resource "aws_efs_file_system" "main" {
  creation_token = "${var.name}-efs"
  
  # Performance configuration
  performance_mode = "generalPurpose"
  throughput_mode = "bursting"
  
  # Security configuration
  encrypted = true
  
  # Use KMS CMK for encryption if provided, otherwise use AWS managed key
  kms_key_id = var.kms_key_arn != "" ? var.kms_key_arn : null
  
  # Lifecycle policy
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = merge(var.tags, {
    Name = var.name
    Environment = var.env
  })
}

# EFS Security Group
resource "aws_security_group" "efs" {
  name_prefix = "${var.name}-efs-sg"
  description = "Security group for EFS file system"
  vpc_id      = var.vpc_id

  # Allow NFS traffic from specified CIDR blocks
  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "NFS access from allowed CIDR blocks"
  }

  # Allow NFS traffic from EKS nodes (if EKS is in the same VPC)
  dynamic "ingress" {
    for_each = var.eks_security_group_ids
    content {
      from_port       = 2049
      to_port         = 2049
      protocol        = "tcp"
      security_groups = [ingress.value]
      description     = "NFS access from EKS nodes"
    }
  }

  # Egress rule - allow only necessary outbound traffic
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
    Name = "${var.name}-efs-sg"
  })
}

# EFS Mount Targets
resource "aws_efs_mount_target" "main" {
  count = length(var.subnet_ids)
  
  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
  
  # IP address (optional - AWS will assign if not specified)
  ip_address = var.mount_target_ip_addresses[count.index] != "" ? var.mount_target_ip_addresses[count.index] : null
}

# EFS Access Point (optional)
resource "aws_efs_access_point" "main" {
  count = var.create_access_point ? 1 : 0
  
  file_system_id = aws_efs_file_system.main.id
  
  root_directory {
    path = var.access_point_root_path
    creation_info {
      owner_gid   = var.access_point_owner_gid
      owner_uid   = var.access_point_owner_uid
      permissions = var.access_point_permissions
    }
  }

  posix_user {
    gid = var.access_point_posix_gid
    uid = var.access_point_posix_uid
  }

  tags = merge(var.tags, {
    Name = "${var.name}-access-point"
  })
}

# EFS Backup Policy (if enabled) - CKV2_AWS_18 compliance
resource "aws_efs_backup_policy" "main" {
  count = var.enable_backup ? 1 : 0
  
  file_system_id = aws_efs_file_system.main.id

  backup_policy {
    status = "ENABLED"
  }
}

# EFS Backup Selection - Explicit integration with AWS Backup (CKV2_AWS_18 compliance)
resource "aws_backup_selection" "efs_explicit" {
  count = var.enable_backup ? 1 : 0
  
  name         = "${var.name}-efs-backup-selection"
  iam_role_arn = var.backup_role_arn
  plan_id      = var.backup_plan_id
  
  resources = [
    aws_efs_file_system.main.arn
  ]
  
  depends_on = [aws_efs_file_system.main]
}

# CloudWatch Log Group for EFS (if monitoring is enabled)
resource "aws_cloudwatch_log_group" "efs" {
  count = var.enable_monitoring ? 1 : 0
  
  name              = "/aws/efs/${var.name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn != "" ? var.kms_key_arn : null

  tags = var.tags
}

# IAM Role for EFS monitoring (if enabled)
resource "aws_iam_role" "efs_monitoring" {
  count = var.enable_monitoring ? 1 : 0
  
  name = "${var.name}-efs-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "efs.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for EFS monitoring
resource "aws_iam_role_policy" "efs_monitoring" {
  count = var.enable_monitoring ? 1 : 0
  
  name = "${var.name}-efs-monitoring-policy"
  role = aws_iam_role.efs_monitoring[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/efs/${var.name}",
          "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/efs/${var.name}:*"
        ]
      }
    ]
  })
}