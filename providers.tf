# =============================================================================
# AWS PROVIDER CONFIGURATION
# =============================================================================

# Configure the AWS Provider
provider "aws" {
  region = var.region
  
  # Uncomment and configure these for production use
  # profile = "your-aws-profile"
  # assume_role {
  #   role_arn = "arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME"
  #   session_name = "terraform-session"
  # }
  
  # Default tags for all resources
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = var.owner
      CostCenter  = var.cost_center
    }
  }
}

# Provider version constraints moved to backend.tf to avoid duplication
# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 5.0"
#       configuration_aliases = [aws.primary, aws.secondary]
#     }
#     random = {
#       source  = "hashicorp/random"
#       version = "~> 3.0"
#     }
#   }
#   
#   # Uncomment for production use with S3 backend
#     bucket         = "your-terraform-state-bucket"
#     key            = "aws-eks-infra/terraform.tfstate"
#     region         = "ap-south-1"
#     dynamodb_table = "terraform-state-lock"
#     encrypt        = true
#   # }
# }