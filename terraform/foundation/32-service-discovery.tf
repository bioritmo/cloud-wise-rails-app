resource "aws_service_discovery_private_dns_namespace" "web" {
  name = var.private_zone
  description = "Private DNS for ${var.private_zone}"
  vpc = aws_vpc.main_vpc.id
}

resource "aws_service_discovery_service" "web" {
  name = "web"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.web.id
    dns_records {
      type = "A"
      ttl = 60
    }
    routing_policy = "MULTIVALUE"
  }
}
