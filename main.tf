terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Main Terraform configuration for AWS EKS Infrastructure
# This configuration creates a secure, production-ready EKS cluster

module "vpc" {
  source = "./modules/vpc"
  
  project                    = var.project_name
  env                       = var.environment
  vpc_peering_connection_id = var.vpc_peering_connection_id
  vpc_cidr                  = var.vpc_cidr
  azs                       = var.availability_zones
  enable_vpc_flow_logs      = var.enable_vpc_flow_logs
  
  tags = local.common_tags
}

module "eks" {
  source = "./modules/eks"
  
  vpc_id                = module.vpc.vpc_id
  project               = var.project_name
  env                   = var.environment
  eks_admin_users       = var.eks_admin_users
  private_subnets_eks   = module.vpc.private_subnets
  public_subnets_eks    = module.vpc.public_subnets
  cluster_version       = var.eks_cluster_version
  node_instance_types   = var.eks_node_instance_types
  node_desired_size     = var.eks_node_desired_size
  node_min_size         = var.eks_node_min_size
  node_max_size         = var.eks_node_max_size
  allowed_public_cidrs  = var.allowed_public_cidrs
  enable_cloudwatch_logs = var.enable_cloudwatch_logs
  enable_eks_control_plane_logging = var.enable_eks_control_plane_logging
  
  # Additional feature flags
  enable_alb_ingress   = var.enable_alb_ingress
  enable_ebs_csi       = var.enable_ebs_csi
  enable_vpc_cni       = var.enable_vpc_cni
  
  tags = local.common_tags
}

module "efs" {
  source = "./modules/efs"
  
  name                 = "${var.project_name}-${var.environment}-efs"
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.private_subnets
  allowed_cidr_blocks  = [var.vpc_cidr] # Restrict to VPC CIDR for better security
  env                  = var.environment
  enable_backup        = var.enable_efs_backup
  enable_monitoring    = var.enable_efs_monitoring
  log_retention_days   = var.backup_retention_days
  kms_key_arn          = var.kms_key_arn
  
  tags = local.common_tags
}

# Advanced Security Module
module "security" {
  source = "./modules/security"
  
  project              = var.project_name
  env                  = var.environment
  enable_guardduty     = var.enable_guardduty
  enable_security_hub  = var.enable_security_hub
  enable_config        = var.enable_config
  enable_cloudtrail    = var.enable_cloudtrail
  enable_waf           = var.enable_waf
  enable_inspector     = var.enable_inspector
  waf_rate_limit       = var.waf_rate_limit
  config_log_retention_days = var.config_log_retention_days
  cloudtrail_log_retention_days = var.cloudtrail_log_retention_days
  waf_log_retention_days = var.waf_log_retention_days
  
  tags = local.common_tags
}

# Advanced Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"
  
  project                    = var.project_name
  env                       = var.environment
  region                    = var.region
  vpc_id                    = module.vpc.vpc_id
  efs_file_system_id        = module.efs.efs_id
  enable_dashboard          = var.enable_monitoring_dashboard
  enable_eks_alarms         = var.enable_eks_alarms
  enable_efs_alarms         = var.enable_efs_alarms
  enable_vpc_alarms         = var.enable_vpc_alarms
  enable_log_insights       = var.enable_log_insights
  enable_sns_notifications  = var.enable_sns_notifications
  enable_composite_alarms   = var.enable_composite_alarms
  enable_anomaly_detection  = var.enable_anomaly_detection
  enable_contributor_insights = var.enable_contributor_insights
  enable_evidently          = var.enable_evidently
  enable_rum                = var.enable_rum
  alarm_email               = var.alarm_email
  alarm_actions             = var.enable_sns_notifications ? [module.monitoring.sns_topic_arn] : []
  rum_domain                = var.rum_domain
  
  tags = local.common_tags
}

# Advanced Backup Module
module "backup" {
  source = "./modules/backup"
  
  project                    = var.project_name
  env                       = var.environment
  region                    = var.region
  vpc_id                    = module.vpc.vpc_id
  efs_file_system_id        = module.efs.efs_id
  enable_backup             = var.enable_backup
  enable_cross_region_backup = var.enable_cross_region_backup
  enable_cross_account_backup = var.enable_cross_account_backup
  backup_retention_days     = var.backup_retention_days
  weekly_backup_retention_days = var.weekly_backup_retention_days
  monthly_backup_retention_days = var.monthly_backup_retention_days
  kms_key_arn               = var.kms_key_arn
  dr_region                 = var.dr_region
  dr_kms_key_arn            = var.dr_kms_key_arn
  
  tags = local.common_tags
}

# ALB Module (optional - uncomment when needed)
# module "alb" {
#   source = "./modules/alb"
#   
#   project               = var.project_name
#   env                   = var.environment
#   vpc_id                = module.vpc.vpc_id
#   subnets               = module.vpc.public_subnets
#   acm_certificate_arn   = var.acm_certificate_arn
#   allowed_cidr_blocks   = var.allowed_public_cidrs
#   enable_access_logs    = var.enable_alb_access_logs
#   
#   tags = local.common_tags
# }

# Route 53 setup (commented out - uncomment when needed)
# module "route53" {
#   source = "./modules/route53"
#   project = var.project_name
#   env = var.environment
#   tags = local.common_tags
# }

# Local values for consistent tagging
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
    CostCenter  = var.cost_center
    CreatedAt   = timestamp()
    SecurityLevel = "High"
    Compliance   = "SOC2"
    BackupPolicy = "Daily"
  }
}
