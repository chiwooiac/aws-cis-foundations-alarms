variable "aws_credentials_file" {
  type        = string
  description = "describe a path to locate a credentials from access aws cli"
  default     = "$HOME/.aws/credentials"
}

variable "aws_profile" {
  type        = string
  description = "describe a specifc profile to access a aws cli"
  default     = "dxterra"
}


variable "project_name" {
  description = "project name is usally account's project name or platform name"
  type = string
  default = "dx-basic"
}

variable "aws_region" {
  type        = string
  description = "describe default region to create a resource from aws"
  default     = "ap-northeast-2"
}

variable "region_alias" {
  description = "region alias or AWS"
  type = string
  default = "an2"
}

variable "env_name" {
  description = "Runtime Environment such as develop, stage, production"
  type = string
  default = "production"
}

variable "env_alias" {
  description = "Runtime Environment such as develop, stage, production"
  type = string
  default = "p"
}

variable "owner" {
  description = "project owner"
  type = string
  default = "devdataopsx_bgk@bespinglobal.com"
}

variable "team_name" {
  description = "team name of DevOps"
  type = string
  default = "Devops Transformation"
}

variable "team_alias" {
  description = "team name of Devops Transformation"
  type = string
  default = "dx"
}

variable "cost_center" {
  description = "CostCenter"
  type = string
  default = "827519537363"
}


variable "max_access_key_age" {
  description = "Checks whether the active access keys are rotated within the number of days specified in maxAccessKeyAge. The rule is NON_COMPLIANT if the access keys have not been rotated for more than maxAccessKeyAge number of days."
  type = number
  default = 90
}


locals {
  category_name = "${var.team_alias}-${var.region_alias}"

  resource_prefix = "${var.project_name}-${var.region_alias}-${var.env_name}"

  extra_tags = {
    "Owner" = var.owner
    "Team" = var.team_alias
    "CostCenter" = var.cost_center
  }

  extra_asg_tags = [
    {
      key = "Env"
      value = var.env_name
      propagate_at_launch = true
    },
    {
      key = "Owner"
      value = var.owner
      propagate_at_launch = true
    },
    {
      key = "Proejct"
      value = var.project_name
      propagate_at_launch = true
    },
    {
      key = "Team"
      value = var.team_alias
      propagate_at_launch = true
    }
  ]

}