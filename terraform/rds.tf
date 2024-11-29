resource "aws_db_instance" "postgres" {
  db_subnet_group_name = aws_db_subnet_group.main.id
  allocated_storage = 10
  engine = "postgres"
  engine_version = "17.2"
  instance_class = "db.t3.micro"
  db_name = "group01db"
  username = "dbadmin"
  password = "password"
  publicly_accessible = false
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot = true
  multi_az = false
  storage_type = "gp2"

  tags = {
    name = "group01-db"
  }
}

resource "aws_db_subnet_group" "main" {
  name = "group01-db-subnetg"
  subnet_ids = [aws_subnet.subnet_private_a.id, aws_subnet.subnet_private_b.id]
}
