provider "aws" {
  region = var.region
}

locals {
  enabled = module.this.enabled
}

data "aws_iam_policy_document" "document" {
  count = local.enabled ? 1 : 0

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

data "aws_canonical_user_id" "current" {
  count = local.enabled ? 1 : 0
}

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
      id          = local.enabled ? data.aws_canonical_user_id.current[0].id : ""
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
  source = "../../"

  parent_zone_name     = var.parent_zone_name
  dns_alias_enabled    = true
  origin_force_destroy = true
  cors_allowed_headers = ["*"]
  cors_allowed_methods = ["GET", "HEAD", "PUT"]
  cors_allowed_origins = ["*.cloudposse.com"]
  cors_expose_headers  = ["ETag"]

  deployment_principal_arns = local.deployment_principal_arns

  s3_access_logging_enabled = true
  s3_access_log_bucket_name = module.s3_bucket.bucket_id
  s3_access_log_prefix      = "logs/s3_access"

  cloudfront_access_logging_enabled = true
  cloudfront_access_log_prefix      = "logs/cf_access"

  additional_bucket_policy = local.enabled ? data.aws_iam_policy_document.document[0].json : ""

  context = module.this.context
}

resource "aws_s3_bucket_object" "index" {
  count = local.enabled ? 1 : 0

  bucket       = module.cloudfront_s3_cdn.s3_bucket
  key          = "index.html"
  source       = "${path.module}/index.html"
  content_type = "text/html"
  etag         = md5(file("${path.module}/index.html"))
  tags         = module.this.tags
}
