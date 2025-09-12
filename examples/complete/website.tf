module "website_default" {
  source = "../../"

  namespace = var.namespace
  stage     = var.stage
  name      = var.name

  // Distinguish this module instance from the one in main.tf and prevent S3 bucket name collisions
  attributes = concat(var.attributes, ["website"])

  cloudfront_access_logging_enabled = false

  website_enabled = true

  context = module.this.context
}

module "website_redirect_all" {
  source = "../../"

  namespace = var.namespace
  stage     = var.stage
  name      = var.name

  // Distinguish this module instance from the one in main.tf and prevent S3 bucket name collisions
  attributes = concat(var.attributes, ["website-redirect-all"])

  cloudfront_access_logging_enabled = false

  website_enabled          = true
  redirect_all_requests_to = "https://cloudposse.com"

  context = module.this.context
}
