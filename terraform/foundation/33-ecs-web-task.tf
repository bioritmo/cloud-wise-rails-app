resource "aws_ecs_task_definition" "web" {
  family = "web"
  container_definitions = templatefile(
    "ecs/task/example.json",
    {
      name = "cloud-wise-rails-app",
      image = "${aws_ecr_repository.ecr.repository_url}:${coalesce(data.aws_ecr_image.image.image_tags[0], "latest")}"
      # image = ""
      region = var.region
      command = ["rails", "s", "-b", "0.0.0.0"]

      log_group = aws_cloudwatch_log_group.log.name
      env_variables = [
        {
          "name": "POSTGRES_PORT",
          "value": "5432"
        },
        {
          "name": "POSTGRES_DB",
          "value": var.database_name
        },
        {
          "name": "POSTGRES_HOST",
          "value": aws_db_instance.default.address
        },
        {
          "name": "POSTGRES_USER",
          "value": var.database_username
        },
        {
          "name": "RAILS_SERVE_STATIC_FILES",
          "value": "true"
        },
        {
          "name": "RAILS_LOAD_BALANCER_HOST",
          "value": aws_alb.application_load_balancer.dns_name
        },
        {
          "name": "RAILS_IP_MASK_HOSTS",
          "value": var.vpc_cidr_block
        }
      ]

      secrets_variables = [
        {
          "name": "POSTGRES_PASSWORD",
          "valueFrom": module.secrets_manager.secret_arn
        },
        {
          "name": "SECRET_KEY_BASE",
          "valueFrom": module.ecs_secrets_manager.secret_arn
        }
      ]
    }
  )

  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"

  cpu = "256"
  memory = "512"

  execution_role_arn = aws_iam_role.ecs_execution_role.arn

  task_role_arn = aws_iam_role.ecs_task_role.arn
}

resource "aws_security_group" "ecs_web" {
  vpc_id = aws_vpc.main_vpc.id
  name = "sg_ecs_web"
  description = "Allow traffic for the web container"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port = 0
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 3000
    to_port = 3000
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_ecs_web"
  }
}