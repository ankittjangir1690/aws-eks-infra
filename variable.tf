# =============================================================================
# VARIABLES - AWS EKS Infrastructure
# =============================================================================

# Project Configuration
variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod", "test"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, test."
  }
}

variable "owner" {
  description = "Owner of the infrastructure (team or individual)"
  type        = string
  default     = "DevOps Team"
}

variable "cost_center" {
  description = "Cost center for billing purposes"
  type        = string
  default     = "Infrastructure"
}

# AWS Configuration
variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "ap-south-1"
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.region))
    error_message = "Region must be a valid AWS region."
  }
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block."
  }
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones are required for high availability."
  }
}

variable "vpc_peering_connection_id" {
  description = "VPC peering connection ID (optional)"
  type        = string
  default     = ""
}

# EKS Configuration
variable "eks_cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.32"
  validation {
    condition     = can(regex("^1\\.[0-9]+$", var.eks_cluster_version))
    error_message = "EKS cluster version must be in format 1.X."
  }
}

variable "eks_admin_users" {
  description = "List of IAM usernames to grant EKS admin access"
  type        = list(string)
  validation {
    condition     = length(var.eks_admin_users) > 0
    error_message = "At least one EKS admin user must be specified."
  }
}

variable "eks_node_instance_types" {
  description = "List of EC2 instance types for EKS nodes"
  type        = list(string)
  default     = ["t3a.medium", "t3a.large"]
  validation {
    condition     = length(var.eks_node_instance_types) > 0
    error_message = "At least one instance type must be specified."
  }
}

variable "eks_node_desired_size" {
  description = "Desired number of EKS nodes"
  type        = number
  default     = 2
  validation {
    condition     = var.eks_node_desired_size >= 1
    error_message = "Desired size must be at least 1."
  }
}

variable "eks_node_min_size" {
  description = "Minimum number of EKS nodes"
  type        = number
  default     = 1
  validation {
    condition     = var.eks_node_min_size >= 1
    error_message = "Minimum size must be at least 1."
  }
}

variable "eks_node_max_size" {
  description = "Maximum number of EKS nodes"
  type        = number
  default     = 5
  validation {
    condition     = var.eks_node_max_size >= 1
    error_message = "Maximum size must be at least 1."
  }
}

variable "allowed_public_cidrs" {
  description = "List of CIDR blocks allowed to access EKS cluster endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"] # WARNING: Restrict this in production
  validation {
    condition     = length(var.allowed_public_cidrs) > 0
    error_message = "At least one allowed CIDR must be specified."
  }
}

# Security Configuration
variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs for security monitoring"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch logs for EKS cluster"
  type        = bool
  default     = true
}

variable "enable_eks_control_plane_logging" {
  description = "Enable EKS control plane logging"
  type        = bool
  default     = true
}

# =============================================================================
# EKS ADDITIONAL FEATURES - Enable only what you need
# =============================================================================

variable "enable_alb_ingress" {
  description = "Enable ALB Ingress Controller and attach required policies"
  type        = bool
  default     = false
}

variable "enable_ebs_csi" {
  description = "Enable EBS CSI Driver and attach required policies"
  type        = bool
  default     = false
}

variable "enable_vpc_cni" {
  description = "Enable VPC CNI and attach required policies"
  type        = bool
  default     = true
}

# =============================================================================
# ALB CONFIGURATION - Optional Load Balancer
# =============================================================================

variable "enable_alb_access_logs" {
  description = "Enable ALB access logging to S3"
  type        = bool
  default     = true
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for ALB HTTPS (required if using ALB)"
  type        = string
  default     = ""
}

# Advanced Security Features
variable "enable_guardduty" {
  description = "Enable AWS GuardDuty for threat detection"
  type        = bool
  default     = true
}

variable "enable_security_hub" {
  description = "Enable AWS Security Hub for security findings"
  type        = bool
  default     = true
}

variable "enable_config" {
  description = "Enable AWS Config for compliance monitoring"
  type        = bool
  default     = true
}

variable "enable_cloudtrail" {
  description = "Enable AWS CloudTrail for API call logging"
  type        = bool
  default     = true
}

variable "enable_waf" {
  description = "Enable AWS WAF for web application protection"
  type        = bool
  default     = false
}

variable "enable_inspector" {
  description = "Enable AWS Inspector for vulnerability assessment"
  type        = bool
  default     = false
}

variable "waf_rate_limit" {
  description = "WAF rate limiting requests per 5 minutes"
  type        = number
  default     = 2000
}

variable "config_log_retention_days" {
  description = "Number of days to retain Config logs"
  type        = number
  default     = 90
}

variable "cloudtrail_log_retention_days" {
  description = "Number of days to retain CloudTrail logs"
  type        = number
  default     = 90
}

variable "waf_log_retention_days" {
  description = "Number of days to retain WAF logs"
  type        = number
  default     = 30
}

# Advanced Monitoring Features
variable "enable_monitoring_dashboard" {
  description = "Enable CloudWatch dashboard for infrastructure monitoring"
  type        = bool
  default     = true
}

variable "enable_eks_alarms" {
  description = "Enable CloudWatch alarms for EKS cluster"
  type        = bool
  default     = true
}

variable "enable_efs_alarms" {
  description = "Enable CloudWatch alarms for EFS file system"
  type        = bool
  default     = true
}

variable "enable_vpc_alarms" {
  description = "Enable CloudWatch alarms for VPC"
  type        = bool
  default     = true
}

variable "enable_log_insights" {
  description = "Enable CloudWatch Log Insights queries"
  type        = bool
  default     = true
}

variable "enable_sns_notifications" {
  description = "Enable SNS notifications for alarms"
  type        = bool
  default     = false
}

variable "enable_composite_alarms" {
  description = "Enable CloudWatch composite alarms"
  type        = bool
  default     = true
}

variable "enable_anomaly_detection" {
  description = "Enable CloudWatch anomaly detection"
  type        = bool
  default     = false
}

variable "enable_contributor_insights" {
  description = "Enable CloudWatch Contributor Insights"
  type        = bool
  default     = false
}

variable "enable_evidently" {
  description = "Enable CloudWatch Evidently for feature flags"
  type        = bool
  default     = false
}

variable "enable_rum" {
  description = "Enable CloudWatch RUM for application monitoring"
  type        = bool
  default     = false
}

variable "alarm_email" {
  description = "Email address for alarm notifications"
  type        = string
  default     = ""
}

variable "rum_domain" {
  description = "Domain for RUM application monitoring"
  type        = string
  default     = ""
}

# Advanced Backup Features
variable "enable_backup" {
  description = "Enable AWS Backup for automated backup"
  type        = bool
  default     = false
}

variable "enable_cross_region_backup" {
  description = "Enable cross-region backup for disaster recovery"
  type        = bool
  default     = false
}

variable "enable_cross_account_backup" {
  description = "Enable cross-account backup"
  type        = bool
  default     = false
}

variable "enable_efs_backup" {
  description = "Enable EFS backup using AWS Backup"
  type        = bool
  default     = false
}

variable "enable_efs_monitoring" {
  description = "Enable EFS monitoring and logging"
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 365
    error_message = "Backup retention must be between 1 and 365 days."
  }
}

variable "weekly_backup_retention_days" {
  description = "Number of days to retain weekly backups"
  type        = number
  default     = 90
  validation {
    condition     = var.weekly_backup_retention_days >= 1 && var.weekly_backup_retention_days <= 365
    error_message = "Weekly backup retention must be between 1 and 365 days."
  }
}

variable "monthly_backup_retention_days" {
  description = "Number of days to retain monthly backups"
  type        = number
  default     = 365
  validation {
    condition     = var.monthly_backup_retention_days >= 1 && var.monthly_backup_retention_days <= 2555
    error_message = "Monthly backup retention must be between 1 and 2555 days."
  }
}

# KMS Configuration
variable "kms_key_arn" {
  description = "KMS key ARN for encryption (optional)"
  type        = string
  default     = ""
}

variable "dr_region" {
  description = "Disaster recovery region for cross-region backup"
  type        = string
  default     = ""
}

variable "dr_kms_key_arn" {
  description = "KMS key ARN for disaster recovery region (optional)"
  type        = string
  default     = ""
}