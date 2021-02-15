terraform {

  required_version = ">= 0.14.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 3.20"
    }

  }

}

provider "aws" {
  region = var.aws_region
  shared_credentials_file = var.aws_credentials_file
  profile = var.aws_profile
}

