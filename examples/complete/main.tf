provider "aws" {
  region = var.region
}

module "cloudfront_s3_cdn" {
  source                   = "../../"
  namespace                = var.namespace
  stage                    = var.stage
  name                     = var.name
  parent_zone_name         = var.parent_zone_name
  use_regional_s3_endpoint = true
  origin_force_destroy     = true
  cors_allowed_headers     = ["*"]
  cors_allowed_methods     = ["GET", "HEAD", "PUT"]
  cors_allowed_origins     = ["*.cloudposse.com"]
  cors_expose_headers      = ["ETag"]
}

resource "aws_s3_bucket_object" "index" {
  bucket       = module.cloudfront_s3_cdn.s3_bucket
  key          = "index.html"
  source       = "${path.module}/index.html"
  content_type = "text/html"
  etag         = md5(file("${path.module}/index.html"))
}
