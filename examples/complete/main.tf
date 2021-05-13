provider "aws" {
  region = var.region
}

locals {
  enabled = module.this.enabled
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

data "aws_canonical_user_id" "current" {}

module "s3_bucket" {
  source  = "cloudposse/s3-bucket/aws"
  version = "0.36.0"

  acl                = null
  force_destroy      = true
  user_enabled       = false
  versioning_enabled = false
  attributes         = ["existing-bucket"]

  grants = [
    {
      id          = data.aws_canonical_user_id.current.id
      type        = "CanonicalUser"
      permissions = ["FULL_CONTROL"]
      uri         = null
    },
    {
      id          = null
      type        = "Group"
      permissions = ["READ_ACP", "WRITE"]
      uri         = "http://acs.amazonaws.com/groups/s3/LogDelivery"
    },
  ]

  context = module.this.context
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

  s3_access_logging_enabled = true
  s3_access_log_bucket_name = module.s3_bucket.bucket_id
  s3_access_log_prefix      = "logs/s3_access"

  cloudfront_access_logging_enabled = true
  cloudfront_access_log_prefix      = "logs/cf_access"

  additional_bucket_policy = data.aws_iam_policy_document.document.json
}

resource "aws_s3_bucket_object" "index" {
  count = module.this.enabled ? 1 : 0

  bucket       = module.cloudfront_s3_cdn.s3_bucket
  key          = "index.html"
  source       = "${path.module}/index.html"
  content_type = "text/html"
  etag         = md5(file("${path.module}/index.html"))
  tags         = module.this.tags
}
