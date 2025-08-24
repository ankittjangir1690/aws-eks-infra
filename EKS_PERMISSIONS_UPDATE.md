# EKS Permissions & Security Update - 2024

## Overview

This document outlines the comprehensive updates made to EKS cluster permissions and node permissions to ensure they are up-to-date, secure, and follow AWS best practices.

## Issues Fixed

### 1. **Duplicate IAM Role Definitions** ❌ → ✅
- **Before**: `eks_node_role` was defined in both `main.tf` and `iam.tf`
- **After**: Single role definition using EKS module's managed role
- **Benefit**: Eliminates conflicts and ensures consistency

### 2. **Overly Permissive Policies** ❌ → ✅
- **Before**: `AmazonEC2FullAccess` policy attached to node role
- **After**: Minimal, scoped policies with least privilege access
- **Benefit**: Reduces security risk and follows principle of least privilege

### 3. **Missing Modern EKS Permissions** ❌ → ✅
- **Before**: No VPC CNI policy, no EBS CSI driver policy
- **After**: Comprehensive policies for all modern EKS features
- **Benefit**: Supports current EKS best practices and features

### 4. **Security Vulnerabilities** ❌ → ✅
- **Before**: Broad resource access (`"*"`) in ALB policy
- **After**: Conditional access with proper tagging requirements
- **Benefit**: Prevents unauthorized resource access

### 5. **Outdated EKS Module Usage** ❌ → ✅
- **Before**: Using both EKS module and manual cluster creation
- **After**: Clean, single EKS module usage
- **Benefit**: Consistent, maintainable infrastructure

## New Permission Structure

### **Node Role Permissions**

#### **Core EKS Policies** (Automatically attached by EKS module)
- `AmazonEKSWorkerNodePolicy` - Basic EKS worker node permissions
- `AmazonEKS_CNI_Policy` - Network interface management
- `AmazonEC2ContainerRegistryReadOnly` - ECR access

#### **Custom Policies** (Conditionally attached)
- **ALB Ingress Controller Policy** - Minimal load balancer permissions
- **EBS CSI Driver Policy** - Storage volume management
- **VPC CNI Policy** - Advanced networking features

### **Cluster Role Permissions**
- `AmazonEKSClusterPolicy` - Basic cluster management
- **IRSA Support** - Service account role management
- **Conditional Logging** - CloudWatch integration

## Security Improvements

### **1. Least Privilege Access**
```hcl
# Before: Overly permissive
"ec2:*"  # Full EC2 access

# After: Scoped access with conditions
"ec2:CreateSecurityGroup" {
  Condition = {
    StringEquals = {
      "aws:RequestTag/kubernetes.io/cluster/${var.project}-${var.env}-eks" = "owned"
    }
  }
}
```

### **2. Resource Tagging Requirements**
```hcl
# All resources must be tagged with cluster ownership
Condition = {
  StringEquals = {
    "aws:RequestTag/kubernetes.io/cluster/${var.project}-${var.env}-eks" = "owned"
  }
}
```

### **3. Conditional Policy Attachment**
```hcl
# Policies only attached when features are enabled
resource "aws_iam_role_policy_attachment" "alb_ingress_controller" {
  count      = var.enable_alb_ingress ? 1 : 0
  role       = data.aws_iam_role.eks_node_role.name
  policy_arn = aws_iam_policy.alb_ingress_controller.arn
}
```

## Feature Control Variables

### **EKS Additional Features**
```hcl
# Load Balancer and Storage Features
enable_alb_ingress   = false   # ALB Ingress Controller
enable_ebs_csi       = false   # EBS CSI Driver  
enable_vpc_cni       = true    # VPC CNI (required)
```

### **Security Features**
```hcl
# Core Security Services
enable_guardduty     = false   # Threat detection
enable_security_hub  = false   # Security findings
enable_config        = false   # Compliance monitoring
enable_cloudtrail    = false   # API logging
```

## Permission Matrix

| Service | Policy | Access Level | Condition |
|---------|--------|--------------|-----------|
| **ALB Ingress** | Custom | Minimal | Cluster-owned resources only |
| **EBS CSI** | Custom | Minimal | Volume/snapshot management |
| **VPC CNI** | Custom | Minimal | Network interface management |
| **EKS Core** | AWS Managed | Standard | EKS service requirements |
| **Security** | Conditional | Feature-based | Enable flags control |

## Best Practices Implemented

### **1. Principle of Least Privilege**
- ✅ Minimal required permissions for each service
- ✅ Conditional access based on resource ownership
- ✅ No broad resource access (`"*"`)

### **2. Resource Tagging**
- ✅ All resources tagged with cluster ownership
- ✅ Conditional permissions based on tags
- ✅ Prevents cross-cluster resource access

### **3. Feature Flags**
- ✅ All features conditionally enabled
- ✅ No unnecessary permissions when features disabled
- ✅ Cost control through feature flags

### **4. Modern EKS Support**
- ✅ IRSA (IAM Roles for Service Accounts)
- ✅ VPC CNI with proper permissions
- ✅ EBS CSI driver support
- ✅ ALB Ingress Controller support

## Migration Guide

### **From Old to New**

1. **Update Variables**
   ```hcl
   # Add to terraform.tfvars
   enable_alb_ingress   = false  # Set based on needs
   enable_ebs_csi       = false  # Set based on needs
   enable_vpc_cni       = true   # Usually required
   ```

2. **Apply Changes**
   ```bash
   terraform plan    # Review changes
   terraform apply   # Apply updates
   ```

3. **Verify Permissions**
   ```bash
   # Check node role policies
   aws iam list-attached-role-policies --role-name <node-role-name>
   
   # Verify cluster functionality
   kubectl get nodes
   kubectl get pods --all-namespaces
   ```

## Security Checklist

- [x] **Duplicate roles eliminated**
- [x] **Overly permissive policies removed**
- [x] **Modern EKS permissions added**
- [x] **Security vulnerabilities fixed**
- [x] **Least privilege access implemented**
- [x] **Resource tagging requirements added**
- [x] **Feature flags implemented**
- [x] **IRSA support enabled**
- [x] **Conditional policy attachment**

## Cost Impact

### **Before (Over-permissioned)**
- ❌ Unnecessary EC2 permissions
- ❌ Broad resource access
- ❌ Potential security risks

### **After (Optimized)**
- ✅ Minimal required permissions
- ✅ Conditional feature enablement
- ✅ Reduced security risk
- ✅ Better cost control

## Monitoring & Compliance

### **CloudWatch Integration**
- ✅ EKS control plane logging
- ✅ Node group monitoring
- ✅ Custom metrics support

### **Security Monitoring**
- ✅ GuardDuty integration (optional)
- ✅ Security Hub integration (optional)
- ✅ Config compliance (optional)

## Next Steps

1. **Review current feature requirements**
2. **Enable only needed features**
3. **Monitor permission usage**
4. **Regular security audits**
5. **Update as EKS evolves**

---

**Result**: EKS cluster now has **enterprise-grade security** with **minimal permissions** and **full feature control**! 🎯
