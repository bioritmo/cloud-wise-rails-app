resource "aws_ecs_cluster" "cluster" {
  name = "cloud-wise-rails-app"
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role"
  assume_role_policy = file("ecs/policies/ecs-task-execution-role.json")
}

resource "aws_iam_role_policy" "ecs_execution_role_policy" {
  name = "ecs_execution_role_policy_dev"
  role = aws_iam_role.ecs_execution_role.id
  policy = file("ecs/policies/ecs-execution-role-policy.json")
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ecs_task_role"
  assume_role_policy = file("ecs/policies/ecs-task-execution-role.json")
}

resource "aws_iam_role_policy" "ecs_task_role_policy" {
  name = "ecs_tasks_role_policy_dev"
  role = aws_iam_role.ecs_task_role.id

  policy = file("ecs/policies/ecs-task-role-policy.json")
}