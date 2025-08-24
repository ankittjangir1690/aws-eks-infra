# =============================================================================
# SECURITY MODULE OUTPUTS - DISABLED DUE TO MISSING RESOURCES
# =============================================================================
# 
# All outputs have been commented out due to missing security resources
# Uncomment when security resources are properly implemented

# output "guardduty_detector_id" {
#   description = "GuardDuty detector ID"
#   value       = var.enable_guardduty ? aws_guardduty_detector.main[0].id : null
# }

# output "guardduty_detector_arn" {
#   description = "GuardDuty detector ARN"
#   value       = var.enable_guardduty ? aws_guardduty_detector.main[0].arn : null
# }

# output "securityhub_account_id" {
#   description = "Security Hub account ID"
#   value       = var.enable_security_hub ? aws_securityhub_account.main[0].id : null
# }

# output "config_recorder_name" {
#   description = "AWS Config recorder name"
#   value       = var.enable_config ? aws_config_configuration_recorder.main[0].name : null
# }
# 
# output "config_delivery_channel_name" {
#   description = "AWS Config delivery channel name"
#   value       = var.enable_config ? aws_config_delivery_channel.main[0].name : null
# }
# 
# output "config_bucket_name" {
#   description = "AWS Config S3 bucket name"
#   value       = var.enable_config ? aws_s3_bucket.config_bucket[0].bucket : null
# }
# 
# output "config_bucket_arn" {
#   description = "AWS Config S3 bucket ARN"
#   value       = var.enable_config ? aws_s3_bucket.config_bucket[0].arn : null
# }
# 
# output "config_role_arn" {
#   description = "AWS Config IAM role ARN"
#   value       = var.enable_config ? aws_iam_role.config_role[0].arn : null
# }

# output "cloudtrail_name" {
#   description = "CloudTrail name"
#   value       = var.enable_cloudtrail ? aws_cloudtrail.main[0].name : null
# }
# 
# output "cloudtrail_arn" {
#   description = "CloudTrail ARN"
#   value       = var.enable_cloudtrail ? aws_cloudtrail.main[0].arn : null
# }
# 
# output "cloudtrail_bucket_name" {
#   description = "CloudTrail S3 bucket name"
#   value       = var.enable_cloudtrail ? aws_s3_bucket.cloudtrail_bucket[0].bucket : null
# }
# 
# output "cloudtrail_bucket_arn" {
#   description = "CloudTrail S3 bucket ARN"
#   value       = var.enable_cloudtrail ? aws_s3_bucket.cloudtrail_bucket[0].arn : null
# }
# 
# output "cloudtrail_kms_key_arn" {
#   description = "CloudTrail KMS key ARN"
#   value       = var.enable_cloudtrail ? aws_kms_key.cloudtrail_encryption[0].arn : null
# }
# 
# output "cloudtrail_sns_topic_arn" {
#   description = "CloudTrail SNS topic ARN"
#   value       = var.enable_cloudtrail ? aws_sns_topic.cloudtrail_alerts[0].arn : null
# }

# output "waf_web_acl_arn" {
#   description = "WAF Web ACL ARN"
#   value       = var.enable_waf ? aws_wafv2_web_acl.main[0].arn : null
# }
# 
# output "waf_web_acl_id" {
#   description = "WAF Web ACL ID"
#   value       = var.enable_waf ? aws_wafv2_web_acl.main[0].id : null
# }
# 
# output "waf_log_group_name" {
#   description = "WAF CloudWatch log group name"
#   value       = var.enable_waf ? aws_cloudwatch_log_group.waf[0].id : null
# }
# 
# output "inspector_enabler_id" {
#   description = "Inspector v2 enabler ID"
#   value       = var.enable_inspector ? aws_inspector2_enabler.main[0].id : null
# }
# 
# output "security_resources" {
#   description = "Map of security resource IDs"
#   value = {
#     guardduty_detector = var.enable_guardduty ? aws_guardduty_detector.main[0].id : null
#     securityhub_account = var.enable_security_hub ? aws_securityhub_account.main[0].id : null
#     config_recorder = var.enable_config ? aws_config_configuration_recorder.main[0].name : null
#     config_delivery_channel = var.enable_config ? aws_config_delivery_channel.main[0].name : null
#     config_bucket = var.enable_config ? aws_s3_bucket.config_bucket[0].bucket : null
#     cloudtrail = var.enable_cloudtrail ? aws_cloudtrail.main[0].name : null
#     cloudtrail_bucket = var.enable_cloudtrail ? aws_s3_bucket.cloudtrail_bucket[0].bucket : null
#     waf_web_acl = var.enable_waf ? aws_wafv2_web_acl.main[0].id : null
#     inspector = var.enable_inspector ? aws_inspector2_enabler.main[0].id : null
#   }
# }
