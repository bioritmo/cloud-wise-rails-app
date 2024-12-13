resource "aws_security_group" "allow_http" {
  name = "allow_http_traffic"
  description = "Allow HTTP inbound traffic and all outbound traffic"
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "allow_http"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_443_ipv4" {
  security_group_id = aws_security_group.allow_http.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 443
  to_port = 443
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_80_ipv4" {
  security_group_id = aws_security_group.allow_http.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 80
  to_port = 80
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_http.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"
}