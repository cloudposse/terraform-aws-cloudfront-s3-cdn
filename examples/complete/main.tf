provider "aws" {
  region = var.region
}

data "aws_iam_policy_document" "document" {
  statement {
    sid = "TemplateTest"

    actions = ["s3:GetObject"]
    resources = [
      "arn:aws:s3:::$${bucket_name}$${origin_path}testprefix/*"
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}


module "cloudfront_s3_cdn" {
  source               = "../../"
  context              = module.this.context
  parent_zone_name     = var.parent_zone_name
  dns_alias_enabled    = true
  origin_force_destroy = true
  cors_allowed_headers = ["*"]
  cors_allowed_methods = ["GET", "HEAD", "PUT"]
  cors_allowed_origins = ["*.cloudposse.com"]
  cors_expose_headers  = ["ETag"]

  additional_bucket_policy = data.aws_iam_policy_document.document.json
}

resource "aws_s3_bucket_object" "index" {
  bucket       = module.cloudfront_s3_cdn.s3_bucket
  key          = "index.html"
  source       = "${path.module}/index.html"
  content_type = "text/html"
  etag         = md5(file("${path.module}/index.html"))
  tags         = module.this.tags
}
