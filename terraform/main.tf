terraform {
  required_providers {
    aws = "~> 5.76.0"
  }
}

provider "aws" {
  profile = "sandbox"
  region = "us-east-1"

  default_tags {
    tags = {
      Project = "03-cfl-cloudwise"
      Managed = "terraform"
      Owner = "cloud"
      terraform = "bootstrap"
    }
  }
}


# Data
data "aws_availability_zones" "available" {
  state = "available"
}


# Locals
locals {
  subnet_private_block = cidrsubnet(var.vpc_cidr_block, 2, 0)
  subnet_public_block = cidrsubnet(var.vpc_cidr_block, 2, 1)

  subnets_private = cidrsubnets(local.subnet_private_block, 8, 8)
  subnets_public = cidrsubnets(local.subnet_public_block, 8, 8)
}

# locals {
#   # Blocos CIDR para subnets privadas e públicas
#   private_subnets = cidrsubnets(var.vpc_cidr_block, 24, 0, 1) # Dividido em dois blocos para subnets privadas 10.0.0.0/24 10.0.1.0/24
#   public_subnets  = cidrsubnets(var.vpc_cidr_block, 4, 2, 3)  # Dividido em dois blocos para subnets públicas 10.0.2.0/24 10.0.3.0/24
# }


# Vars
variable "region" {
  type = string
  default = "us-east-1"
}

variable "profile" {
  type = string
  default = "sandbox"
}

variable "vpc_cidr_block" {
  type = string
}


# VPC
resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"

  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "03-cfl-vpc-cloudwise"
  }
}


# Elastic IP
resource "aws_eip" "eip_egress" {
  tags = {
    Name = "03-cfl-EIP-NGW"
  }
}


# NAT Gateway
resource "aws_nat_gateway" "ngw_public" {
  subnet_id = values(aws_subnet.subnet_public)[0].id
  allocation_id = aws_eip.eip_egress.id

  tags = {
    Name = "03-cfl-NATGW-public"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "03-cfl-IGW-VPC-Main"
  }
}


# Subnet
## Subnet priv A
resource "aws_subnet" "subnet_private_a" {
  vpc_id = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block = local.subnets_private[0]

  tags = {
    Name = "03-cfl-subnet-priv-${data.aws_availability_zones.available.names[0]}"
  }
}

## Subnet priv B
resource "aws_subnet" "subnet_private_b" {
  vpc_id = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[1]
  cidr_block = local.subnets_private[1]

  tags = {
    Name = "03-cfl-subnet-priv-${data.aws_availability_zones.available.names[1]}"
  }
}

## Route Table
### RT priv A
resource "aws_route_table" "rt_private_a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw_public.id
  }

  tags = {
    Name = "03-cfl-rt-priv-${data.aws_availability_zones.available.names[0]}"
  }
}

### RT priv B
resource "aws_route_table" "rt_private_b" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw_public.id
  }

  tags = {
    Name = "03-cfl-rt-priv-${data.aws_availability_zones.available.names[1]}"
  }
}

## Route Table Association
### RTA private A
resource "aws_route_table_association" "rta_private_a" {
  subnet_id = aws_subnet.subnet_private_a.id
  route_table_id = aws_route_table.rt_private_a.id
}

### RTA private B
resource "aws_route_table_association" "rta_private_b" {
  subnet_id = aws_subnet.subnet_private_b.id
  route_table_id = aws_route_table.rt_private_b.id
}


## Subnet public with for
resource "aws_subnet" "subnet_public" {
  for_each = {
    for idx, az in data.aws_availability_zones.available.names : az => local.subnets_public[idx] if idx < length(local.subnets_public)
  }

  vpc_id = aws_vpc.main.id
  availability_zone = each.key
  cidr_block = each.value

  tags = {
    Name = "03-cfl-subnet-pub-${each.key}"
  }
}

## Route Table
resource "aws_route_table" "rt_public" {
  for_each = aws_subnet.subnet_public

  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "03-cfl-rt-public-${each.key}"
  }
}

## Route Table Association
resource "aws_route_table_association" "rta_public" {
  for_each = aws_subnet.subnet_public

  subnet_id = each.value.id
  route_table_id = aws_route_table.rt_public[each.key].id
}

# Security Group
resource "aws_security_group" "sec_group" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic from anywhere"
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS traffic from anywhere"
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1" # Permitir todo o tráfego de saída
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "03-cfl-sec-group"
  }
}


# RDS Postgresql
variable "db_name" {
  type = string
  default = "db03cfl"
}

variable "db_username" {
  type = string
  default = "group03cfl"
}

variable "db_password" {
  type = string
  default = "password"
}

resource "aws_db_instance" "rds_postgres" {
  engine = "postgres"
  engine_version = "17.1"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  max_allocated_storage = 50
  storage_type = "gp3"

  db_name = var.db_name
  username = var.db_username
  password = var.db_password

  publicly_accessible = false

  storage_encrypted = true
  backup_retention_period = 7
  delete_automated_backups = true

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name

  final_snapshot_identifier = "final-snapshot-${var.db_name}"

  tags = {
    Name = "03-cfl-rds-postgres"
  }
}

## Subnet Group RDS
resource "aws_db_subnet_group" "rds_subnet_group" {
  subnet_ids = [
    aws_subnet.subnet_private_a.id,
    aws_subnet.subnet_private_b.id
  ]

  tags = {
    Name = "03-cfl-rds-subnet-Group"
  }
}

## Security Group RDS
resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    security_groups = [aws_security_group.sec_group.id]
    description = "Allow PostgreSQL traffic from sec group ECS"
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "03-cfl-sec-group-rds"
  }
}


# Load Balancer
resource "aws_lb" "main_lb" {
  name = "03-cfl-main-lb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.sec_group.id]
  subnets = [values(aws_subnet.subnet_public)[0].id, values(aws_subnet.subnet_public)[1].id]

  tags = {
    Name = "03-cfl-lb"
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.main_lb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port = "443"
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.main_lb.arn
  port = 443
  protocol = "HTTPS"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.main_tg.arn
  }
}

# Target Group
resource "aws_lb_target_group" "main_tg" {
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id

  health_check {
    path = "/"
    interval = 30
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 2
    matcher = "200"
  }

  tags = {
    Name = "03-cfl-target-group"
  }
}


# ECR
resource "aws_ecr_repository" "ecr" {
  name = "03-cfl-rails-app"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "ecr_lifecycle_policy" {
  repository = aws_ecr_repository.ecr.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last 10 images",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": 10
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}


# ECS
# resource "aws_ecs_cluster" "my_cluster" {
#   name = "My Cluster"
# }

# ## Tasks
# data "template_file" "task_definition" {
#   template = file("${path.module}/task_definition.json")

#   vars = {
#     image_name = "my-image-name"
#     port       = "80"
#   }
# }

# resource "aws_ecs_task_definition" "task_definition" {
#   family                   = "my-task-definition"
#   container_definitions    = data.template_file.task_definition.rendered
#   requires_compatibilities = ["FARGATE"]
# }
