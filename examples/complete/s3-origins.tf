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
  version = "0.39.0"
  enabled = local.additional_s3_origins_enabled

  acl                = "private"
  force_destroy      = true
  user_enabled       = false
  versioning_enabled = false
  attributes         = ["s3"]

  context = module.this.context
}

module "additional_s3_failover_origin" {
  source  = "cloudposse/s3-bucket/aws"
  version = "0.39.0"
  enabled = local.additional_s3_origins_enabled

  acl                = "private"
  force_destroy      = true
  user_enabled       = false
  versioning_enabled = false
  attributes         = ["s3", "fo"] # fo = failover

  context = module.this.context
}
