# Source
output "source_bucket_id" {
  value = module.source_bucket.s3_bucket_id
}

output "source_bucket_arn" {
  value = module.source_bucket.s3_bucket_arn
}

output "source_bucket_regional_domain_name" {
  value = module.source_bucket.s3_bucket_regional_domain_name
}

# Cache
output "cache_bucket_id" {
  value = module.cache_bucket.s3_bucket_id
}

output "cache_bucket_arn" {
  value = module.cache_bucket.s3_bucket_arn
}

output "cache_bucket_regional_domain_name" {
  value = module.cache_bucket.s3_bucket_regional_domain_name
}
