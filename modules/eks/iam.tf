resource "aws_iam_role" "eks_node_role" {
  name = "${var.project}-${var.env}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}
# Attach EKS worker node policy
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# Attach EKS CNI policy (for network interface management)
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "alb_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}
# Attach required ALB ingress policy
# resource "aws_iam_role_policy_attachment" "eks_alb_ingress_policy" {
#   role       = aws_iam_role.eks_node_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_ALBIngressControllerPolicy"
# }

resource "aws_iam_policy" "alb_ingress_controller" {
  name        = "${var.project}-${var.env}-ALBIngressControllerPolicy"
  description = "Policy for ALB Ingress Controller"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "elasticloadbalancing:*" 
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeRouteTables",
          "ec2:DescribeVpcs",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "sts:AssumeRole"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "iam:CreateServiceLinkedRole",
          "iam:GetRole",
          "iam:AttachRolePolicy"
        ],
        Resource = "*",
        Condition = {
          "StringEquals": {
            "iam:AWSServiceName": "elasticloadbalancing.amazonaws.com"
          }
        }
      },
        {
        Effect = "Allow",
        Action = [
          "ecr:*"
        ],
        Resource = "*"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "ALBIngressControllerPolicyAttach" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = aws_iam_policy.alb_ingress_controller.arn
  #   depends_on = [
  #   aws_iam_role.eks_node_role,          # Ensure the role is created
  #   aws_iam_policy.alb_ingress_controller # Ensure the policy is created
  # ]
}

# resource "aws_iam_role_policy_attachment" "attach_alb_ingress_policy" {
#   policy_arn = aws_iam_policy.alb_ingress_controller.arn
#   role       = module.eks.node_group_role_arns["general"]  # Adjust to your node group name
# }

# resource "aws_iam_role_policy_attachment" "attach_alb_ingress_policy" {
#   for_each   = toset(keys(module.eks.node_groups_iam_role_name))
#   policy_arn = aws_iam_policy.alb_ingress_controller.arn
#   role       = module.eks.node_groups[each.key].iam_role_name
# }
