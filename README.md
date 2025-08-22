# AWS EKS Infrastructure with Terraform

A secure, production-ready AWS EKS infrastructure built with Terraform following security best practices.

## 🚀 Features

- **Secure VPC Configuration**: Multi-AZ setup with public/private subnets, NAT Gateway, and VPC Flow Logs
- **Production EKS Cluster**: Latest EKS version with managed node groups, IRSA, and security hardening
- **EFS Storage**: Encrypted EFS file system with access controls and backup policies
- **Security First**: IAM roles with least privilege, security groups, encryption, and monitoring
- **Infrastructure as Code**: Fully automated infrastructure deployment and management
- **Best Practices**: Follows AWS Well-Architected Framework and Terraform best practices

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS Account                         │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐              │
│  │   Public Subnet │    │  Private Subnet │              │
│  │   (AZ-1a)       │    │   (AZ-1a)      │              │
│  │                 │    │                 │              │
│  │ ┌─────────────┐ │    │ ┌─────────────┐ │              │
│  │ │Internet     │ │    │ │EKS Node    │ │              │
│  │ │Gateway      │ │    │ │Group       │ │              │
│  │ └─────────────┘ │    │ └─────────────┘ │              │
│  │ ┌─────────────┐ │    │ ┌─────────────┐ │              │
│  │ │NAT Gateway  │ │    │ │EFS Mount   │ │              │
│  │ └─────────────┘ │    │ │Target      │ │              │
│  └─────────────────┘    │ └─────────────┘ │              │
│                         └─────────────────┘              │
│  ┌─────────────────┐    ┌─────────────────┐              │
│  │   Public Subnet │    │  Private Subnet │              │
│  │   (AZ-1b)       │    │   (AZ-1b)      │              │
│  │                 │    │                 │              │
│  │ ┌─────────────┐ │    │ ┌─────────────┐ │              │
│  │ │Load         │ │    │ │EKS Node    │ │              │
│  │ │Balancer     │ │    │ │Group       │ │              │
│  │ └─────────────┘ │    │ └─────────────┘ │              │
│  │                 │    │ ┌─────────────┐ │              │
│  │                 │    │ │EFS Mount   │ │              │
│  │                 │    │ │Target      │ │              │
│  └─────────────────┘    │ └─────────────┘ │              │
│                         └─────────────────┘              │
│                                                           │
│  ┌─────────────────────────────────────────────────────┐  │
│  │                EKS Control Plane                   │  │
│  │              (Multi-AZ Managed)                    │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                           │
│  ┌─────────────────────────────────────────────────────┐  │
│  │                EFS File System                      │  │
│  │              (Encrypted, Multi-AZ)                 │  │
│  └─────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 📋 Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- AWS account with necessary permissions
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) (for cluster management)

## 🔐 Security Features

- **VPC Flow Logs**: Network traffic monitoring and logging
- **Encryption**: EFS encryption at rest, EKS secrets encryption
- **IAM Roles**: Least privilege access with proper role separation
- **Security Groups**: Restrictive network access controls
- **CloudWatch Logs**: Centralized logging and monitoring
- **Backup Policies**: Automated backup and recovery

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd aws-eks-infra
```

### 2. Configure Variables

Copy the example variables file and customize it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
project_name = "my-project"
environment  = "dev"
region       = "us-west-2"
eks_admin_users = ["your-iam-username"]
allowed_public_cidrs = ["YOUR_IP/32"]
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Plan the Deployment

```bash
terraform plan
```

### 5. Deploy Infrastructure

```bash
terraform apply
```

### 6. Configure kubectl

```bash
aws eks update-kubeconfig --region <region> --name <cluster-name>
```

## 📁 Project Structure

```
aws-eks-infra/
├── README.md                 # This file
├── main.tf                   # Main Terraform configuration
├── variables.tf              # Variable definitions
├── outputs.tf                # Output values
├── providers.tf              # Provider configuration
├── backend.tf                # Backend configuration (S3)
├── terraform.tfvars.example  # Example variable values
├── .gitignore               # Git ignore file
└── modules/                  # Terraform modules
    ├── vpc/                  # VPC and networking
    ├── eks/                  # EKS cluster
    ├── efs/                  # EFS file system
    ├── alb/                  # Application Load Balancer
    ├── route53/              # DNS management
    └── devops/               # DevOps tools
```

## 🔧 Configuration

### VPC Configuration

- **CIDR Block**: 10.0.0.0/16 (configurable)
- **Availability Zones**: 2 AZs for high availability
- **Subnets**: Public and private subnets in each AZ
- **NAT Gateway**: For private subnet internet access
- **VPC Flow Logs**: Network traffic monitoring

### EKS Configuration

- **Cluster Version**: Latest stable EKS version
- **Node Groups**: Managed node groups with auto-scaling
- **IRSA**: IAM Roles for Service Accounts enabled
- **Control Plane Logging**: API, audit, and system logs
- **Security Groups**: Restrictive access controls

### EFS Configuration

- **Encryption**: At-rest encryption enabled
- **Performance**: General purpose with bursting throughput
- **Access Control**: Security group-based access
- **Backup**: Automated backup policies (optional)
- **Monitoring**: CloudWatch integration (optional)

## 🛡️ Security Best Practices

### Network Security

- Use private subnets for EKS nodes
- Restrict public access to EKS cluster endpoint
- Implement VPC Flow Logs for traffic monitoring
- Use security groups with minimal required access

### IAM Security

- Follow principle of least privilege
- Use IAM roles instead of access keys
- Enable MFA for all users
- Regular access reviews and rotation

### Data Security

- Enable encryption at rest for all storage
- Use encrypted communication (TLS/HTTPS)
- Implement proper backup and recovery
- Regular security audits and penetration testing

## 📊 Monitoring and Logging

### CloudWatch Integration

- VPC Flow Logs for network monitoring
- EKS control plane logs
- EFS access logs (optional)
- Custom metrics and dashboards

### Log Retention

- VPC Flow Logs: 30 days
- EKS Logs: 30 days
- EFS Logs: 30 days (configurable)

## 🔄 Backup and Recovery

### EFS Backup

- Automated daily backups
- Configurable retention periods
- Cross-region replication (optional)
- Point-in-time recovery

### Infrastructure Backup

- Terraform state stored in S3
- State locking with DynamoDB
- Version control for all configurations
- Disaster recovery procedures

## 🚨 Important Security Notes

⚠️ **CRITICAL**: Never commit `terraform.tfvars` to version control
⚠️ **CRITICAL**: Restrict `allowed_public_cidrs` in production
⚠️ **CRITICAL**: Use strong IAM policies and rotate credentials regularly
⚠️ **CRITICAL**: Enable CloudTrail for API call logging

## 🧪 Testing

### Pre-deployment Validation

```bash
terraform validate
terraform fmt -check
```

### Post-deployment Testing

```bash
# Test EKS cluster access
kubectl get nodes

# Test EFS connectivity
kubectl run test-efs --image=busybox --rm -it --restart=Never -- sh
```

## 📚 Additional Resources

- [AWS EKS Best Practices](https://aws.amazon.com/eks/best-practices/)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

This infrastructure is designed for production use but should be thoroughly tested in your environment. Always review security configurations and adjust based on your specific requirements and compliance needs.

## 🆘 Support

For issues and questions:
- Create an issue in the repository
- Review the troubleshooting guide
- Check AWS and Terraform documentation
- Consult with your security team

---

**Remember**: Security is a shared responsibility. Regularly review and update your security configurations!
