# =============================================================================
# SECURITY MODULE VARIABLES
# =============================================================================

variable "project" {
  description = "Project name for resource naming"
  type        = string
}

variable "env" {
  description = "Environment name for resource naming"
  type        = string
}

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

variable "dr_region" {
  description = "Disaster recovery region for cross-region replication"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
