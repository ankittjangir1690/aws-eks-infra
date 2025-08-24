# =============================================================================
# EKS MODULE VARIABLES
# =============================================================================

variable "project" {
  description = "Project name for resource naming"
  type        = string
}

variable "env" {
  description = "Environment name for resource naming"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where EKS cluster will be created"
  type        = string
}

variable "private_subnets_eks" {
  description = "List of private subnet IDs for EKS cluster"
  type        = list(string)
}

variable "public_subnets_eks" {
  description = "List of public subnet IDs for EKS cluster"
  type        = list(string)
}

variable "eks_admin_users" {
  description = "List of IAM usernames to grant EKS admin access"
  type        = list(string)
}

variable "cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.32"
}

variable "node_instance_types" {
  description = "List of EC2 instance types for EKS nodes"
  type        = list(string)
  default     = ["t3a.medium", "t3a.large"]
}

variable "node_desired_size" {
  description = "Desired number of EKS nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of EKS nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of EKS nodes"
  type        = number
  default     = 5
}

variable "allowed_public_cidrs" {
  description = "List of CIDR blocks allowed to access EKS cluster endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
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
# ADDITIONAL FEATURE FLAGS
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

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}