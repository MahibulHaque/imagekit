resource "aws_lambda_function" "imagix" {
  function_name = "${var.project_name}-optimizer-${var.environment}"
  runtime       = var.runtime
  role          = aws_iam_role.lambda_exec.arn
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.lambda.repository_url}:${var.lambda_image_tag}"
  timeout       = 60
  memory_size   = 1536

  environment {
    variables = {
      SOURCE_BUCKET = aws_s3_bucket.source.id
      CACHE_BUCKET  = aws_s3_bucket.cache.id
      AWS_REGION    = var.aws_region
      MAX_WIDTH     = var.max_image_width
      MAX_HEIGHT    = var.max_image_height
      QUALITY       = var.default_quality
    }
  }

  tags = {
    Name        = "Imagix Lambda"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Lambda URL for direct invocation
resource "aws_lambda_function_url" "optimizer" {
  function_name      = aws_lambda_function.imagix.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = false
    allow_origins     = ["*"]
    allow_methods     = ["GET"]
    allow_headers     = ["*"]
    expose_headers    = ["*"]
    max_age           = 86400
  }
}
