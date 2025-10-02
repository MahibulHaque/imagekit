variable "environment" {
  type = string
}

variable "project_name" {
  type = string
  default="imagix"
}

variable "s3_origin_bucket_arn" {
  type = string
  description = "ARN of the S3 bucket used as CloudFront origin"
}

variable "s3_origin_bucket_domain" {
  type = string
  description = "Regional domain name for the S3 bucket (e.g. mybucket.s3.amazonaws.com or bucket.s3.<region>.amazonaws.com)"
}

variable "s3_origin_bucket_regional_domain_name" {
  type = string
  description = "Bucket regional domain name (optional). Module uses s3_origin_bucket_domain primarily."
  default = ""
}

variable "enable_lambda_origin" {
  type = bool
  default = false
  description = "If true, cloudfront will create additional origin for lambda URL (not wired by default)"
}

variable "tags" {
  type = map(string)
  default = {}
}
