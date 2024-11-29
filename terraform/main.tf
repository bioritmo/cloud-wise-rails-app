terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region  = "us-east-1"
  profile = "desafio"
}

### General Variables ###
variable "region" {
  type = string

  default = "us-east-1"
}


variable "profile" {
  type = string

  default = "desafio"
}

variable "vpc_cidr_block" {
  type = string
}

#### End Variables ###


### General Locals ###
locals {
  subnet_private_block = cidrsubnet(var.vpc_cidr_block, 2, 0)            # "172.20.0.0/26"
  subnet_public_block  = cidrsubnet(var.vpc_cidr_block, 2, 1)            # "172.20.0.64/26"
  subnets_private      = cidrsubnets(local.subnet_private_block, 8, 8)   # tolist(["172.20.0.0/31", "172.20.0.8/29" ])
  subnets_public       = cidrsubnets(local.subnet_public_block, 8, 8)    # tolist(["172.20.0.64/31", "172.20.0.72/29" ])
}


#### End Locals ###

# Data
data "aws_availability_zones" "available" {
  state = "available"
}


# VPC
resource "aws_vpc" "group04_vpc" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"

  tags = {
    Name = "group_04"
    cidr_block = "172.20.0.0/16"
  }
}


# Elastic IP
resource "aws_eip" "group04_eip_egress" {
  tags = {
    Name = "group04_eip_egress"
  }
}

## Subnet

# Subnet priv A
resource "aws_subnet" "subnet_private_a" {
  vpc_id = aws_vpc.group04_vpc.id
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block = local.subnets_private[0]

  tags = {
    Name = "group04-cfl-subnet-priv-${data.aws_availability_zones.available.names[0]}"
  }
}

# Subnet priv B
resource "aws_subnet" "subnet_private_b" {
  vpc_id = aws_vpc.group04_vpc.id
  availability_zone = data.aws_availability_zones.available.names[1]
  cidr_block = local.subnets_private[1]

  tags = {
    Name = "group04-cfl-subnet-priv-${data.aws_availability_zones.available.names[1]}"
  }
}


## Subnet public with for
resource "aws_subnet" "group04_subnet_public" {
  for_each = {
    for idx, az in data.aws_availability_zones.available.names : az => local.subnets_public[idx] if idx < length(local.subnets_public)
  }

  vpc_id = aws_vpc.group04_vpc.id
  availability_zone = each.key
  cidr_block = each.value

  tags = {
    Name = "group04-cfl-subnet-pub-${each.key}"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "group04_ngw_public" {
  subnet_id = aws_subnet.group04_subnet_public["us-east-1a"].id
  allocation_id = aws_eip.group04_eip_egress.id

  tags = {
    Name = "group04_ngw_public"
  }
}

# TODO: Internet Gateway
resource "aws_internet_gateway" "group04_gw" {
  vpc_id = aws_vpc.group04_vpc.id

  tags = {
    Name = "group04_gw"
  }
}

resource "aws_route_table" "group04_rt_private" {
  vpc_id = aws_vpc.group04_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.group04_ngw_public.id
  }

  tags = {
    Name = "group04_rt_private"
  }
}

resource "aws_route_table" "group04_rt_public" {
  vpc_id = aws_vpc.group04_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.group04_gw.id
  }

  tags = {
    Name = "group04_rt_public"
  }
}

# Route Table Association
resource "aws_route_table_association" "group_04_public" {
  for_each = aws_subnet.group04_subnet_public
  subnet_id = aws_subnet.group04_subnet_public[each.key].id

  route_table_id = aws_route_table.group04_rt_public.id
}

resource "aws_route_table_association" "group_04_private_a" {
  subnet_id = aws_subnet.subnet_private_a.id

  route_table_id = aws_route_table.group04_rt_private.id
}

resource "aws_route_table_association" "group_04_private_b" {
  subnet_id = aws_subnet.subnet_private_b.id

  route_table_id = aws_route_table.group04_rt_private.id
}