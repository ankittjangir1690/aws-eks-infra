# =============================================================================
# MONITORING MODULE - Advanced Monitoring and Alerting
# =============================================================================

# CloudWatch Dashboard for EKS Infrastructure
resource "aws_cloudwatch_dashboard" "eks_infrastructure" {
  count = var.enable_dashboard ? 1 : 0
  
  dashboard_name = "${var.project}-${var.env}-eks-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EKS", "ClusterFailedNodeCount", "ClusterName", "${var.project}-${var.env}-eks"],
            [".", "ClusterTotalNodes", ".", "."],
            [".", "ClusterActiveNodes", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "EKS Cluster Node Status"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "${var.project}-${var.env}-eks-nodegroup-general"],
            [".", "NetworkIn", ".", "."],
            [".", "NetworkOut", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "EKS Node Performance"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EFS", "ClientConnections", "FileSystemId", var.efs_file_system_id],
            [".", "TotalIOBytes", ".", "."],
            [".", "MetadataIOBytes", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "EFS Performance"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/VPC", "ActiveFlowCount", "VPCId", var.vpc_id],
            [".", "NewFlowCount", ".", "."],
            [".", "PacketsDroppedCount", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "VPC Network Activity"
        }
      }
    ]
  })
}

# CloudWatch Alarms for EKS
resource "aws_cloudwatch_metric_alarm" "eks_high_cpu" {
  count = var.enable_eks_alarms ? 1 : 0
  
  alarm_name          = "${var.project}-${var.env}-eks-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EKS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "EKS cluster CPU utilization is high"
  alarm_actions       = var.alarm_actions
  
  dimensions = {
    ClusterName = "${var.project}-${var.env}-eks"
  }
  
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "eks_high_memory" {
  count = var.enable_eks_alarms ? 1 : 0
  
  alarm_name          = "${var.project}-${var.env}-eks-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/EKS"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "EKS cluster memory utilization is high"
  alarm_actions       = var.alarm_actions
  
  dimensions = {
    ClusterName = "${var.project}-${var.env}-eks"
  }
  
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "eks_node_failures" {
  count = var.enable_eks_alarms ? 1 : 0
  
  alarm_name          = "${var.project}-${var.env}-eks-node-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ClusterFailedNodeCount"
  namespace           = "AWS/EKS"
  period              = 300
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "EKS cluster has failed nodes"
  alarm_actions       = var.alarm_actions
  
  dimensions = {
    ClusterName = "${var.project}-${var.env}-eks"
  }
  
  tags = var.tags
}

# CloudWatch Alarms for EFS
resource "aws_cloudwatch_metric_alarm" "efs_high_connections" {
  count = var.enable_efs_alarms ? 1 : 0
  
  alarm_name          = "${var.project}-${var.env}-efs-high-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ClientConnections"
  namespace           = "AWS/EFS"
  period              = 300
  statistic           = "Average"
  threshold           = 1000
  alarm_description   = "EFS has high number of client connections"
  alarm_actions       = var.alarm_actions
  
  dimensions = {
    FileSystemId = var.efs_file_system_id
  }
  
  tags = var.tags
}

# CloudWatch Alarms for VPC
resource "aws_cloudwatch_metric_alarm" "vpc_dropped_packets" {
  count = var.enable_vpc_alarms ? 1 : 0
  
  alarm_name          = "${var.project}-${var.env}-vpc-dropped-packets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "PacketsDroppedCount"
  namespace           = "AWS/VPC"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  
  dimensions = {
    VPCId = var.vpc_id
  }
  
  alarm_actions       = var.alarm_actions
  alarm_description   = "VPC dropped packets threshold exceeded"
  
  tags = var.tags
}

# CloudWatch Log Insights Queries
resource "aws_cloudwatch_query_definition" "eks_logs" {
  count = var.enable_log_insights ? 1 : 0
  
  name = "${var.project}-${var.env}-eks-logs-query"
  
  log_group_names = [
    "/aws/eks/${var.project}-${var.env}-eks/cluster",
    "/aws/vpc/flowlogs/${var.project}-${var.env}"
  ]
  
  query_string = <<EOF
fields @timestamp, @message
| filter @message like /ERROR/ or @message like /WARN/
| sort @timestamp desc
| limit 100
EOF
}

# SNS Topic for Alarms
resource "aws_sns_topic" "alarms" {
  count = var.enable_sns_notifications ? 1 : 0
  
  name = "${var.project}-${var.env}-alarms-topic"
  
  # Enable KMS encryption
  kms_master_key_id = aws_kms_key.sns_encryption[0].arn
  
  tags = var.tags
}

# KMS key for SNS encryption
resource "aws_kms_key" "sns_encryption" {
  count = var.enable_sns_notifications ? 1 : 0
  
  description             = "KMS key for SNS topic encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  
  tags = var.tags
}

resource "aws_kms_alias" "sns_encryption" {
  count = var.enable_sns_notifications ? 1 : 0
  
  name          = "alias/${var.project}-${var.env}-sns-encryption"
  target_key_id = aws_kms_key.sns_encryption[0].key_id
}

# SNS Topic Subscription (Email)
resource "aws_sns_topic_subscription" "alarms_email" {
  count = var.enable_sns_notifications ? 1 : 0
  
  topic_arn = aws_sns_topic.alarms[0].arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# CloudWatch Composite Alarm for Critical Issues
resource "aws_cloudwatch_composite_alarm" "critical_infrastructure" {
  count = var.enable_composite_alarms ? 1 : 0
  
  alarm_name = "${var.project}-${var.env}-critical-infrastructure"
  
  alarm_rule = "ALARM(${aws_cloudwatch_metric_alarm.eks_node_failures[0].alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.vpc_dropped_packets[0].alarm_name})"
  
  alarm_description = "Critical infrastructure issues detected"
  alarm_actions     = var.alarm_actions
  
  tags = var.tags
}

# CloudWatch Anomaly Detection
resource "aws_cloudwatch_metric_alarm" "eks_cpu_anomaly" {
  count = var.enable_anomaly_detection ? 1 : 0
  
  alarm_name          = "${var.project}-${var.env}-eks-cpu-anomaly"
  comparison_operator = "GreaterThanUpperThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EKS"
  period              = 300
  statistic           = "Average"
  alarm_description   = "EKS CPU utilization is anomalously high"
  alarm_actions       = var.alarm_actions
  
  dimensions = {
    ClusterName = "${var.project}-${var.env}-eks"
  }
  
  # Anomaly detection configuration
  threshold_metric_id = "e1"
  
  tags = var.tags
}

# CloudWatch Contributor Insights for EKS API calls
resource "aws_cloudwatch_contributor_insight_rule" "eks_api_calls" {
  count = var.enable_contributor_insights ? 1 : 0
  
  rule_name = "${var.project}-${var.env}-eks-api-calls"
  
  rule_definition = "{\"SchemaVersion\":\"1.0\",\"ContributionInsightsRuleDefinition\":[{\"LogGroupName\":\"/aws/eks/${var.project}-${var.env}-eks/cluster\"}]}"
  
  tags = var.tags
}

# CloudWatch Evidently - Feature Flags
resource "aws_evidently_project" "main" {
  count = var.enable_evidently ? 1 : 0
  
  name        = "${var.project}-${var.env}-evidently"
  description = "Evidently project for ${var.project}-${var.env}"
  
  tags = var.tags
}

# CloudWatch RUM - Real User Monitoring
resource "aws_rum_app_monitor" "main" {
  count = var.enable_rum ? 1 : 0
  
  name   = "${var.project}-${var.env}-rum-monitor"
  domain = var.rum_domain
  
  app_monitor_configuration {
    allow_cookies = true
    enable_xray   = true
    session_sample_rate = 0.1
    telemetries = ["errors", "performance", "http"]
  }
  
  tags = var.tags
}

# IAM Role for RUM
resource "aws_iam_role" "rum_role" {
  count = var.enable_rum ? 1 : 0
  
  name = "${var.project}-${var.env}-rum-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rum.amazonaws.com"
        }
      }
    ]
  })
  
  tags = var.tags
}

# Cognito Identity Pool for RUM
resource "aws_cognito_identity_pool" "main" {
  count = var.enable_rum ? 1 : 0
  
  identity_pool_name = "${var.project}-${var.env}-rum-identity-pool"
  
  allow_unauthenticated_identities = false  # Disable guest access for security
  
  tags = var.tags
}
