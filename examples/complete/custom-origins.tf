locals {
  additional_custom_origins_enabled = local.enabled && var.additional_custom_origins_enabled
  default_custom_origin_configuration = {
    domain_name    = null
    origin_id      = null
    origin_path    = null
    custom_headers = []
    custom_origin_config = {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "https-only"
      origin_ssl_protocols     = ["TLSv1", "TLSv1.1", "TLSv1.2"]
      origin_keepalive_timeout = 60
      origin_read_timeout      = 60
    }
  }
  additional_custom_origin_primary = local.additional_custom_origins_enabled ? merge(
    local.default_custom_origin_configuration, {
      domain_name = module.additional_custom_origin.bucket_website_endpoint
      origin_id   = module.additional_custom_origin.bucket_id
    }
  ) : null
  additional_custom_origin_secondary = local.additional_custom_origins_enabled ? merge(
    local.default_custom_origin_configuration, {
      domain_name = module.additional_custom_failover_origin.bucket_website_endpoint
      origin_id   = module.additional_custom_failover_origin.bucket_id
    }
  ) : null
  additional_custom_origin_groups = local.additional_custom_origins_enabled ? [{
    primary_origin_id  = local.additional_custom_origin_primary.origin_id
    failover_origin_id = local.additional_custom_origin_secondary.origin_id
    failover_criteria  = var.origin_group_failover_criteria_status_codes
  }] : []
  website_configuration = [
    {
      index_document = "index.html"
      error_document = null
      routing_rules  = []
    }
  ]
  cors_configuration = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET"]
      allowed_origins = ["*"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3600
    }
  ]
}

# additional labels are required because they will be used for the 'hostname' variables for each of the additional website origins.
module "additional_custom_origin_label" {
  source  = "cloudposse/label/null"
  version = "0.24.1"
  enabled = local.additional_custom_origins_enabled

  attributes = ["web"]

  context = module.this.context
}

module "additional_custom_origin" {
  source  = "cloudposse/s3-bucket/aws"
  version = "3.1.2"

  enabled = local.additional_custom_origins_enabled

  bucket_name           = format("%s.%s", module.additional_custom_origin_label.id, var.parent_zone_name)
  force_destroy         = true
  website_configuration = local.website_configuration
  cors_configuration    = local.cors_configuration

  context = module.additional_custom_origin_label.context
}

resource "aws_s3_bucket_public_access_block" "additional_custom_origin" {
  count = local.additional_custom_origins_enabled ? 1 : 0

  # The bucket used for a public static website.
  #bridgecrew:skip=BC_AWS_S3_19:Skipping `Ensure S3 bucket has block public ACLS enabled`
  #bridgecrew:skip=BC_AWS_S3_20:Skipping `Ensure S3 Bucket BlockPublicPolicy is set to True`
  #bridgecrew:skip=BC_AWS_S3_21:Skipping `Ensure S3 bucket IgnorePublicAcls is set to True`
  #bridgecrew:skip=BC_AWS_S3_22:Skipping `Ensure S3 bucket RestrictPublicBucket is set to True`
  bucket = module.additional_custom_origin.bucket_id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "additional_custom_origin" {
  count = local.additional_custom_origins_enabled ? 1 : 0

  bucket = module.additional_custom_origin.bucket_id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

module "additional_custom_failover_origin_label" {
  source  = "cloudposse/label/null"
  version = "0.24.1"
  enabled = local.additional_custom_origins_enabled

  attributes = ["web", "fo"]

  context = module.this.context
}

module "additional_custom_failover_origin" {
  source  = "cloudposse/s3-bucket/aws"
  version = "3.1.2"

  enabled = local.additional_custom_origins_enabled

  bucket_name           = format("%s.%s", module.additional_custom_failover_origin_label.id, var.parent_zone_name)
  force_destroy         = true
  website_configuration = local.website_configuration
  cors_configuration    = local.cors_configuration

  context = module.additional_custom_failover_origin_label.context
}

resource "aws_s3_bucket_public_access_block" "additional_custom_failover_origin" {
  count = local.additional_custom_origins_enabled ? 1 : 0

  # The bucket used for a public static website.
  #bridgecrew:skip=BC_AWS_S3_19:Skipping `Ensure S3 bucket has block public ACLS enabled`
  #bridgecrew:skip=BC_AWS_S3_20:Skipping `Ensure S3 Bucket BlockPublicPolicy is set to True`
  #bridgecrew:skip=BC_AWS_S3_21:Skipping `Ensure S3 bucket IgnorePublicAcls is set to True`
  #bridgecrew:skip=BC_AWS_S3_22:Skipping `Ensure S3 bucket RestrictPublicBucket is set to True`
  bucket = module.additional_custom_failover_origin.bucket_id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "additional_custom_failover_origin" {
  count = local.additional_custom_origins_enabled ? 1 : 0

  bucket = module.additional_custom_failover_origin.bucket_id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

