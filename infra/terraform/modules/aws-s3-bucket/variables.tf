variable "project_name" {
  type = string
  default = "imagix"
}

variable "environment" {
  type = string
  default = "dev"
}

variable "s3_module_version" {
  type        = string
  description = "The version of the S3 module to use."
  default     = "5.7.0"
}

variable "versioning_enabled"{
  type=bool
  default=true
}

variable "source_bucket_name" {
  type = string
  description = "Source S3 bucket name"
  default="source"
}

variable "cache_bucket_name" {
  type = string
  description = "Cache S3 bucket name"
  default="cache"
}

variable "source_bucket_prefix" {
  type        = string
  description = "The prefix for the bucket name."
  default     = ""
}

variable "cache_bucket_prefix" {
  type        = string
  description = "The prefix for the bucket name."
  default     = ""
}

variable "force_destroy" {
  type        = bool
  description = "Whether to destroy all objects from the bucket so that the bucket can be destroyed without error."
  default     = true
}

variable "cache_expiration_days" {
  type = number
  default = 30
}

variable "tags" {
  type = map(string)
  default = {}
}
