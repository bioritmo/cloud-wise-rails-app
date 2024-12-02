variable "profile" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "access_key" {
  type = string
}

variable "secret_key" {
  type = string
}

variable "database_name" {
  type = string
}

variable "database_username" {
  type = string
}

variable "private_zone" {
  type = string
  default = "cloud-wise-rails-app.internal"

  validation {
    condition = strcontains(var.private_zone, ".internal")
    error_message = "Deve ser uma zona privada terminada com .interna"
  }
}