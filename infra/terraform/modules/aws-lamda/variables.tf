variable "function_name" {
  type        = string
  description = "Lambda function name"
}

variable "handler" {
  type        = string
  description = "Lambda handler"
}

variable "runtime" {
  type        = string
  description = "Lambda runtime"
}

variable "source_path" {
  type        = string
  description = "Path to Lambda source code"
}

variable "environment" {
  type        = string
  description = "Environment tag"
}

variable "max_image_width" {
  type        = number
  description = "Max image width"
  default = 2000
}

variable "max_image_height" {
  type        = number
  description = "Max image height"
  default = 2000
}
