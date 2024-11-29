resource "aws_security_group" "ecs" {
  name = "group01-ECS-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "HTTP permitted"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow all outbound traffic"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "group01-ECS-sg"
  }
}

resource "aws_security_group" "rds" {
  name = "group01-RDS-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "group01-RDS-sg"
  }
}
