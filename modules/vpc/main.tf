# =============================================================================
# VPC MODULE - Secure VPC Configuration
# =============================================================================

# Data sources for resource ARNs
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Main VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  # Enable VPC Flow Logs for security monitoring
  enable_network_address_usage_metrics = true

  tags = merge(var.tags, {
    Name = "${var.project}-${var.env}-vpc"
  })
}

# Restrict default VPC security group
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  # No ingress rules - deny all inbound traffic
  # No egress rules - deny all outbound traffic
  
  tags = merge(var.tags, {
    Name = "${var.project}-${var.env}-default-sg"
  })
}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = length(var.azs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = false  # Disable public IP assignment by default for security

  tags = merge(var.tags, {
    Name = "${var.project}-${var.env}-public-subnet-${count.index + 1}"
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/role/alb" = "1"
  })
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + length(var.azs))
  availability_zone = var.azs[count.index]

  tags = merge(var.tags, {
    Name = "${var.project}-${var.env}-private-subnet-${count.index + 1}"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.project}-${var.env}-igw"
  })
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
  
  tags = merge(var.tags, {
    Name = "${var.project}-${var.env}-nat-eip"
  })
}

# NAT Gateway
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(var.tags, {
    Name = "${var.project}-${var.env}-nat-gateway"
  })

  depends_on = [aws_internet_gateway.main]
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.env}-public-route-table"
  })
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
    # Note: This route is required for NAT Gateway to route private subnet traffic to internet
    # The NAT Gateway provides controlled outbound access while maintaining private subnet security
  }

  # VPC Peering route (if specified)
  dynamic "route" {
    for_each = var.vpc_peering_connection_id != "" ? [1] : []
    content {
      cidr_block                = "192.168.248.0/21"
      vpc_peering_connection_id = var.vpc_peering_connection_id
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.env}-private-route-table"
  })
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# VPC Flow Logs for security monitoring
resource "aws_flow_log" "vpc_flow_log" {
  count = var.enable_vpc_flow_logs ? 1 : 0
  
  iam_role_arn    = aws_iam_role.vpc_flow_log_role[0].arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log[0].arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.project}-${var.env}-vpc-flow-logs"
  })
}

# CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  count = var.enable_vpc_flow_logs ? 1 : 0
  
  name              = "/aws/vpc/flowlogs/${var.project}-${var.env}"
  retention_in_days = 365  # Minimum 1 year for compliance

  tags = var.tags
}

# KMS key for VPC Flow Logs encryption
resource "aws_kms_key" "vpc_flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0
  
  description             = "KMS key for VPC Flow Logs encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  
  tags = var.tags
}

resource "aws_kms_alias" "vpc_flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0
  
  name          = "alias/${var.project}-${var.env}-vpc-flow-logs"
  target_key_id = aws_kms_key.vpc_flow_logs[0].key_id
}

# IAM Role for VPC Flow Logs
resource "aws_iam_role" "vpc_flow_log_role" {
  count = var.enable_vpc_flow_logs ? 1 : 0
  
  name = "${var.project}-${var.env}-vpc-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for VPC Flow Logs
resource "aws_iam_role_policy" "vpc_flow_log_policy" {
  count = var.enable_vpc_flow_logs ? 1 : 0
  
  name = "${var.project}-${var.env}-vpc-flow-log-policy"
  role = aws_iam_role.vpc_flow_log_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*",
          "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-stream:*"
        ]
      }
    ]
  })
}