variable "vpc_cidr_block" {
  type        = string
  default     = "10.0.0.0/16"
}

locals {
  subnet_private_block  = cidrsubnet(var.vpc_cidr_block, 2 , 0)
  subnet_public_block   = cidrsubnet(var.vpc_cidr_block, 2 , 1)

  subnets_private  =  cidrsubnets(local.subnet_private_block, 8, 8)
  subnets_public   =  cidrsubnets(local.subnet_public_block, 8, 8)
}

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
