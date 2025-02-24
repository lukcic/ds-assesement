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
