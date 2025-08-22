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
    condition     = var.eks_node_max_size >= var.eks_node_desired_size
    error_message = "Maximum size must be greater than or equal to desired size."
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

# Backup and Recovery
variable "enable_efs_backup" {
  description = "Enable EFS backup using AWS Backup"
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