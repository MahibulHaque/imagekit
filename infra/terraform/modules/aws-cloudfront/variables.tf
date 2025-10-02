variable "environment" {
  type = string
}

variable "project_name" {
  type = string
  default="imagix"
}

variable "s3_origin_bucket_domain" {
  type = string
  description = "Regional domain name for the S3 bucket (e.g. mybucket.s3.amazonaws.com or bucket.s3.<region>.amazonaws.com)"
}

variable "tags" {
  type = map(string)
  default = {}
}
