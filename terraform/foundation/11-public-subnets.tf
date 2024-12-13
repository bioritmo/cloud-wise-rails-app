resource "aws_subnet" "public" {
  for_each = {
    for idx, az in data.aws_availability_zones.available.names : az => local.subnets_public[idx] if idx < length(local.subnets_public)
  }

  vpc_id = aws_vpc.main_vpc.id
  availability_zone =  each.key
  cidr_block = each.value

  tags = {
    Name = "subnet-public-${each.key}"
  }
}

resource "aws_route_table" "rtb_public" {
  for_each = aws_subnet.public

  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta_public" {
  for_each = aws_subnet.public

  subnet_id = each.value.id
  route_table_id = aws_route_table.rtb_public[each.key].id
}