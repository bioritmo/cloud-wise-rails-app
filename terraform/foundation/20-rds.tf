resource "aws_db_instance" "default" {
  depends_on = [ aws_db_subnet_group.db_subnet_group ]

  allocated_storage = 20
  engine = "postgres"
  db_name = var.database_name
  username = var.database_username
  password = module.secrets_manager.secret_string
  engine_version = "17.2"
  instance_class = "db.t3.micro"
  availability_zone = data.aws_availability_zones.available.names[0]
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.rds_security_group.id]
  publicly_accessible = false
  
  tags = {
    Name = "Cloud Wise App Database"
  }
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db_subnet_group"
  subnet_ids = [aws_subnet.isolated[keys(aws_subnet.isolated)[0]].id, aws_subnet.isolated[keys(aws_subnet.isolated)[1]].id]

  tags = {
    Name = "DB subnet group"
  }
}

resource "aws_security_group" "rds_security_group" {
  name = "rds_security_group"
  description = "Blocks all connections"
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "rds_security_group"
  }
}

resource "aws_vpc_security_group_egress_rule" "rds_allow_all_outbound_traffic" {
  security_group_id = aws_security_group.rds_security_group.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "rds_inbound_private_traffic" {
  for_each = aws_subnet.private

  security_group_id = aws_security_group.rds_security_group.id
  cidr_ipv4 = each.value.cidr_block
  from_port = 5432
  to_port = 5432
  ip_protocol = "tcp"
}