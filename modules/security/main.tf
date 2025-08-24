# =============================================================================
# SECURITY MODULE - Simplified Configuration (WAF Disabled)
# =============================================================================

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Note: The following security services have been removed:
# - AWS GuardDuty
# - AWS Security Hub  
# - AWS Config
# - CloudTrail
# - AWS Inspector

# Note: WAF WebACL has been removed for now
# It can be re-enabled later when WAF compliance is needed

# Note: CloudWatch Log Group for WAF has been removed for now
# It can be re-enabled later when WAF compliance is needed

# Note: WAF logging configuration has been removed for now
# It can be re-enabled later when WAF compliance is needed

# Note: KMS key for WAF encryption has been removed for now
# It can be re-enabled later when WAF compliance is needed
