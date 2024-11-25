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
  subnet_id = aws_subnet.subnet_public[0].id
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
  cidr_block = local.subnet_private_block[0]

  tags = {
    Name = "03-cfl-subnet-priv-${data.aws_availability_zones.available.names[0]}"
  }
}

## Subnet priv B
resource "aws_subnet" "subnet_private_b" {
  vpc_id = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[1]
  cidr_block = local.subnet_private_block[1]

  tags = {
    Name = "03-cfl-subnet-priv-${data.aws_availability_zones.available.names[1]}"
  }
}

## Route Table
### RT priv A
resource "aws_route_table" "rt_private_a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0"
    nat_gateway_id = aws_nat_gateway.ngw_public.id
  }
}

### RT priv B
resource "aws_route_table" "rt_private_b" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw_public.id
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
    nat_gateway_id = aws_internet_gateway.igw.id
  }
}

## Route Table Association
resource "aws_route_table_association" "rta_public" {
  for_each = aws_subnet.subnet_public

  subnet_id = each.value.id
  route_table_id = aws_route_table.rt_public[each.key].id
}

