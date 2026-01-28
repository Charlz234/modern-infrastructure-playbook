variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Execution environment (dev/staging/prod)"
  type        = string
  default     = "management"
}
