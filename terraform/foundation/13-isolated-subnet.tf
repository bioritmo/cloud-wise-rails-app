resource "aws_subnet" "isolated" {
  for_each = {
    for idx, az in data.aws_availability_zones.available.names : az => local.subnets_isolated[idx] if idx < length(local.subnets_isolated)
  }

  vpc_id = aws_vpc.main_vpc.id
  availability_zone = each.key
  cidr_block = each.value

  tags = {
    Name = "subnet-isolated-${each.key}"
  }
}

resource "aws_route_table" "rtb_isolated" {
  for_each = aws_subnet.isolated

  vpc_id = aws_vpc.main_vpc.id
}

resource "aws_route_table_association" "rta_isolated" {
  for_each = aws_subnet.isolated

  subnet_id = each.value.id
  route_table_id = aws_route_table.rtb_isolated[each.key].id
}