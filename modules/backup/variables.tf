# =============================================================================
# BACKUP MODULE VARIABLES
# =============================================================================

variable "project" {
  description = "Project name for resource naming"
  type        = string
}

variable "env" {
  description = "Environment name for resource naming"
  type        = string
}

variable "region" {
  description = "AWS region for resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for backup resources"
  type        = string
}

variable "efs_file_system_id" {
  description = "EFS file system ID for backup"
  type        = string
  default     = ""
}

variable "enable_backup" {
  description = "Enable AWS Backup service"
  type        = bool
  default     = true
}

variable "enable_cross_region_backup" {
  description = "Enable cross-region backup"
  type        = bool
  default     = false
}

variable "enable_cross_account_backup" {
  description = "Enable cross-account backup"
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}

variable "weekly_backup_retention_days" {
  description = "Number of days to retain weekly backups"
  type        = number
  default     = 90
}

variable "monthly_backup_retention_days" {
  description = "Number of days to retain monthly backups"
  type        = number
  default     = 365
}

variable "kms_key_arn" {
  description = "KMS key ARN for backup encryption"
  type        = string
  default     = ""
}

variable "dr_region" {
  description = "Disaster recovery region for cross-region backup"
  type        = string
  default     = ""
}

variable "dr_kms_key_arn" {
  description = "KMS key ARN for DR region backup encryption"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
