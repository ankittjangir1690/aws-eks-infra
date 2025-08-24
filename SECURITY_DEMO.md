# Security Resource Conditional Creation Demo

## How It Works

All security resources in this repository are **conditionally created** using Terraform's `count` expression. Resources are only created when their respective `enable_` variable is set to `true`.

## Example: Security Module

### 1. Variable Definition
```hcl
# In variables.tf
variable "enable_guardduty" {
  description = "Enable AWS GuardDuty for threat detection"
  type        = bool
  default     = true  # Can be overridden in terraform.tfvars
}
```

### 2. Conditional Resource Creation
```hcl
# In modules/security/main.tf
resource "aws_guardduty_detector" "main" {
  count = var.enable_guardduty ? 1 : 0  # Only creates if enable_guardduty = true
  
  enable = true
  tags   = var.tags
}
```

### 3. Output Handling
```hcl
# In modules/security/outputs.tf
output "guardduty_detector_id" {
  description = "GuardDuty detector ID (if enabled)"
  value       = var.enable_guardduty ? aws_guardduty_detector.main[0].id : null
}
```

## Control Security Features

### Enable Only What You Need
```hcl
# In terraform.tfvars
enable_guardduty     = true    # ✅ Creates GuardDuty detector
enable_security_hub  = false   # ❌ No Security Hub resources created
enable_config        = true    # ✅ Creates AWS Config resources
enable_cloudtrail    = false   # ❌ No CloudTrail resources created
enable_waf           = false   # ❌ No WAF resources created
enable_inspector     = false   # ❌ No Inspector resources created
```

## What Happens When Disabled

When `enable_feature = false`:
- **No AWS resources are created** for that feature
- **No costs are incurred** for that feature
- **Outputs return `null`** for that feature
- **Dependencies are handled gracefully** (other resources don't fail)

## Security Features Available

| Feature | Variable | Default | Description |
|---------|----------|---------|-------------|
| GuardDuty | `enable_guardduty` | `true` | Threat detection |
| Security Hub | `enable_security_hub` | `true` | Security findings |
| AWS Config | `enable_config` | `true` | Compliance monitoring |
| CloudTrail | `enable_cloudtrail` | `true` | API call logging |
| WAF | `enable_waf` | `false` | Web application firewall |
| Inspector | `enable_inspector` | `false` | Vulnerability assessment |

## Cost Control

**Expensive features are disabled by default:**
- `enable_security_hub = false` (can be expensive)
- `enable_cloudtrail = false` (can be expensive)
- `enable_waf = false` (additional cost per request)
- `enable_inspector = false` (additional cost per assessment)

**Core security features enabled by default:**
- `enable_guardduty = true` (free tier available)
- `enable_config = true` (free tier available)

## Testing the Conditional Creation

1. **Check current state:**
   ```bash
   terraform plan
   ```

2. **Enable a feature:**
   ```bash
   # Edit terraform.tfvars
   enable_waf = true
   ```

3. **Apply changes:**
   ```bash
   terraform apply
   ```

4. **Verify resource creation:**
   ```bash
   terraform show | grep -A 10 "aws_wafv2_web_acl"
   ```

## Best Practices

1. **Start with minimal features** - only enable what you need
2. **Use environment-specific settings** - different values for dev/staging/prod
3. **Monitor costs** - expensive features are disabled by default
4. **Review security requirements** - enable features based on compliance needs
5. **Test in non-production** - verify functionality before enabling in production

## Example: Production vs Development

```hcl
# Development (terraform.tfvars.dev)
enable_guardduty     = true
enable_security_hub  = false
enable_config        = true
enable_cloudtrail    = false
enable_waf           = false
enable_inspector     = false

# Production (terraform.tfvars.prod)
enable_guardduty     = true
enable_security_hub  = true
enable_config        = true
enable_cloudtrail    = true
enable_waf           = true
enable_inspector     = true
```

This approach ensures you only pay for and manage the security features you actually need!
