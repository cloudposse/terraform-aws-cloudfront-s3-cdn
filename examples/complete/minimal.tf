module "minimal" {
  source = "../../"

  namespace = var.namespace
  stage     = var.stage
  name      = var.name

  // This is required to distinguish this module instance from the one in main.tf and to prevent S3 bucket name collisions
  attributes = concat(var.attributes, ["minimal"])

  cloudfront_access_logging_enabled = false

  context = module.this.context
}
