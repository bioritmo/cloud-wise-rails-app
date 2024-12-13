# AWS ECS Infrastructure

Infrastructure as Code project for AWS ECS deployment using Terraform.

## Project Structure

```
terraform/
├── ecs/
│   ├── policies/                                    # IAM policies directory
│   │   ├── ecs-execution-role-policy.json          # ECS execution role permissions
│   │   ├── ecs-task-execution-role.json            # Task execution role settings
│   │   └── ecs-task-role-policy.json               # Task role permissions
│   ├── task/                                       # Task definitions directory
│   │   └── example.json                            # Example task configuration
│   ├── 01-providers.tf                             # AWS provider configuration
│   ├── 10-vpc.tf                                   # VPC network setup
│   ├── 11-public-subnets.tf                        # Public subnet configuration
│   ├── 12-private-subnets.tf                       # Private subnet configuration
│   ├── 13-isolated-subnet.tf                       # Isolated subnet setup
│   ├── 14-security-group.tf                        # Security group definitions
│   ├── 15-cloudwatch.tf                            # CloudWatch logs configuration
│   ├── 20-rds.tf                                   # RDS database setup
│   ├── 30-ecr.tf                                   # ECR repository configuration
│   ├── 31-ecs.tf                                   # ECS cluster setup
│   ├── 32-service-discovery.tf                     # Service discovery configuration
│   ├── 33-ecs-web-task.tf                         # Web service task definition
│   ├── 34-ecs-web-service.tf                      # ECS service configuration
│   ├── 35-ecs-web-service-autoscaling.tf          # Service autoscaling rules
│   ├── 36-application-load-balancer.tf            # ALB setup and routing
│   ├── 88-ecs-secrets-manager.tf                  # ECS secrets configuration
│   ├── 89-rds-secrets-manager.tf                  # RDS secrets management
│   ├── 96-outputs.tf                              # Resource output values
│   ├── 97-locals.tf                               # Local variables definition
│   ├── 98-data.tf                                 # Data sources configuration
│   └── 99-variables.tf                            # Input variables declaration
```

## Prerequisites

- AWS CLI
- Terraform >= 1.0
- Docker

## Components

- VPC with multi-tier subnet architecture
- ECS cluster with autoscaling capabilities
- Application Load Balancer
- RDS database
- CloudWatch monitoring
- ECR repository
- Service discovery
- IAM roles and policies
- Secrets management

## Usage

```bash
terraform init
terraform plan
terraform apply
```
