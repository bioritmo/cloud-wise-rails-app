data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ecr_image" "image" {
  depends_on = [ aws_ecr_repository.ecr ]

  repository_name = aws_ecr_repository.ecr.name
  most_recent = true
}

data "aws_ecs_task_definition" "web_app" {
  task_definition = aws_ecs_task_definition.web.family
}

data "aws_caller_identity" "current" {}