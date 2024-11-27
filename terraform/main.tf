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
# configure the aws provider
# -----------------------------------------------
# create a s3 bucket resource
# -----------------------------------------------
# create a dynamodb resource
# -----------------------------------------------
# create a vpc (eip, nat_gatway, internet_gatway)
# -----------------------------------------------
# create subnets
# -----------------------------------------------
# create route tables
# -----------------------------------------------

#################################################
# variables
#################################################
variable "region" {
  type        = string
  default     = "us-east-1"
}

variable "profile" {
  type        = string
  default     = "cloudwise"
}

variable "vpc_cidr_block" {
  type        = string
  default     = "10.0.0.0/16"
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
    profile = "cloudwise"
    region = "us-east-1"
    bucket = "group01-cloudwise-tfstate-workshop-terraform"
    key = "terraform.tfstate"
    dynamodb_table = "terraform-locks"
  }
}




#################################################
# configure the aws provider
#################################################

provider "aws" {
  profile = var.profile
  region = var.region

  default_tags {
    tags = {
      Project = "group01-workshop"
      Managed = "group01-terraform"
      Owner = "group01-cloud"
      terraform = "group01-maintf"
    }
  }
}






#################################################
# create a s3 bucket resource
#################################################

resource "aws_s3_bucket" "terraform_tfstate" {
  bucket = "group01-cloudwise-tfstate-workshop-terraform"

  tags = {
    Name = "group01-terraform-bucket"
  }
}

resource "aws_s3_bucket_ownership_controls" "s3_bucket_acl_ownership" {
  bucket = aws_s3_bucket.terraform_tfstate.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  depends_on = [ aws_s3_bucket_ownership_controls.s3_bucket_acl_ownership ]

  bucket = aws_s3_bucket.terraform_tfstate.id
  acl = "private"
}

resource "aws_s3_bucket_versioning" "s3_versioning" {
  bucket = aws_s3_bucket.terraform_tfstate.bucket

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_enc" {
  bucket = aws_s3_bucket.terraform_tfstate.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_tfstate" {
  bucket = aws_s3_bucket.terraform_tfstate.id

  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
}






#################################################
# create a dynamodb resource
#################################################

resource "aws_dynamodb_table" "terraform_locks" {
  name = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "group01-terraform-locks"
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

