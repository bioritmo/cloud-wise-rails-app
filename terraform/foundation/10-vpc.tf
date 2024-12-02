resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr_block

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "Grupo-5-VPC"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "IGW-VPC-Main"
  }
}

resource "aws_eip" "eip_egress" {
  tags = {
    Name = "EIP-NGW"
  }
}

resource "aws_nat_gateway" "ntg_public" {
  subnet_id     = aws_subnet.public[keys(aws_subnet.public)[0]].id
  allocation_id = aws_eip.eip_egress.id

  tags = {
    Name = "NATGW-public"
  }
}