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
  additional_custom_origins = local.additional_custom_origins_enabled ? [
    merge(local.default_custom_origin_configuration, {
      domain_name = module.additional_custom_origin[0].s3_bucket_website_endpoint
      origin_id   = module.additional_custom_origin[0].hostname
    }),
    merge(local.default_custom_origin_configuration, {
      domain_name = module.additional_custom_failover_origin[0].s3_bucket_website_endpoint
      origin_id   = module.additional_custom_failover_origin[0].hostname
    })
  ] : []
  additional_custom_origin_groups = local.additional_custom_origins_enabled ? [{
    primary_origin_id  = local.additional_custom_origins[0].origin_id
    failover_origin_id = local.additional_custom_origins[1].origin_id
    failover_criteria  = var.origin_group_failover_criteria_status_codes
  }] : []
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
  count = local.additional_s3_origins_enabled ? 1 : 0 # https://github.com/cloudposse/terraform-aws-s3-website/issues/65

  source  = "cloudposse/s3-website/aws"
  version = "0.16.0"
  enabled = local.additional_custom_origins_enabled

  force_destroy = true
  hostname      = format("%s.%s", module.additional_custom_origin_label.id, var.parent_zone_name)

  context = module.additional_custom_origin_label.context
}

module "additional_custom_failover_origin_label" {
  source  = "cloudposse/label/null"
  version = "0.24.1"
  enabled = local.additional_custom_origins_enabled

  attributes = ["web", "fo"]

  context = module.this.context
}

module "additional_custom_failover_origin" {
  count = local.additional_s3_origins_enabled ? 1 : 0 # https://github.com/cloudposse/terraform-aws-s3-website/issues/65

  source  = "cloudposse/s3-website/aws"
  version = "0.16.0"
  enabled = local.additional_custom_origins_enabled

  force_destroy = true
  hostname      = format("%s.%s", module.additional_custom_failover_origin_label.id, var.parent_zone_name)

  context = module.additional_custom_failover_origin_label.context
}
