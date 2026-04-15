variable "environment" {
  description = "Deployment environment (dev or prod)"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be dev or prod."
  }
}

variable "domain_name" {
  description = "Full domain name for this environment (e.g. dev.haiau68.com)"
  type        = string
}

variable "aws_region" {
  description = "Primary AWS region for resources"
  type        = string
  default     = "ap-southeast-1"
}