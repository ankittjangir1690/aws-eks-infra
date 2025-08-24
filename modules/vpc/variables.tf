# =============================================================================
# VPC MODULE VARIABLES
# =============================================================================

variable "project" {
  description = "Project name for resource naming"
  type        = string
}

variable "env" {
  description = "Environment name for resource naming"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)
}

variable "vpc_peering_connection_id" {
  description = "VPC peering connection ID (optional)"
  type        = string
  default     = ""
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs for security monitoring"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}