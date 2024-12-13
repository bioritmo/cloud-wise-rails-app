terraform {
  required_providers {
    aws = "~> 5.77"
  }

  backend "s3" {
    # Utilizando Aws Cli profile
    # profile = ""

    # Utilizando Chaves de acesso
    # access_key = var.access_key
    # secret_key = var.secret_key

    region         = "us-east-1"
    bucket         = "grupo-5-terraform"
    key            = "grupo-5/foundation/terraform.tfstate"
    dynamodb_table = "terraform-locks"
  }
}

provider "aws" {
  # Utilizando Aws Cli profile
  # profile = ""

  # Utilizando Chaves de acesso
  # access_key = var.access_key
  # secret_key = var.secret_key
  region  = "us-east-1"

  default_tags {
    tags = {
      Project   = "Desafio Cloud Wise"
      Managed   = "Grupo 5"
      Owner     = "Grupo 5"
      terraform = "foundation"
    }
  }
}