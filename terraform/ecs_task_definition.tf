resource "aws_ecs_task_definition" "app" {
  family = "group01-app-hellorails-task"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = "256"
  memory = "512"

  container_definitions = jsonencode([
    {
      name = "group01-web"
      image = "${aws_ecr_repository.repository.name}"
      cpu = 256
      memory = 512
      essential = true
      portMappings = [{
        containerPort = 8000
        hostPort = 8000
      }]
      environment = [
        { "name": "DB_HOST", "value": "${aws_db_instance.postgres.endpoint}" }
      ]
    }
  ])
}
