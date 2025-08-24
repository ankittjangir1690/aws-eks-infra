terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # Uncomment and configure these values for production use
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket-name"
  #   key            = "aws-eks-infra/terraform.tfstate"
  #   region         = "ap-south-1"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  #   kms_key_id     = "arn:aws:kms:ap-south-1:ACCOUNT_ID:key/KEY_ID"
  # }
}
