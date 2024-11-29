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
