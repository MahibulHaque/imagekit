output "distribution_id" {
  value = aws_cloudfront_distribution.cdn.id
}

output "domain_name" {
  value = aws_cloudfront_distribution.cdn.domain_name
}

output "origin_access_control_id" {
  value = aws_cloudfront_origin_access_control.oac.id
}
