# =============================================================================
# MONITORING MODULE VARIABLES
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
  description = "VPC ID for VPC-related monitoring"
  type        = string
}

variable "efs_file_system_id" {
  description = "EFS file system ID for EFS monitoring"
  type        = string
  default     = ""
}

variable "enable_dashboard" {
  description = "Enable CloudWatch dashboard"
  type        = bool
  default     = true
}

variable "enable_eks_alarms" {
  description = "Enable EKS-related CloudWatch alarms"
  type        = bool
  default     = true
}

variable "enable_efs_alarms" {
  description = "Enable EFS-related CloudWatch alarms"
  type        = bool
  default     = true
}

variable "enable_vpc_alarms" {
  description = "Enable VPC-related CloudWatch alarms"
  type        = bool
  default     = true
}

variable "enable_log_insights" {
  description = "Enable CloudWatch Logs Insights queries"
  type        = bool
  default     = true
}

variable "enable_sns_notifications" {
  description = "Enable SNS notifications for alarms"
  type        = bool
  default     = true
}

variable "enable_composite_alarms" {
  description = "Enable composite CloudWatch alarms"
  type        = bool
  default     = true
}

variable "enable_anomaly_detection" {
  description = "Enable CloudWatch anomaly detection"
  type        = bool
  default     = true
}

variable "enable_contributor_insights" {
  description = "Enable CloudWatch Contributor Insights"
  type        = bool
  default     = true
}

variable "enable_evidently" {
  description = "Enable CloudWatch Evidently for feature flags"
  type        = bool
  default     = false
}

variable "enable_rum" {
  description = "Enable CloudWatch RUM for real user monitoring"
  type        = bool
  default     = false
}

variable "alarm_email" {
  description = "Email address for alarm notifications"
  type        = string
  default     = ""
}

variable "alarm_actions" {
  description = "List of ARNs for alarm actions (SNS topics, etc.)"
  type        = list(string)
  default     = []
}

variable "rum_domain" {
  description = "Domain for CloudWatch RUM"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
