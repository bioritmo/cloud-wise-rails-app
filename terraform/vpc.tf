resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
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
