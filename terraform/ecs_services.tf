resource "aws_ecs_service" "app" {
  depends_on = [ aws_lb_listener.http ]

  name = "group01-hellorails-service"
  cluster = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count = 1
  launch_type = "FARGATE"

  network_configuration {
    subnets = [aws_subnet.subnet_public_a.id, aws_subnet.subnet_public_b.id]
    assign_public_ip = true
    security_groups = [aws_security_group.ecs.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs.arn
    container_name = "group01-web"
    container_port = 8000
  }
}
