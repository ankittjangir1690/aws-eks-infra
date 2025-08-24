# =============================================================================
# SECURITY MODULE OUTPUTS
# =============================================================================

output "guardduty_detector_id" {
  description = "GuardDuty detector ID (if enabled)"
  value       = var.enable_guardduty ? aws_guardduty_detector.main[0].id : null
}

output "guardduty_detector_arn" {
  description = "GuardDuty detector ARN (if enabled)"
  value       = var.enable_guardduty ? aws_guardduty_detector.main[0].arn : null
}

output "security_hub_account_id" {
  description = "Security Hub account ID (if enabled)"
  value       = var.enable_security_hub ? aws_securityhub_account.main[0].id : null
}

output "security_hub_account_arn" {
  description = "Security Hub account ARN (if enabled)"
  value       = var.enable_security_hub ? aws_securityhub_account.main[0].arn : null
}

output "config_recorder_id" {
  description = "Config recorder ID (if enabled)"
  value       = var.enable_config ? aws_config_configuration_recorder.main[0].id : null
}

output "config_recorder_arn" {
  description = "Config recorder ARN (if enabled)"
  value       = var.enable_config ? aws_config_configuration_recorder.main[0].arn : null
}

output "config_delivery_channel_id" {
  description = "Config delivery channel ID (if enabled)"
  value       = var.enable_config ? aws_config_delivery_channel.main[0].id : null
}

output "config_bucket_id" {
  description = "Config S3 bucket ID (if enabled)"
  value       = var.enable_config ? aws_s3_bucket.config_bucket[0].id : null
}

output "config_bucket_arn" {
  description = "Config S3 bucket ARN (if enabled)"
  value       = var.enable_config ? aws_s3_bucket.config_bucket[0].arn : null
}

output "config_role_arn" {
  description = "Config IAM role ARN (if enabled)"
  value       = var.enable_config ? aws_iam_role.config_role[0].arn : null
}

output "cloudtrail_id" {
  description = "CloudTrail ID (if enabled)"
  value       = var.enable_cloudtrail ? aws_cloudtrail.main[0].id : null
}

output "cloudtrail_arn" {
  description = "CloudTrail ARN (if enabled)"
  value       = var.enable_cloudtrail ? aws_cloudtrail.main[0].arn : null
}

output "cloudtrail_bucket_id" {
  description = "CloudTrail S3 bucket ID (if enabled)"
  value       = var.enable_cloudtrail ? aws_s3_bucket.cloudtrail_bucket[0].id : null
}

output "cloudtrail_bucket_arn" {
  description = "CloudTrail S3 bucket ARN (if enabled)"
  value       = var.enable_cloudtrail ? aws_s3_bucket.cloudtrail_bucket[0].arn : null
}

output "waf_web_acl_id" {
  description = "WAF Web ACL ID (if enabled)"
  value       = var.enable_waf ? aws_wafv2_web_acl.main[0].id : null
}

output "waf_web_acl_arn" {
  description = "WAF Web ACL ARN (if enabled)"
  value       = var.enable_waf ? aws_wafv2_web_acl.main[0].arn : null
}

output "waf_log_group_name" {
  description = "WAF CloudWatch log group name (if enabled)"
  value       = var.enable_waf ? aws_cloudwatch_log_group.waf[0].name : null
}

output "waf_log_group_arn" {
  description = "WAF CloudWatch log group ARN (if enabled)"
  value       = var.enable_waf ? aws_cloudwatch_log_group.waf[0].arn : null
}

output "inspector_enabler_id" {
  description = "Inspector enabler ID (if enabled)"
  value       = var.enable_inspector ? aws_inspector2_enabler.main[0].id : null
}

output "inspector_assessment_template_id" {
  description = "Inspector assessment template ID (if enabled)"
  value       = var.enable_inspector ? aws_inspector_assessment_template.main[0].id : null
}

output "inspector_assessment_template_arn" {
  description = "Inspector assessment template ARN (if enabled)"
  value       = var.enable_inspector ? aws_inspector_assessment_template.main[0].arn : null
}

output "inspector_target_id" {
  description = "Inspector target ID (if enabled)"
  value       = var.enable_inspector ? aws_inspector_target.main[0].id : null
}

output "inspector_target_arn" {
  description = "Inspector target ARN (if enabled)"
  value       = var.enable_inspector ? aws_inspector_target.main[0].arn : null
}

output "inspector_resource_group_id" {
  description = "Inspector resource group ID (if enabled)"
  value       = var.enable_inspector ? aws_inspector_resource_group.main[0].id : null
}

output "inspector_resource_group_arn" {
  description = "Inspector resource group ARN (if enabled)"
  value       = var.enable_inspector ? aws_inspector_resource_group.main[0].arn : null
}

# Security Summary
output "security_features_enabled" {
  description = "Summary of enabled security features"
  value = {
    guardduty     = var.enable_guardduty
    security_hub  = var.enable_security_hub
    config        = var.enable_config
    cloudtrail    = var.enable_cloudtrail
    waf           = var.enable_waf
    inspector     = var.enable_inspector
  }
}

output "security_resources" {
  description = "Summary of security resource IDs"
  value = {
    guardduty_detector = var.enable_guardduty ? aws_guardduty_detector.main[0].id : null
    security_hub       = var.enable_security_hub ? aws_securityhub_account.main[0].id : null
    config_recorder    = var.enable_config ? aws_config_configuration_recorder.main[0].id : null
    cloudtrail         = var.enable_cloudtrail ? aws_cloudtrail.main[0].id : null
    waf_web_acl       = var.enable_waf ? aws_wafv2_web_acl.main[0].id : null
    inspector          = var.enable_inspector ? aws_inspector_assessment_template.main[0].id : null
  }
}
