locals {
  subnet_private_block  = cidrsubnet(var.vpc_cidr_block, 2, 0)
  subnet_public_block   = cidrsubnet(var.vpc_cidr_block, 2, 1)
  subnet_isolated_block = cidrsubnet(var.vpc_cidr_block, 2, 2)

  subnets_private  = cidrsubnets(local.subnet_private_block, 8, 8)
  subnets_public   = cidrsubnets(local.subnet_public_block, 8, 8)
  subnets_isolated = cidrsubnets(local.subnet_isolated_block, 8, 8)
}