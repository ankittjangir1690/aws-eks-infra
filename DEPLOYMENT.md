# Deployment Guide

This guide provides step-by-step instructions for deploying the AWS EKS infrastructure using Terraform.

## 📋 Prerequisites

### Required Tools
- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) >= 2.0
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) >= 1.25
- [Git](https://git-scm.com/) for version control

### AWS Account Setup
- AWS account with appropriate permissions
- IAM user with programmatic access
- Access key and secret key configured
- Appropriate AWS region selected

### Required AWS Permissions
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*",
                "eks:*",
                "iam:*",
                "efs:*",
                "logs:*",
                "cloudwatch:*",
                "elasticloadbalancing:*",
                "route53:*",
                "s3:*",
                "dynamodb:*",
                "kms:*"
            ],
            "Resource": "*"
        }
    ]
}
```

## 🚀 Step-by-Step Deployment

### Step 1: Clone and Setup Repository

```bash
# Clone the repository
git clone <repository-url>
cd aws-eks-infra

# Verify the structure
ls -la
```

### Step 2: Configure AWS Credentials

```bash
# Configure AWS CLI
aws configure

# Or set environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="ap-south-1"

# Verify configuration
aws sts get-caller-identity
```

### Step 3: Configure Terraform Variables

```bash
# Copy example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit the file with your values
nano terraform.tfvars
```

**Required Variables:**
```hcl
project_name = "my-eks-project"
environment  = "dev"
eks_admin_users = ["your-iam-username"]
allowed_public_cidrs = ["YOUR_IP_ADDRESS/32"]
```

**Optional Variables:**
```hcl
region = "ap-south-1"
vpc_cidr = "10.0.0.0/16"
availability_zones = ["ap-south-1a", "ap-south-1b"]
eks_cluster_version = "1.32"
```

### Step 4: Initialize Terraform

```bash
# Initialize Terraform
terraform init

# Verify initialization
terraform version
terraform providers
```

### Step 5: Validate Configuration

```bash
# Validate Terraform configuration
terraform validate

# Format code (optional)
terraform fmt

# Check formatting
terraform fmt -check
```

### Step 6: Plan Deployment

```bash
# Create deployment plan
terraform plan -out=tfplan

# Review the plan carefully
terraform show tfplan
```

**Important things to verify in the plan:**
- Resource names and tags
- Security group rules
- IAM roles and policies
- Network configurations
- Cost implications

### Step 7: Deploy Infrastructure

```bash
# Apply the configuration
terraform apply tfplan

# Or apply directly
terraform apply
```

**During deployment, you'll see:**
- Resources being created
- Progress updates
- Any errors or warnings

**Expected deployment time:**
- VPC and networking: 5-10 minutes
- EKS cluster: 15-20 minutes
- EFS file system: 5-10 minutes
- **Total: 25-40 minutes**

### Step 8: Verify Deployment

```bash
# Check Terraform state
terraform show

# List all outputs
terraform output

# Verify AWS resources
aws eks list-clusters
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=my-eks-project"
```

### Step 9: Configure kubectl

```bash
# Update kubeconfig for the cluster
aws eks update-kubeconfig \
  --region ap-south-1 \
  --name my-eks-project-dev-eks

# Verify cluster access
kubectl get nodes
kubectl get pods --all-namespaces
```

### Step 10: Test Infrastructure

```bash
# Test EKS cluster
kubectl run test-pod --image=nginx --restart=Never
kubectl get pods
kubectl delete pod test-pod

# Test EFS connectivity (if needed)
kubectl run test-efs --image=busybox --rm -it --restart=Never -- sh
```

## 🔧 Post-Deployment Configuration

### Configure EKS Add-ons

```bash
# Install AWS Load Balancer Controller
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"

# Install metrics server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### Configure Monitoring

```bash
# Install Prometheus and Grafana (optional)
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack
```

### Configure Backup

```bash
# Install Velero for backup (optional)
helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts
helm install velero vmware-tanzu/velero
```

## 🚨 Troubleshooting

### Common Issues

#### 1. Terraform State Issues
```bash
# If state is corrupted
terraform init -reconfigure

# If you need to import existing resources
terraform import aws_vpc.main vpc-12345678
```

#### 2. EKS Cluster Issues
```bash
# Check cluster status
aws eks describe-cluster --name my-eks-project-dev-eks

# Check node group status
aws eks describe-nodegroup --cluster-name my-eks-project-dev-eks --nodegroup-name general
```

#### 3. Network Issues
```bash
# Check VPC configuration
aws ec2 describe-vpcs --vpc-ids vpc-12345678

# Check security groups
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=vpc-12345678"
```

#### 4. IAM Issues
```bash
# Check IAM roles
aws iam get-role --role-name my-eks-project-dev-eks-cluster-role

# Check role policies
aws iam list-attached-role-policies --role-name my-eks-project-dev-eks-cluster-role
```

### Debug Commands

```bash
# Enable Terraform debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log

# Check AWS CLI debug
aws --debug sts get-caller-identity

# Check kubectl configuration
kubectl config view
kubectl config current-context
```

## 🔄 Updating Infrastructure

### Making Changes

```bash
# Edit configuration files
nano main.tf
nano variables.tf

# Plan changes
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan
```

### Scaling Operations

```bash
# Scale EKS node groups
terraform apply -var="eks_node_desired_size=5"

# Update EKS cluster version
terraform apply -var="eks_cluster_version=1.33"
```

## 🗑️ Cleanup

### Destroy Infrastructure

```bash
# Plan destruction
terraform plan -destroy

# Destroy infrastructure
terraform destroy

# Confirm destruction
yes | terraform destroy
```

**⚠️ Warning**: This will delete ALL resources including:
- EKS cluster and nodes
- EFS file system and data
- VPC and networking
- IAM roles and policies

### Manual Cleanup (if needed)

```bash
# Delete EKS cluster manually
aws eks delete-cluster --name my-eks-project-dev-eks

# Delete EFS file system
aws efs delete-file-system --file-system-id fs-12345678

# Delete VPC
aws ec2 delete-vpc --vpc-id vpc-12345678
```

## 📊 Monitoring Deployment

### CloudWatch Metrics

- **EKS**: Cluster health, node metrics
- **EC2**: Instance performance, network
- **EFS**: Throughput, IOPS, latency
- **VPC**: Flow log metrics

### Terraform Outputs

```bash
# Get cluster information
terraform output eks_cluster_endpoint

# Get security group IDs
terraform output security_groups

# Get network information
terraform output network_info
```

## 🔐 Security Verification

### Post-Deployment Security Checks

```bash
# Verify EKS cluster security
kubectl get nodes -o wide
kubectl get pods --all-namespaces

# Verify network security
aws ec2 describe-security-groups --group-ids sg-12345678

# Verify IAM roles
aws iam get-role --role-name my-eks-project-dev-eks-cluster-role
```

### Security Best Practices

1. **Review security groups** and restrict access
2. **Enable VPC Flow Logs** for monitoring
3. **Use private subnets** for EKS nodes
4. **Implement least privilege** IAM policies
5. **Enable encryption** for all storage
6. **Regular security audits** and updates

## 📚 Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/)
- [AWS Security Best Practices](https://aws.amazon.com/security/security-learning/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## 🆘 Getting Help

### Support Channels

1. **Documentation**: Check this guide and README.md
2. **Issues**: Create an issue in the repository
3. **AWS Support**: Contact AWS support if needed
4. **Community**: Use Terraform and Kubernetes communities

### Useful Commands

```bash
# Get help
terraform --help
aws help
kubectl --help

# Check versions
terraform version
aws --version
kubectl version --client
```

---

**Remember**: Always test in a non-production environment first and review all changes before applying to production!
