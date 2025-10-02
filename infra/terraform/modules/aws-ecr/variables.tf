variable "repository_name" {
  description = "ECR repository name"
  type        = string
  default     = "imagix"
}

variable "ecr_module_version" {
  description = "The version of the ECR module to use"
  type        = string
  default     = "3.1.0"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "dev"
}

variable "tags" {
  type = map(string)
  default = {}
}
