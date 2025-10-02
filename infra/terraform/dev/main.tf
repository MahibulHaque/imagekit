module "s3" {
  source               = "../modules/aws-s3-bucket"
  cache_expiration_days = 30
}

module "ecr" {
  source          = "../modules/aws-ecr"
}

module "lambda" {
  source = "../modules/aws-lamda"
}

module "cloudfront" {
  source = "../modules/aws-cloudfront"
}

module oidc{
  source = "../modules/aws-oidc-role"
}
