# 🚀 AWS EKS Infrastructure - Enterprise Grade

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-blue.svg)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-EKS-orange.svg)](https://aws.amazon.com/eks/)
[![Security](https://img.shields.io/badge/Security-Enterprise%20Grade-green.svg)](https://aws.amazon.com/security/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

> **Production-ready AWS EKS infrastructure with enterprise-grade security, monitoring, backup, and CI/CD**

## 🌟 **What's New in 2024**

- 🔒 **Advanced Security Module** - GuardDuty, Security Hub, Config, CloudTrail, WAF, Inspector
- 📊 **Comprehensive Monitoring** - CloudWatch dashboards, alarms, anomaly detection, RUM
- 💾 **Robust Backup & DR** - AWS Backup with cross-region and cross-account support
- 🚀 **CI/CD Pipeline** - GitHub Actions with security scanning and automated testing
- 🧪 **Testing Framework** - Terraform Compliance and custom Python tests
- 📚 **Complete Documentation** - Architecture guides and deployment instructions

## 📋 **Table of Contents**

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Security](#security)
- [Monitoring](#monitoring)
- [Backup & DR](#backup--dr)
- [CI/CD Pipeline](#cicd-pipeline)
- [Testing](#testing)
- [Deployment](#deployment)
- [Contributing](#contributing)
- [Support](#support)

## 🎯 **Overview**

This repository provides a **production-ready**, **enterprise-grade** AWS EKS infrastructure built with Terraform. It implements AWS best practices, security-first design, and comprehensive monitoring to create a robust Kubernetes platform.

### **Key Benefits**

- ✅ **Zero Trust Security** - Least privilege access, conditional feature enablement
- ✅ **Cost Optimized** - Feature flags control resource creation and costs
- ✅ **Production Ready** - Comprehensive monitoring, backup, and disaster recovery
- ✅ **Developer Friendly** - Automated CI/CD, testing, and documentation
- ✅ **Compliance Ready** - SOC2, security scanning, and audit trails

## 🏗️ **Architecture**

### **High-Level Architecture**

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              AWS Account                                        │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                        Security Layer                                   │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐      │   │
│  │  │  GuardDuty  │ │Security Hub │ │    Config   │ │ CloudTrail  │      │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘      │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐      │   │
│  │  │     WAF     │ │ Inspector   │ │   KMS       │ │   IAM       │      │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘      │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                      Infrastructure Layer                               │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐      │   │
│  │  │     VPC     │ │    EKS      │ │    EFS      │ │   Route53   │      │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘      │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                       Monitoring Layer                                  │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐      │   │
│  │  │CloudWatch   │ │    SNS      │ │   Evidently │ │     RUM     │      │   │
│  │  │  Dashboard  │ │Notifications│ │Feature Flags│ │Monitoring   │      │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘      │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                        Backup Layer                                     │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐      │   │
│  │  │AWS Backup   │ │Cross-Region │ │Cross-Account│ │   Reports   │      │   │
│  │  │   Vault     │ │   Backup    │ │   Backup    │ │  & Audits   │      │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘      │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### **Component Architecture**

- **🔒 Security Layer**: Multi-layered security with conditional enablement
- **🌐 Network Layer**: VPC with public/private subnets, NAT Gateway, VPC Flow Logs
- **⚙️ Compute Layer**: EKS cluster with managed node groups, IRSA support
- **💾 Storage Layer**: EFS with encryption, backup, and monitoring
- **📊 Monitoring Layer**: Comprehensive CloudWatch integration
- **💾 Backup Layer**: AWS Backup with disaster recovery planning

## ✨ **Features**

### **🔒 Security Features**

| Feature | Description | Default | Cost Impact |
|---------|-------------|---------|-------------|
| **GuardDuty** | Threat detection and monitoring | `false` | Low |
| **Security Hub** | Centralized security findings | `false` | Medium |
| **AWS Config** | Compliance monitoring | `false` | Low |
| **CloudTrail** | API call logging | `false` | Medium |
| **WAF** | Web application firewall | `false` | Per request |
| **Inspector** | Vulnerability assessment | `false` | Per assessment |

### **📊 Monitoring Features**

| Feature | Description | Default | Use Case |
|---------|-------------|---------|----------|
| **Dashboard** | CloudWatch infrastructure dashboard | `true` | Overview |
| **EKS Alarms** | Cluster and node monitoring | `true` | Performance |
| **EFS Alarms** | File system monitoring | `true` | Storage |
| **VPC Alarms** | Network monitoring | `true` | Networking |
| **Log Insights** | Advanced log querying | `false` | Troubleshooting |
| **Anomaly Detection** | ML-based monitoring | `false` | Advanced |

### **💾 Backup Features**

| Feature | Description | Default | DR Level |
|---------|-------------|---------|----------|
| **AWS Backup** | Automated backup orchestration | `false` | Basic |
| **Cross-Region** | Disaster recovery backup | `false` | Regional |
| **Cross-Account** | Multi-account backup | `false` | Enterprise |

### **🚀 EKS Features**

| Feature | Description | Default | Requirement |
|---------|-------------|---------|-------------|
| **VPC CNI** | Advanced networking | `true` | Required |
| **ALB Ingress** | Load balancer controller | `false` | Optional |
| **EBS CSI** | Storage driver | `false` | Optional |

## 🚀 **Quick Start**

### **Prerequisites**

- [Terraform](https://www.terraform.io/downloads.html) >= 1.5.0
- [AWS CLI](https://aws.amazon.com/cli/) configured
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (for cluster access)
- [Git](https://git-scm.com/) for version control

### **1. Clone Repository**

```bash
git clone https://github.com/yourusername/aws-eks-infra.git
cd aws-eks-infra
```

### **2. Configure Variables**

```bash
# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

### **3. Initialize Terraform**

```bash
# Initialize with S3 backend
terraform init

# Verify configuration
terraform plan
```

### **4. Deploy Infrastructure**

```bash
# Deploy to AWS
terraform apply

# Verify deployment
terraform output
```

### **5. Access EKS Cluster**

```bash
# Update kubeconfig
aws eks update-kubeconfig --region <region> --name <cluster-name>

# Verify cluster access
kubectl get nodes
kubectl get pods --all-namespaces
```

## ⚙️ **Configuration**

### **Core Configuration**

```hcl
# Project Configuration
project_name = "my-eks-project"
environment  = "dev"  # Options: dev, staging, prod, test
owner        = "Your Name"
cost_center  = "Engineering"

# AWS Configuration
region = "ap-south-1"  # Change to your preferred region

# VPC Configuration
vpc_cidr = "10.0.0.0/16"
availability_zones = ["ap-south-1a", "ap-south-1b"]
```

### **Security Configuration**

```hcl
# Security Features - Set to true only what you want enabled
enable_guardduty     = false   # Threat detection
enable_security_hub  = false   # Security findings (can be expensive)
enable_config        = false   # Compliance monitoring
enable_cloudtrail    = false   # API logging (can be expensive)
enable_waf           = false   # Web application firewall
enable_inspector     = false   # Vulnerability assessment
```

### **Monitoring Configuration**

```hcl
# Core Monitoring
enable_monitoring_dashboard = true   # CloudWatch dashboard
enable_eks_alarms         = true    # EKS alarms
enable_efs_alarms         = true    # EFS alarms
enable_vpc_alarms         = true    # VPC alarms

# Advanced Monitoring (optional)
enable_log_insights       = false   # Log Insights queries
enable_sns_notifications  = false   # SNS notifications
enable_anomaly_detection  = false   # Anomaly detection
```

### **Backup Configuration**

```hcl
# Core Backup
enable_backup             = false   # AWS Backup (can be expensive)
enable_cross_region_backup = false  # Cross-region backup
enable_cross_account_backup = false # Cross-account backup

# EFS Backup
enable_efs_backup      = false
enable_efs_monitoring  = false
```

## 🔒 **Security**

### **Security Model**

This infrastructure implements a **defense-in-depth** security approach:

1. **Network Security**
   - Private subnets for EKS nodes
   - VPC Flow Logs for traffic monitoring
   - Security groups with minimal required access

2. **Identity & Access Management**
   - IAM roles with least privilege
   - IRSA (IAM Roles for Service Accounts)
   - Conditional policy attachment

3. **Data Protection**
   - EFS encryption at rest and in transit
   - KMS key management
   - Backup encryption

4. **Threat Detection**
   - GuardDuty for threat monitoring
   - Security Hub for findings aggregation
   - CloudTrail for API audit

### **Security Best Practices**

- ✅ **Principle of Least Privilege** - Minimal required permissions
- ✅ **Resource Tagging** - Cluster ownership validation
- ✅ **Feature Flags** - Conditional security enablement
- ✅ **Encryption** - Data at rest and in transit
- ✅ **Monitoring** - Comprehensive security monitoring
- ✅ **Compliance** - SOC2, security scanning, audit trails

## 📊 **Monitoring**

### **CloudWatch Integration**

- **Infrastructure Dashboard** - Real-time overview of all resources
- **Custom Alarms** - Metric-based, composite, and anomaly detection
- **Log Management** - Centralized logging with retention policies
- **Performance Insights** - Contributor insights and RUM monitoring

### **Alarm Categories**

- **EKS Alarms** - Cluster health, node status, pod metrics
- **EFS Alarms** - File system performance, client connections
- **VPC Alarms** - Network performance, dropped packets
- **Security Alarms** - GuardDuty findings, WAF events

### **Monitoring Best Practices**

- ✅ **Real-time Monitoring** - 5-minute metric collection
- ✅ **Proactive Alerting** - Early warning for issues
- ✅ **Performance Tracking** - Resource utilization monitoring
- ✅ **Cost Monitoring** - Resource cost tracking and optimization

## 💾 **Backup & DR**

### **AWS Backup Strategy**

- **Daily Backups** - Point-in-time recovery
- **Weekly Backups** - Extended retention for compliance
- **Monthly Backups** - Long-term archival
- **Cross-Region** - Disaster recovery planning

### **Backup Components**

- **EKS Resources** - Cluster configuration and data
- **EFS File Systems** - Persistent storage backup
- **VPC Resources** - Network configuration backup
- **IAM Resources** - Identity and access backup

### **Disaster Recovery**

- **RTO (Recovery Time Objective)** - 4-8 hours
- **RPO (Recovery Point Objective)** - 24 hours
- **Cross-Region Recovery** - Geographic redundancy
- **Automated Recovery** - Infrastructure as Code

## 🚀 **CI/CD Pipeline**

### **GitHub Actions Workflow**

The repository includes a comprehensive CI/CD pipeline:

```yaml
name: 'Terraform CI/CD Pipeline'

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  - security-scan      # Trivy + Checkov security scanning
  - terraform-validate # Format, init, validate, plan
  - infrastructure-test # Compliance and custom testing
  - deploy            # Multi-environment deployment
  - verify            # Post-deployment verification
  - cleanup           # Notifications and PR comments
```

### **Pipeline Features**

- **Security Scanning** - Trivy vulnerability scanning, Checkov IaC security
- **Automated Testing** - Terraform Compliance, custom Python tests
- **Multi-Environment** - Development and production deployments
- **Quality Gates** - Validation, testing, and verification steps
- **Notifications** - Slack, email, and PR status updates

## 🧪 **Testing**

### **Testing Framework**

- **Terraform Compliance** - Policy-as-code testing with Gherkin syntax
- **Custom Python Tests** - Infrastructure validation using boto3
- **Security Scanning** - Automated vulnerability and security checks
- **Integration Testing** - End-to-end infrastructure validation

### **Test Categories**

- **Security Tests** - IAM policies, security groups, encryption
- **Compliance Tests** - AWS best practices, security standards
- **Functionality Tests** - Resource creation, connectivity, performance
- **Integration Tests** - Module interaction, dependency validation

## 🚀 **Deployment**

### **Environment Strategy**

- **Development** - Feature testing and development
- **Staging** - Pre-production validation
- **Production** - Live workload deployment

### **Deployment Process**

1. **Plan Review** - `terraform plan` with detailed output
2. **Security Scan** - Automated security validation
3. **Compliance Check** - Policy-as-code validation
4. **Infrastructure Test** - Custom validation scripts
5. **Deployment** - Automated infrastructure provisioning
6. **Verification** - Post-deployment validation
7. **Monitoring** - Continuous monitoring and alerting

### **Rollback Strategy**

- **State Management** - Terraform state versioning
- **Backup Recovery** - AWS Backup restoration
- **Infrastructure Rebuild** - Complete infrastructure recreation
- **Data Recovery** - EFS and EKS data restoration

## 📚 **Documentation**

### **Available Documentation**

- **README.md** - This comprehensive guide
- **ARCHITECTURE.md** - Detailed architecture documentation
- **SECURITY.md** - Security implementation details
- **DEPLOYMENT.md** - Step-by-step deployment guide
- **EKS_PERMISSIONS_UPDATE.md** - Permission improvements
- **SECURITY_DEMO.md** - Security feature demonstration

### **Documentation Standards**

- **Clear Examples** - Code snippets and configuration examples
- **Best Practices** - AWS and Terraform best practices
- **Troubleshooting** - Common issues and solutions
- **Security Guidelines** - Security implementation guidance

## 🤝 **Contributing**

### **Contribution Guidelines**

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Make your changes** following the coding standards
4. **Test your changes** with the testing framework
5. **Submit a pull request** with detailed description

### **Development Setup**

```bash
# Clone your fork
git clone https://github.com/yourusername/aws-eks-infra.git

# Add upstream remote
git remote add upstream https://github.com/original/aws-eks-infra.git

# Create development branch
git checkout -b develop

# Make changes and test
terraform plan
terraform apply

# Commit and push
git add .
git commit -m "Add amazing feature"
git push origin develop
```

### **Code Standards**

- **Terraform** - Use `terraform fmt` and `terraform validate`
- **Documentation** - Update relevant documentation
- **Testing** - Add tests for new features
- **Security** - Follow security best practices

## 🆘 **Support**

### **Getting Help**

- **Issues** - Create GitHub issues for bugs and feature requests
- **Discussions** - Use GitHub Discussions for questions
- **Documentation** - Check the comprehensive documentation
- **Community** - Join the community for support

### **Common Issues**

- **Permission Errors** - Check IAM roles and policies
- **Network Issues** - Verify VPC and security group configuration
- **Resource Limits** - Check AWS service quotas
- **Cost Optimization** - Review feature flags and resource sizing

### **Support Resources**

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform Documentation](https://www.terraform.io/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 **Acknowledgments**

- **AWS EKS Team** - For the excellent managed Kubernetes service
- **HashiCorp** - For the powerful Terraform infrastructure tool
- **Open Source Community** - For the amazing tools and libraries
- **Contributors** - For helping improve this infrastructure

---

## 🎯 **Quick Status Check**

| Component | Status | Description |
|-----------|--------|-------------|
| **VPC** | ✅ Complete | Multi-AZ with public/private subnets |
| **EKS** | ✅ Complete | Production-ready cluster with IRSA |
| **EFS** | ✅ Complete | Encrypted storage with backup |
| **Security** | ✅ Complete | Enterprise-grade security features |
| **Monitoring** | ✅ Complete | Comprehensive CloudWatch integration |
| **Backup** | ✅ Complete | AWS Backup with DR planning |
| **CI/CD** | ✅ Complete | Automated pipeline with testing |
| **Documentation** | ✅ Complete | Comprehensive guides and examples |

**Your infrastructure is production-ready with enterprise-grade security! 🚀**

---

**⭐ Star this repository if it helped you! ⭐**
