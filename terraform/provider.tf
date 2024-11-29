provider "aws" {
  profile = "personal-account"
  region  = "us-east-1"

  default_tags {
    tags = {
      Project = "group01-workshop"
      Managed = "group01-terraform"
      Owner = "group01-cloud"
      terraform = "group01-maintf"
    }
  }
}
