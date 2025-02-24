module "aws-vpc" {
  source = "../../aws-vpc"

  vpc_cidr = "10.10.0.0/16"

  project_name = var.project_name
  project_env  = var.project_env
}
