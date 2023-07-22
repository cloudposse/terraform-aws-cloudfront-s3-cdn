locals {
  additional_s3_origins_enabled = local.enabled && var.additional_s3_origins_enabled
  default_s3_origin_configuration = {
    domain_name = null
    origin_id   = null
    origin_path = null
    s3_origin_config = {
      origin_access_identity = ""
    }
  }
  additional_s3_origin_primary = local.additional_s3_origins_enabled ? merge(
    local.default_s3_origin_configuration, {
      domain_name = module.additional_s3_origin.bucket_regional_domain_name
      origin_id   = module.additional_s3_origin.bucket_id
    }
  ) : null
  additional_s3_origin_secondary = local.additional_s3_origins_enabled ? merge(
    local.default_s3_origin_configuration, {
      domain_name = module.additional_s3_failover_origin.bucket_regional_domain_name
      origin_id   = module.additional_s3_failover_origin.bucket_id
    }
  ) : null
  additional_s3_origin_groups = local.additional_s3_origins_enabled ? [{
    primary_origin_id  = local.additional_s3_origin_primary.origin_id
    failover_origin_id = local.additional_s3_origin_secondary.origin_id
    failover_criteria  = var.origin_group_failover_criteria_status_codes
  }] : []
}

module "additional_s3_origin" {
  source  = "cloudposse/s3-bucket/aws"
  version = "3.1.2"
  enabled = local.additional_s3_origins_enabled

  force_destroy      = true
  user_enabled       = false
  versioning_enabled = false
  attributes         = ["s3"]

  # See https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/AccessLogs.html
  s3_object_ownership = "BucketOwnerPreferred"
  acl                 = null
  grants = [
    {
      # Canonical ID for the awslogsdelivery account
      id          = "c4c1ede66af53448b93c283ce9448c4ba468c9432aa01d700d3878632f77d2d0"
      permissions = ["FULL_CONTROL"]
      type        = "CanonicalUser"
      uri         = null
    },
  ]

  context = module.this.context
}

module "additional_s3_failover_origin" {
  source  = "cloudposse/s3-bucket/aws"
  version = "3.1.2"
  enabled = local.additional_s3_origins_enabled

  force_destroy      = true
  user_enabled       = false
  versioning_enabled = false
  attributes         = ["s3", "fo"] # fo = failover

  # See https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/AccessLogs.html
  s3_object_ownership = "BucketOwnerPreferred"
  acl                 = null
  grants = [
    {
      # Canonical ID for the awslogsdelivery account
      id          = "c4c1ede66af53448b93c283ce9448c4ba468c9432aa01d700d3878632f77d2d0"
      permissions = ["FULL_CONTROL"]
      type        = "CanonicalUser"
      uri         = null
    },
  ]

  context = module.this.context
}
