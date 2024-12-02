resource "aws_ecs_service" "web" {
  cluster = aws_ecs_cluster.cluster.id
  name = "web"
  task_definition = "${aws_ecs_task_definition.web.family}:${max("${aws_ecs_task_definition.web.revision}", "${data.aws_ecs_task_definition.web_app.revision}")}"
  desired_count = 2
  launch_type = "FARGATE"

  enable_execute_command =  true

  network_configuration {
    security_groups = [aws_security_group.ecs_web.id]
    subnets = [
      aws_subnet.private[keys(aws_subnet.private)[0]].id,
      aws_subnet.private[keys(aws_subnet.private)[1]].id,
    ]
  }

  lifecycle {
    ignore_changes = [ desired_count ]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.web.arn
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name = "cloud-wise-rails-app"
    container_port = 3000
  }
}