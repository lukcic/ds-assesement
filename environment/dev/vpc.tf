module "aws-vpc" {
  source = "../../modules/aws-vpc"

  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  az_list            = var.az_list
  project_name       = var.project_name
  project_env        = var.project_env
}
