# =============================================================================
# EKS MODULE - Secure EKS Cluster Configuration
# =============================================================================

# EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0.0"

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
  }

  # EKS managed node group defaults
  eks_managed_node_group_defaults = {
    disk_size = 30
    disk_type = "gp3"
    
    # Enable detailed monitoring
    enable_monitoring = true
    
    # Security configurations
    vpc_security_group_ids = [aws_security_group.eks_nodes.id]
    
    # IAM role configuration
    iam_role_use_name_prefix = true
    iam_role_name            = aws_iam_role.eks_node_role.name
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

# IAM Role for EKS Nodes
resource "aws_iam_role" "eks_node_role" {
  name = "${var.project}-${var.env}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach required policies to EKS node role
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

# Security Group for EKS Nodes
resource "aws_security_group" "eks_nodes" {
  name_prefix = "${var.project}-${var.env}-eks-nodes"
  description = "Security group for EKS nodes"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.env}-eks-nodes-sg"
  })
}

# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.project}-${var.env}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach required policies to EKS cluster role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# EKS Cluster IAM Role Mapping
resource "aws_auth_configmap" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = aws_iam_role.eks_node_role.arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      }
    ])
    
    mapUsers = yamlencode([
      for user in var.eks_admin_users : {
        userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${user}"
        username = user
        groups   = ["system:masters"]
      }
    ])
  }

  depends_on = [module.eks]
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# CloudWatch Log Group for EKS Cluster
resource "aws_cloudwatch_log_group" "eks_cluster" {
  count = var.enable_cloudwatch_logs ? 1 : 0
  
  name              = "/aws/eks/${var.project}-${var.env}-eks/cluster"
  retention_in_days = 30

  tags = var.tags
}

# EKS Control Plane Logging
resource "aws_eks_cluster" "main" {
  count = var.enable_eks_control_plane_logging ? 1 : 0
  
  name     = "${var.project}-${var.env}-eks"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = var.private_subnets_eks
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = var.allowed_public_cidrs
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_cloudwatch_log_group.eks_cluster
  ]

  tags = var.tags
}