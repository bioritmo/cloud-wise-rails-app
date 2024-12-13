module "ecs_secrets_manager" {
  source = "terraform-aws-modules/secrets-manager/aws"

  # Secret
  name_prefix             = "rails-app-secret-key-base"
  description             = "Rails app Secret Key base"
  recovery_window_in_days = 30

  # Policy
  create_policy       = true
  block_public_policy = true
  policy_statements = {
    read = {
      sid = "AllowAccountRead"
      principals = [{
        type        = "AWS"
        identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
      }]
      actions   = ["secretsmanager:GetSecretValue"]
      resources = ["*"]
    }
  }

  # Version
  create_random_password           = true
  random_password_length           = 16
  random_password_override_special = "!@#$%^&*()_+"

  tags = {
    Environment = "Development"
  }
}