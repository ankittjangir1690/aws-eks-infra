# =============================================================================
# BACKUP MODULE OUTPUTS
# =============================================================================

output "backup_vault_arn" {
  description = "ARN of the primary backup vault"
  value       = var.enable_backup ? aws_backup_vault.main[0].arn : ""
}

output "backup_vault_name" {
  description = "Name of the primary backup vault"
  value       = var.enable_backup ? aws_backup_vault.main[0].name : ""
}

output "backup_plan_arn" {
  description = "ARN of the backup plan"
  value       = var.enable_backup ? aws_backup_plan.main[0].arn : ""
}

output "backup_plan_name" {
  description = "Name of the backup plan"
  value       = var.enable_backup ? aws_backup_plan.main[0].name : ""
}

output "dr_backup_vault_arn" {
  description = "ARN of the DR region backup vault"
  value       = var.enable_cross_region_backup ? aws_backup_vault.dr[0].arn : ""
}

output "dr_backup_vault_name" {
  description = "Name of the DR region backup vault"
  value       = var.enable_cross_region_backup ? aws_backup_vault.dr[0].name : ""
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for backup encryption"
  value       = var.enable_backup ? aws_kms_key.backup_default[0].arn : ""
}

output "kms_key_id" {
  description = "ID of the KMS key used for backup encryption"
  value       = var.enable_backup ? aws_kms_key.backup_default[0].key_id : ""
}
