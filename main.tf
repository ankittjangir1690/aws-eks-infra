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
  
  tags = local.common_tags
}

module "efs" {
  source = "./modules/efs"
  
  name                 = "${var.project_name}-${var.environment}-efs"
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.private_subnets
  allowed_cidr_blocks  = [var.vpc_cidr] # Restrict to VPC CIDR for better security
  env                  = var.environment
  
  tags = local.common_tags
}

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
  }
}
