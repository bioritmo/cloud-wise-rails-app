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
