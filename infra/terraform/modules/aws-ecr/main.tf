module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = var.ecr_module_version

  name = var.repository_name

  image_tag_mutability = "MUTABLE"
  scan_on_push         = true

  tags = merge(var.tags, {
    Environment = var.environment
  })
}
