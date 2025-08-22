# =============================================================================
# OUTPUTS - AWS EKS Infrastructure
# =============================================================================

# VPC Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = module.vpc.vpc_arn
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnets
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = module.vpc.availability_zones
}

output "nat_gateway_public_ip" {
  description = "Public IP address of the NAT Gateway"
  value       = module.vpc.nat_gateway_public_ip
}

# EKS Outputs
output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "eks_cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks.cluster_arn
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_version" {
  description = "EKS cluster version"
  value       = module.eks.cluster_version
}

output "eks_cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "eks_cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.eks.cluster_oidc_issuer_url
}

output "eks_node_groups" {
  description = "Map of EKS node groups"
  value       = module.eks.node_groups
}

output "eks_cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "eks_node_security_group_id" {
  description = "Security group ID attached to the EKS node groups"
  value       = module.eks.node_security_group_id
}

output "eks_cluster_iam_role_name" {
  description = "IAM role name associated with EKS cluster"
  value       = module.eks.cluster_iam_role_name
}

output "eks_cluster_iam_role_arn" {
  description = "IAM role ARN associated with EKS cluster"
  value       = module.eks.cluster_iam_role_arn
}

output "eks_node_iam_role_name" {
  description = "IAM role name associated with EKS nodes"
  value       = module.eks.node_iam_role_name
}

output "eks_node_iam_role_arn" {
  description = "IAM role ARN associated with EKS nodes"
  value       = module.eks.node_iam_role_arn
}

# EFS Outputs
output "efs_id" {
  description = "EFS file system ID"
  value       = module.efs.efs_id
}

output "efs_arn" {
  description = "EFS file system ARN"
  value       = module.efs.efs_arn
}

output "efs_dns_name" {
  description = "EFS file system DNS name"
  value       = module.efs.efs_dns_name
}

output "efs_mount_target_ids" {
  description = "List of EFS mount target IDs"
  value       = module.efs.efs_mount_target_ids
}

output "efs_mount_target_ips" {
  description = "List of EFS mount target IP addresses"
  value       = module.efs.efs_mount_target_ips
}

output "efs_security_group_id" {
  description = "EFS security group ID"
  value       = module.efs.efs_security_group_id
}

# VPC Flow Logs Outputs
output "vpc_flow_log_id" {
  description = "VPC Flow Log ID (if enabled)"
  value       = module.vpc.vpc_flow_log_id
}

output "vpc_flow_log_arn" {
  description = "VPC Flow Log ARN (if enabled)"
  value       = module.vpc.vpc_flow_log_arn
}

# CloudWatch Log Groups
output "vpc_flow_log_group_name" {
  description = "VPC Flow Log CloudWatch log group name (if enabled)"
  value       = var.enable_vpc_flow_logs ? "/aws/vpc/flowlogs/${var.project_name}-${var.environment}" : null
}

output "eks_cluster_log_group_name" {
  description = "EKS cluster CloudWatch log group name (if enabled)"
  value       = var.enable_cloudwatch_logs ? "/aws/eks/${var.project_name}-${var.environment}-eks/cluster" : null
}

output "efs_log_group_name" {
  description = "EFS CloudWatch log group name (if monitoring enabled)"
  value       = var.enable_efs_backup ? "/aws/efs/${var.project_name}-${var.environment}-efs" : null
}

# Connection Information
output "kubectl_config_command" {
  description = "Command to configure kubectl for the EKS cluster"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${var.project_name}-${var.environment}-eks"
}

output "cluster_access_info" {
  description = "Information about accessing the EKS cluster"
  value = {
    cluster_name = "${var.project_name}-${var.environment}-eks"
    region       = var.region
    endpoint     = module.eks.cluster_endpoint
    kubectl_cmd  = "aws eks update-kubeconfig --region ${var.region} --name ${var.project_name}-${var.environment}-eks"
  }
}

# Security Information
output "security_groups" {
  description = "Security group IDs for the infrastructure"
  value = {
    vpc_flow_logs = module.vpc.vpc_flow_log_id
    eks_cluster   = module.eks.cluster_security_group_id
    eks_nodes     = module.eks.node_security_group_id
    efs           = module.efs.efs_security_group_id
  }
}

# IAM Roles Information
output "iam_roles" {
  description = "IAM role information for the infrastructure"
  value = {
    eks_cluster = module.eks.cluster_iam_role_arn
    eks_nodes   = module.eks.node_iam_role_arn
    vpc_flow_logs = var.enable_vpc_flow_logs ? module.vpc.vpc_flow_log_arn : null
  }
}

# Network Information
output "network_info" {
  description = "Network configuration information"
  value = {
    vpc_id           = module.vpc.vpc_id
    vpc_cidr         = module.vpc.vpc_cidr_block
    public_subnets   = module.vpc.public_subnets
    private_subnets  = module.vpc.private_subnets
    availability_zones = module.vpc.availability_zones
    nat_gateway_ip   = module.vpc.nat_gateway_public_ip
  }
}

# Storage Information
output "storage_info" {
  description = "Storage configuration information"
  value = {
    efs_id       = module.efs.efs_id
    efs_dns_name = module.efs.efs_dns_name
    efs_arn      = module.efs.efs_arn
    mount_targets = module.efs.efs_mount_target_ids
  }
}
