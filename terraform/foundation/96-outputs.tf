output "database_address" {
  description = "Database address"
  value       = aws_db_instance.default.address
}

output "database_port" {
  description = "Database port"
  value       = aws_db_instance.default.port
}

output "load_balancer" {
  description = "load balancer info"
  value = aws_alb.application_load_balancer.dns_name
}