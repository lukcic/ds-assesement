variable "project_name" {
  type        = string
  description = "Project name"
}

variable "project_env" {
  type        = string
  description = "Project environment"

  validation {
    condition     = can(regex("^(dev|stg|prod)$", var.project_env))
    error_message = "Must be: dev/stg/prod"
  }
}

variable "vpc_cidr" {
  type        = string
  description = "Main CIDR of VPC to create"
}

variable "az_list" {
  type        = list(string)
  description = "List of Availability Zones to create subnets in."
}
