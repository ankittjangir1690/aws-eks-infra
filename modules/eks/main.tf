# =============================================================================
# EKS MODULE - Secure EKS Cluster Configuration (Updated 2024)
# =============================================================================

# EKS Cluster
module "eks" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git?ref=v19.21.0"

  cluster_name    = "${var.project}-${var.env}-eks"
  cluster_version = var.cluster_version

  # Cluster endpoint access control
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  cluster_endpoint_public_access_cidrs = var.allowed_public_cidrs

  # VPC and subnet configuration
  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets_eks

  # Enable IRSA (IAM Roles for Service Accounts)
  enable_irsa = true

  # Cluster security group
  cluster_security_group_additional_rules = {
    ingress_nodes_443 = {
      description                = "Node groups to cluster API"
      protocol                  = "tcp"
      from_port                 = 443
      to_port                   = 443
      type                      = "ingress"
      source_node_security_group = true
    }
  }

  # Node group security group
  node_security_group_additional_rules = {
    ingress_allow_access_from_control_plane = {
      type                          = "ingress"
      protocol                      = "tcp"
      from_port                     = 1025
      to_port                       = 65535
      source_cluster_security_group = true
    }
    egress_all = {
      type      = "egress"
      protocol  = "-1"
      from_port = 0
      to_port   = 0
      cidr_blocks = ["0.0.0.0/0"]
    }
    # Explicit attachment to EKS nodes security group for compliance
    ingress_eks_nodes_security_group = {
      type                     = "ingress"
      protocol                 = "tcp"
      from_port                = 443
      to_port                  = 443
      source_security_groups   = [aws_security_group.eks_nodes.id]
      description              = "Allow traffic from EKS nodes security group"
    }
  }

  # EKS managed node group defaults
  eks_managed_node_group_defaults = {
    disk_size = 30
    disk_type = "gp3"
    
    # Enable detailed monitoring
    enable_monitoring = true
    
    # Security configurations - attach the security group to nodes
    vpc_security_group_ids = [aws_security_group.eks_nodes.id]
    
    # IAM role configuration - use the module's default role
    iam_role_use_name_prefix = true
  }
  
  # EKS managed node groups
  eks_managed_node_groups = {
    general = {
      ami_type = "AL2_x86_64"
      
      desired_size = var.node_desired_size
      min_size     = var.node_min_size
      max_size     = var.node_max_size

      labels = {
        role = "${var.project}-${var.env}-general"
        node-type = "general"
      }

      instance_types = var.node_instance_types
      capacity_type  = "ON_DEMAND"
      
      # Explicitly attach security group to this node group (CKV2_AWS_5 compliance)
      vpc_security_group_ids = [aws_security_group.eks_nodes.id]
      
      # Update configuration
      update_config = {
        max_unavailable_percentage = 33
      }
      
      # Launch template
      launch_template = {
        name_prefix = "eks-${var.project}-${var.env}"
        version     = "$Latest"
      }
    }
  }

  # Tags
  tags = var.tags
}

# Security Group for EKS Nodes
# Note: This security group is attached to EKS nodes via the eks_managed_node_group_defaults.vpc_security_group_ids
resource "aws_security_group" "eks_nodes" {
  name_prefix = "${var.project}-${var.env}-eks-nodes"
  description = "Security group for EKS nodes"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS outbound for AWS services"
  }
  
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP outbound for AWS services"
  }
  
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow DNS outbound for name resolution"
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.env}-eks-nodes-sg"
  })
}

# EKS Cluster IAM Role Mapping - Removed due to unsupported resource type
# The aws-auth ConfigMap is now managed automatically by the EKS module

# CloudWatch Log Group for EKS Cluster (with KMS encryption)
resource "aws_cloudwatch_log_group" "eks_cluster" {
  count = var.enable_cloudwatch_logs ? 1 : 0
  
  name              = "/aws/eks/${var.project}-${var.env}-eks/cluster"
  retention_in_days = 365  # Minimum 1 year for compliance
  kms_key_id        = aws_kms_key.eks_logs[0].arn

  tags = var.tags
}

# KMS key for EKS CloudWatch logs encryption
resource "aws_kms_key" "eks_logs" {
  count = var.enable_cloudwatch_logs ? 1 : 0
  
  description             = "KMS key for EKS CloudWatch logs encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs to use the key"
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "logs.amazonaws.com"
          }
        }
      }
    ]
  })
  
  tags = var.tags
}

resource "aws_kms_alias" "eks_logs" {
  count = var.enable_cloudwatch_logs ? 1 : 0
  
  name          = "alias/${var.project}-${var.env}-eks-logs"
  target_key_id = aws_kms_key.eks_logs[0].key_id
}

# EKS Control Plane Logging - Handled by the EKS module
# The module.eks already handles cluster creation with logging enabled

# KMS key for EKS secrets encryption
resource "aws_kms_key" "eks_secrets" {
  count = var.enable_eks_control_plane_logging ? 1 : 0
  
  description             = "KMS key for EKS secrets encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow EKS to use the key"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "eks.amazonaws.com"
          }
        }
      }
    ]
  })
  
  tags = var.tags
}

resource "aws_kms_alias" "eks_secrets" {
  count = var.enable_eks_control_plane_logging ? 1 : 0
  
  name          = "alias/${var.project}-${var.env}-eks-secrets"
  target_key_id = aws_kms_key.eks_secrets[0].key_id
}