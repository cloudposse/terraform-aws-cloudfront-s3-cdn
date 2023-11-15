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

  force_destroy       = true
  user_enabled        = false
  versioning_enabled  = false
  block_public_policy = false
  attributes          = ["s3"]

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

module "additional_s3_failover_origin" {
  source  = "cloudposse/s3-bucket/aws"
  version = "3.1.2"
  enabled = local.additional_s3_origins_enabled

  force_destroy       = true
  user_enabled        = false
  versioning_enabled  = false
  block_public_policy = false
  attributes          = ["s3", "fo"] # fo = failover

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

resource "time_sleep" "wait_for_additional_s3_origins" {
  count = local.additional_s3_origins_enabled ? 1 : 0

  create_duration  = "30s"
  destroy_duration = "30s"

  depends_on = [
    module.additional_s3_origin,
    module.additional_s3_failover_origin
  ]
}

