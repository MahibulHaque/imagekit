# Create Origin Access Control (OAC) to allow CloudFront to access S3 via SigV4
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.project_name}-${var.environment}-oac"
  description                       = "OAC to allow CloudFront to access S3 origins"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
  tags = var.tags
}

# Minimal CloudFront Function to remove querystring or rewrite, optional. (Example simple pass-through)
resource "aws_cloudfront_function" "noop" {
  name    = "${var.project_name}-${var.environment}-noop"
  runtime = "cloudfront-js-1.0"
  publish = true
  code    = <<EOF
function handler(event) {
    var request = event.request;
    var uri = request.uri;
    var querystring = request.querystring;
    
    // If no query parameters, return as-is
    if (Object.keys(querystring).length === 0) {
        return request;
    }
    
    // Build parameter string for S3 key
    var params = [];
    
    if (querystring.format && querystring.format.value) {
        params.push('format=' + querystring.format.value);
    } else {
        params.push('format=auto');
    }
    
    if (querystring.w && querystring.w.value) {
        params.push('width=' + querystring.w.value);
    }
    
    if (querystring.h && querystring.h.value) {
        params.push('height=' + querystring.h.value);
    }
    
    if (querystring.q && querystring.q.value) {
        params.push('quality=' + querystring.q.value);
    }
    
    // Rewrite URI: /image.jpg?w=200 -> /format=auto,width=200/image.jpg
    request.uri = '/' + params.join(',') + uri;
    
    // Remove query string as it's now in the path
    request.querystring = {};
    
    return request;
}
EOF
}

# CloudFront distribution pointing to S3 cache bucket with OAC
resource "aws_cloudfront_distribution" "cdn" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${var.project_name} CDN - ${var.environment}"
  default_root_object = "index.html"

 # S3 Cache Bucket Origin
  origin {
    domain_name              = aws_s3_bucket.cache.bucket_regional_domain_name
    origin_id                = "S3-Cache"
    origin_access_control_id = aws_cloudfront_origin_access_control.cache.id
  }

  # Lambda URL Origin (fallback for cache misses)
  origin {
    domain_name = replace(replace(aws_lambda_function_url.optimizer.function_url, "https://", ""), "/", "")
    origin_id   = "Lambda"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Origin Group (S3 with Lambda fallback)
  origin_group {
    origin_id = "S3-with-Lambda-fallback"

    failover_criteria {
      status_codes = [403, 404, 500, 502, 503, 504]
    }

    member {
      origin_id = "S3-Cache"
    }

    member {
      origin_id = "Lambda"
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-with-Lambda-fallback"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    # Apply URL rewrite function
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.url_rewrite.arn
    }

    forwarded_values {
      query_string = true
      headers      = ["Accept"]

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 86400      # 1 day
    max_ttl     = 31536000   # 1 year
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }


  tags = merge(var.tags, {
    Environment = var.environment
  })
}
