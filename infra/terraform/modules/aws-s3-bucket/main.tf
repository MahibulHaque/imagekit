# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE SOURCE AND CACHE S3 BUCKETS
# ---------------------------------------------------------------------------------------------------------------------

module "source_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = var.s3_module_version

  bucket = var.source_bucket_prefix != "" ? "${var.source_bucket_prefix}-${var.source_bucket_name}" : var.source_bucket_name

  # enable versioning for source bucket
  versioning = {
    enabled = var.versioning_enabled
  }
  force_destroy = var.force_destroy

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Type        = "source"
    }
  )
}

# Cache bucket (optimized images)
module "cache_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = var.s3_module_version

  bucket = var.cache_bucket_prefix != "" ? "${var.cache_bucket_prefix}-${var.cache_bucket_name}" : var.cache_bucket_name

  versioning = {
    enabled = var.versioning_enabled
  }

  lifecycle_rule = [
    {
      id      = "expire-old-cached-images"
      enabled = true
      expiration = {
        days = var.cache_expiration_days
      }
    }
  ]

  force_destroy = false

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Type        = "cache"
    }
  )
}
