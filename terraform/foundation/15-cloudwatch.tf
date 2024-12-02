resource "aws_cloudwatch_log_group" "log" {
  name              = "/ecs/development/cloud-wise-rails-app"
  retention_in_days = 3
}