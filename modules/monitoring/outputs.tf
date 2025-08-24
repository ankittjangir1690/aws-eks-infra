# =============================================================================
# MONITORING MODULE OUTPUTS
# =============================================================================

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alarm notifications"
  value       = var.enable_sns_notifications ? aws_sns_topic.alarms[0].arn : ""
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = var.enable_dashboard ? aws_cloudwatch_dashboard.eks_infrastructure[0].dashboard_name : ""
}

output "dashboard_arn" {
  description = "ARN of the CloudWatch dashboard"
  value       = var.enable_dashboard ? aws_cloudwatch_dashboard.eks_infrastructure[0].dashboard_arn : ""
}

output "alarm_names" {
  description = "Names of all created CloudWatch alarms"
  value = {
    eks_high_cpu        = var.enable_eks_alarms ? aws_cloudwatch_metric_alarm.eks_high_cpu[0].alarm_name : ""
    eks_high_memory     = var.enable_eks_alarms ? aws_cloudwatch_metric_alarm.eks_high_memory[0].alarm_name : ""
    eks_node_failures   = var.enable_eks_alarms ? aws_cloudwatch_metric_alarm.eks_node_failures[0].alarm_name : ""
    efs_high_connections = var.enable_efs_alarms ? aws_cloudwatch_metric_alarm.efs_high_connections[0].alarm_name : ""
    vpc_dropped_packets = var.enable_vpc_alarms ? aws_cloudwatch_metric_alarm.vpc_dropped_packets[0].alarm_name : ""
  }
}

output "sns_topic_name" {
  description = "Name of the SNS topic"
  value       = var.enable_sns_notifications ? aws_sns_topic.alarms[0].name : ""
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for SNS encryption"
  value       = var.enable_sns_notifications ? aws_kms_key.sns_encryption[0].arn : ""
}
