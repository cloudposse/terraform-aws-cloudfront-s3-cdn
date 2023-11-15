provider "aws" {
  region = var.region
}

locals {
  enabled                  = module.this.enabled
  additional_origin_groups = concat(local.additional_custom_origin_groups, local.additional_s3_origin_groups)
  lambda_at_edge_enabled   = local.enabled && var.lambda_at_edge_enabled
}

data "aws_partition" "current" {
  count = local.enabled ? 1 : 0
}

data "aws_iam_policy_document" "document" {
  count = local.enabled ? 1 : 0

  statement {
    sid = "TemplateTest"

    actions = ["s3:GetObject"]
    resources = [
      "arn:${join("", data.aws_partition.current[*].partition)}:s3:::$${bucket_name}$${origin_path}testprefix/*"
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
  version = "3.1.2"

  force_destroy       = true
  user_enabled        = false
  versioning_enabled  = false
  block_public_policy = false
  attributes          = ["existing-bucket"]

  acl                 = null
  s3_object_ownership = "BucketOwnerPreferred"
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

# Workaround for S3 eventual consistency for settings relating to objects
resource "time_sleep" "wait_for_aws_s3_bucket_settings" {
  count = local.enabled ? 1 : 0

  create_duration  = "30s"
  destroy_duration = "30s"

  depends_on = [
    data.aws_iam_policy_document.document,
    module.s3_bucket
  ]
}

module "cloudfront_s3_cdn" {
  source = "../../"

  depends_on = [
    time_sleep.wait_for_aws_s3_bucket_settings,
    time_sleep.wait_for_additional_s3_origins
  ]

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
  s3_object_ownership               = "BucketOwnerPreferred"

  additional_bucket_policy = local.enabled ? data.aws_iam_policy_document.document[0].json : ""

  custom_origins = var.additional_custom_origins_enabled ? [local.additional_custom_origin_primary, local.additional_custom_origin_secondary] : []
  s3_origins = concat([{
    domain_name = module.s3_bucket.bucket_regional_domain_name
    origin_id   = module.s3_bucket.bucket_id
    origin_path = null
    s3_origin_config = {
      origin_access_identity = null # will get translated to the origin_access_identity used by the origin created by this module.
    }
  }], var.additional_s3_origins_enabled ? [local.additional_s3_origin_primary, local.additional_s3_origin_secondary] : [])
  origin_groups = concat([{
    primary_origin_id  = null # will get translated to the origin id of the origin created by this module.
    failover_origin_id = module.s3_bucket.bucket_id
    failover_criteria  = var.origin_group_failover_criteria_status_codes
  }], local.additional_origin_groups)

  lambda_function_association = local.lambda_at_edge_enabled ? module.lambda_at_edge.lambda_function_association : []
  forward_header_values       = local.lambda_at_edge_enabled ? ["useless-header"] : []

  context = module.this.context
}

resource "aws_s3_object" "index" {
  count = local.enabled ? 1 : 0

  bucket       = module.cloudfront_s3_cdn.s3_bucket
  key          = "index.html"
  source       = "${path.module}/index.html"
  content_type = "text/html"
  etag         = md5(file("${path.module}/index.html"))
  tags         = module.this.tags
}
