terraform {
  required_version = "1.5.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.88.0"
    }
  }

  backend "s3" {
    bucket         = "lukcic-homelab-terraform-state"
    key            = "ds-elasticsearch-dev"
    region         = "eu-north-1"
    dynamodb_table = "lukcic-homelab-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Environment    = "${var.project_env}"
      CostAllocation = "${var.project_name}-${var.project_env}"
    }
  }
}
