module "minimal" {
  source = "../../"

  namespace = var.namespace
  stage     = var.stage
  name      = var.name

  cloudfront_access_logging_enabled = false
}
