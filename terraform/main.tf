#################################################
# INDEX
#################################################
# setup
#################################################
# variables
# -----------------------------------------------
# locals
# -----------------------------------------------
# data
# -----------------------------------------------
# terraform backend s3 - save tfstate
# -----------------------------------------------
# create a vpc (eip, nat_gatway, internet_gatway)
# -----------------------------------------------
# create subnets
# -----------------------------------------------
# create route tables
# -----------------------------------------------
# create ecr
# -----------------------------------------------
# security groups ecs rds
# -----------------------------------------------
# alb app ecs
# -----------------------------------------------
# rds postgresql
# -----------------------------------------------
# ecs cluster
# -----------------------------------------------
# ecs task definition
# -----------------------------------------------

#################################################
# variables
#################################################

variable "vpc_cidr_block" {
  type        = string
  default     = "10.0.0.0/16"
}

variable "alb_health_check_path" {
  default = "/"
}

#################################################
# locals
#################################################
locals {
  subnet_private_block  = cidrsubnet(var.vpc_cidr_block, 2 , 0)
  subnet_public_block   = cidrsubnet(var.vpc_cidr_block, 2 , 1)

  subnets_private  =  cidrsubnets(local.subnet_private_block, 8, 8)
  subnets_public   =  cidrsubnets(local.subnet_public_block, 8, 8)
}

#################################################
# data
#################################################
data "aws_availability_zones" "available" {
  state = "available"
}

#################################################
# setup terraform
#################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  #------------------------------------------------
  # terraform backend s3 - save tfstate
  #------------------------------------------------
  backend "s3" {
    profile = "personal-account"
    region = "us-east-1"
    bucket = "group01-personal-account-tfstate-workshop-terraform"
    key = "terraform.tfstate"
    dynamodb_table = "terraform-locks"
  }
}

#################################################
# create a vpc
#################################################

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "group01-VPC-Main"
    Owner = "group01-network"
  }
}

resource "aws_eip" "eip_egress" {
  tags = {
    Name = "group01-EIP-NGW"
  }
}

resource "aws_nat_gateway" "ntg_public" {
  subnet_id = aws_subnet.subnet_public_a.id
  allocation_id = aws_eip.eip_egress.id

  tags = {
    Name = "group01-NATG-public"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "group01-IGW-VPC-Main"
  }
}

#################################################
# create subnets
#################################################

resource "aws_subnet" "subnet_private_a" {
  vpc_id = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[0] #us-east-1a
  cidr_block = local.subnets_private[0]
  tags = {
    Name = "group01-subnet-private-${data.aws_availability_zones.available.names[0]}"
  }
}

resource "aws_subnet" "subnet_private_b" {
  vpc_id = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[1] #us-east-1b
  cidr_block = local.subnets_private[1]
  tags = {
    Name = "group01-subnet-private-${data.aws_availability_zones.available.names[1]}"
  }
}

resource "aws_subnet" "subnet_public_a" {
  vpc_id = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[0] #us-east-1a
  cidr_block = local.subnets_public[0]
  tags = {
    Name = "group01-subnet-public-${data.aws_availability_zones.available.names[0]}"
  }
}

resource "aws_subnet" "subnet_public_b" {
  vpc_id = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[1] #us-east-1b
  cidr_block = local.subnets_public[1]
  tags = {
    Name = "group01-subnet-public-${data.aws_availability_zones.available.names[1]}"
  }
}

#################################################
# create route tables
#################################################

resource "aws_route_table" "rtb_private_a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ntg_public.id
  }
}
resource "aws_route_table" "rtb_private_b" {
  vpc_id = aws_vpc.main.id

  route {
     cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ntg_public.id
  }
}

resource "aws_route_table_association" "rta_private_a" {
  subnet_id = aws_subnet.subnet_private_a.id
  route_table_id = aws_route_table.rtb_private_a.id
}

resource "aws_route_table_association" "rta_private_b" {
  subnet_id = aws_subnet.subnet_private_b.id
  route_table_id = aws_route_table.rtb_private_b.id
}

resource "aws_route_table" "rtb_public_a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table" "rtb_public_b" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta_public_a" {
  subnet_id = aws_subnet.subnet_public_a.id
  route_table_id = aws_route_table.rtb_public_a.id
}

resource "aws_route_table_association" "rta_public_b" {
  subnet_id = aws_subnet.subnet_public_b.id
  route_table_id = aws_route_table.rtb_public_b.id
}

#################################################
# create ecr
#################################################
resource "aws_ecr_repository" "repository" {
  name = "grupo01/app"
  image_tag_mutability = "IMMUTABLE"
}

resource "aws_ecr_lifecycle_policy" "ecr_api_policy" {
  repository = aws_ecr_repository.repository.name

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

#################################################
# Security Groups
#################################################
resource "aws_security_group" "ecs" {
  name = "group01-ECS-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "HTTP permitted"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow all outbound traffic"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "group01-ECS-sg"
  }
}

resource "aws_security_group" "rds" {
  name = "group01-RDS-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "group01-RDS-sg"
  }
}

#################################################
# alb app ecs
#################################################

resource "aws_lb" "app" {
  name = "group01-app-hellorails-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.ecs.id]
  subnets = [aws_subnet.subnet_public_a.id, aws_subnet.subnet_public_b.id]

  tags = {
    Name = "group01-hellorails-alb"
  }
}

resource "aws_lb_target_group" "ecs" {
  name = "group01-app-hellorails-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id
  target_type = "ip"
  health_check {
    path = var.alb_health_check_path
    interval = 30
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.ecs.arn
  }
}

#################################################
# rds postgresql
#################################################
resource "aws_db_instance" "postgres" {
  db_subnet_group_name = aws_db_subnet_group.main.id
  allocated_storage = 10
  engine = "postgres"
  engine_version = "17.2"
  instance_class = "db.t3.micro"
  db_name = "group01db"
  username = "dbadmin"
  password = "password"
  publicly_accessible = false
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot = true
  multi_az = false
  storage_type = "gp2"

  tags = {
    name = "group01-db"
  }
}

resource "aws_db_subnet_group" "main" {
  name = "group01-db-subnetg"
  subnet_ids = [aws_subnet.subnet_private_a.id, aws_subnet.subnet_private_b.id]
}

#################################################
# ecs cluster
#################################################

resource "aws_ecs_cluster" "main" {
  name = "group01-hellorails-cluster"
}

#################################################
# ecs task definition
#################################################
resource "aws_ecs_task_definition" "app" {
  family = "group01-app-hellorails-task"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = "256"
  memory = "512"

  container_definitions = jsonencode([
    {
      name = "group01-web"
      image = "${aws_ecr_repository.repository.name}"
      cpu = 256
      memory = 512
      essential = true
      portMappings = [{
        containerPort = 8000
        hostPort = 8000
      }]
      environment = [
        { "name": "DB_HOST", "value": "${aws_db_instance.postgres.endpoint}" }
      ]
    }
  ])
}

#################################################
# ecs service
#################################################
resource "aws_ecs_service" "app" {
  depends_on = [ aws_lb_listener.http ]

  name = "group01-hellorails-service"
  cluster = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count = 1
  launch_type = "FARGATE"

  network_configuration {
    subnets = [aws_subnet.subnet_public_a.id, aws_subnet.subnet_public_b.id]
    assign_public_ip = true
    security_groups = [aws_security_group.ecs.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs.arn
    container_name = "group01-web"
    container_port = 8000
  }
}
