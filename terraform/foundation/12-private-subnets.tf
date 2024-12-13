resource "aws_subnet" "private" {
  for_each = {
    for idx, az in data.aws_availability_zones.available.names : az => local.subnets_private[idx] if idx < length(local.subnets_private)
  }

  vpc_id = aws_vpc.main_vpc.id
  availability_zone = each.key
  cidr_block = each.value

  tags = {
    Name = "subnet-private-${each.key}"
  }
}

resource "aws_route_table" "rtb_private" {
  for_each = aws_subnet.private

  vpc_id = aws_vpc.main_vpc.id

  route { 
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ntg_public.id
  }
}

resource "aws_route_table_association" "rta_private" {
  for_each = aws_subnet.private

  subnet_id = each.value.id
  route_table_id = aws_route_table.rtb_private[each.key].id
}