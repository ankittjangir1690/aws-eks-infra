# =============================================================================
# EFS MODULE VARIABLES
# =============================================================================

variable "name" {
  description = "Name of the EFS file system"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where EFS will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for EFS mount targets"
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access EFS"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "eks_security_group_ids" {
  description = "List of EKS security group IDs for EFS access"
  type        = list(string)
  default     = []
}

variable "env" {
  description = "Environment name for resource naming"
  type        = string
}

variable "availability_zone_id" {
  description = "Availability zone ID for EFS (optional)"
  type        = string
  default     = ""
}

variable "create_access_point" {
  description = "Whether to create an EFS access point"
  type        = bool
  default     = false
}

variable "access_point_root_path" {
  description = "Root directory path for EFS access point"
  type        = string
  default     = "/"
}

variable "access_point_owner_gid" {
  description = "Owner GID for EFS access point"
  type        = number
  default     = 1000
}

variable "access_point_owner_uid" {
  description = "Owner UID for EFS access point"
  type        = number
  default     = 1000
}

variable "access_point_permissions" {
  description = "Permissions for EFS access point root directory"
  type        = string
  default     = "755"
}

variable "access_point_posix_gid" {
  description = "POSIX GID for EFS access point"
  type        = number
  default     = 1000
}

variable "access_point_posix_uid" {
  description = "POSIX UID for EFS access point"
  type        = number
  default     = 1000
}

variable "mount_target_ip_addresses" {
  description = "List of IP addresses for mount targets (optional)"
  type        = list(string)
  default     = []
}

variable "enable_backup" {
  description = "Enable EFS backup policy"
  type        = bool
  default     = false
}

variable "enable_monitoring" {
  description = "Enable EFS monitoring and logging"
  type        = bool
  default     = false
}

variable "backup_role_arn" {
  description = "ARN of the AWS Backup IAM role for EFS backup integration"
  type        = string
  default     = ""
}

variable "backup_plan_id" {
  description = "ID of the AWS Backup plan for EFS backup integration"
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "kms_key_arn" {
  description = "KMS key ARN for EFS encryption (optional - uses AWS managed key if not provided)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "efs_name" {
  description = "Name of the EFS filesystem"
  type        = string
}