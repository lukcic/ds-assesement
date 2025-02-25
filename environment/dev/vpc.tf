module "aws-vpc" {
  source = "../../modules/aws-vpc"

  vpc_cidr     = "10.10.0.0/16"
  az_list      = var.az_list
  project_name = var.project_name
  project_env  = var.project_env
}
