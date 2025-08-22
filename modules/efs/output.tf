# =============================================================================
# EFS MODULE OUTPUTS
# =============================================================================

output "efs_id" {
  description = "EFS file system ID"
  value       = aws_efs_file_system.main.id
}

output "efs_arn" {
  description = "EFS file system ARN"
  value       = aws_efs_file_system.main.arn
}

output "efs_dns_name" {
  description = "EFS file system DNS name"
  value       = aws_efs_file_system.main.dns_name
}

output "efs_mount_target_ids" {
  description = "List of EFS mount target IDs"
  value       = aws_efs_mount_target.main[*].id
}

output "efs_mount_target_ips" {
  description = "List of EFS mount target IP addresses"
  value       = aws_efs_mount_target.main[*].ip_address
}

output "efs_security_group_id" {
  description = "EFS security group ID"
  value       = aws_security_group.efs.id
}

output "efs_access_point_id" {
  description = "EFS access point ID (if created)"
  value       = var.create_access_point ? aws_efs_access_point.main[0].id : null
}

output "efs_access_point_arn" {
  description = "EFS access point ARN (if created)"
  value       = var.create_access_point ? aws_efs_access_point.main[0].arn : null
}

output "efs_backup_policy_id" {
  description = "EFS backup policy ID (if enabled)"
  value       = var.enable_backup ? aws_efs_backup_policy.main[0].id : null
}

output "efs_monitoring_role_arn" {
  description = "EFS monitoring IAM role ARN (if enabled)"
  value       = var.enable_monitoring ? aws_iam_role.efs_monitoring[0].arn : null
}

output "efs_cloudwatch_log_group_name" {
  description = "EFS CloudWatch log group name (if monitoring enabled)"
  value       = var.enable_monitoring ? aws_cloudwatch_log_group.efs[0].name : null
}   