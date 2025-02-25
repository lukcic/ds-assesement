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

variable "aws_profile" {
  type        = string
  description = "AWS Profile name"
}

variable "aws_region" {
  type        = string
  description = "AWS Region name"
  default     = "eu-north-1"
}

variable "vpc_cidr" {
  type        = string
  description = "Main VPC CIDR"
  default     = "10.10.0.0/16"
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 32))
    error_message = "Must be valid IPv4 CIDR."
  }
}

variable "public_subnet_cidr" {
  type        = string
  description = "CIDR of NAT (public) subnet"
  default     = "10.10.200.0/24"
  validation {
    condition     = can(cidrhost(var.public_subnet_cidr, 32))
    error_message = "Must be valid IPv4 CIDR."
  }
}

variable "az_list" {
  type        = set(string)
  description = "List of Availability Zones to create subnets in."
  default     = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
}

variable "ssh_public_key" {
  type        = string
  description = "Value of the SSH public key."
}

variable "ami" {
  description = "AMI ID, if nor provided, latest Debian 12 image will be used."
  type = object({
    id = optional(string)
  })
  default = null
}

variable "master_ec2_config" {
  type = object({
    instance_type    = string
    root_volume_size = number
  })
  default = {
    instance_type    = "t3.large"
    root_volume_size = 30
  }
}

variable "node_ec2_config" {
  type = object({
    instance_type    = string
    root_volume_size = number
    min_size         = number
    max_size         = number
    desired_size     = number
  })
  default = {
    instance_type    = "t3.large"
    root_volume_size = 50
    min_size         = 2
    max_size         = 5
    desired_size     = 3
  }
}

variable "elasticsearch_config" {
  type = object({
    cluster_name    = string
    elastic_version = string
  })
}
