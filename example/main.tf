resource "aws_route53_zone" "primary" {
  name          = "cloudposse.com"
  force_destroy = "true"
}

module "cdn" {
  source                   = "../"
  namespace                = "eg"
  stage                    = "prod"
  name                     = "app"
  aliases                  = ["assets.cloudposse.com"]
  parent_zone_id           = "${aws_route53_zone.primary.zone_id}"
  use_regional_s3_endpoint = "true"
  origin_force_destroy     = "true"
  cors_allowed_headers     = ["*"]
  cors_allowed_methods     = ["GET", "HEAD", "PUT"]
  cors_allowed_origins     = ["*.cloudposse.com"]
  cors_expose_headers      = ["ETag"]
}

resource "aws_s3_bucket_object" "index" {
  bucket       = "${module.cdn.s3_bucket}"
  key          = "index.html"
  source       = "${path.module}/index.html"
  content_type = "text/html"
  etag         = "${md5(file("${path.module}/index.html"))}"
}
