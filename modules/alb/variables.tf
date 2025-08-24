variable "vpc_id" {
  description = "The ID of the VPC where the ALB will be created"
  type        = string
}
variable "subnets" {
  description = "List of subnet IDs to attach to the ALB"
  type        = list(string)
}
variable "acm_certificate_arn" {
  description = "The ARN of the ACM certificate for HTTPS"
  type        = string
}

variable "project" {
  description = "Project name for resource naming"
  type        = string
}

variable "env" {
  description = "Environment name for resource naming"
  type        = string
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the ALB (WARNING: 0.0.0.0/0 allows access from anywhere)"
  type        = list(string)
  default     = ["10.0.0.0/16"]  # Default to VPC CIDR for security
}

variable "enable_access_logs" {
  description = "Enable ALB access logging to S3"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_waf" {
  description = "Enable WAF protection for the ALB"
  type        = bool
  default     = true
}

variable "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL to associate with the ALB"
  type        = string
  default     = ""
}

variable "dr_region" {
  description = "Disaster recovery region for cross-region replication"
  type        = string
  default     = ""
}