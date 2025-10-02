variable "project_name" {
  description = "The project name"
  type        = string
  default     = "imagix"
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
