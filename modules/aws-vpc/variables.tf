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

variable "az_list" {
  type        = list(string)
  description = "List of Availability Zones to create subnets in."
}

variable "vpc_cidr" {
  type        = string
  description = "Main CIDR of VPC to create"
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 32))
    error_message = "Must be valid IPv4 CIDR."
  }
}

variable "public_subnet_cidr" {
  type        = string
  description = "CIDR of NAT gateway public subnet"
  validation {
    condition     = can(cidrhost(var.public_subnet_cidr, 32))
    error_message = "Must be valid IPv4 CIDR."
  }
}
