locals {
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
  custom_origins = [
    merge(local.default_custom_origin_configuration, {
      domain_name    = module.additional_custom_origin.s3_bucket_website_endpoint
      origin_id      = module.additional_custom_origin.hostname
    })
  ]
  custom_failover_origins = {
    (module.additional_custom_origin.hostname) = merge(local.default_custom_origin_configuration, {
      domain_name    = module.additional_custom_failover_origin.s3_bucket_website_endpoint
      origin_id      = module.additional_custom_failover_origin.hostname
    })
  }
}

# additional labels are required because they will be used for the 'hostname' variables for each of the additional website origins.
module "additional_custom_origin_label" {
  source  = "cloudposse/label/null"
  version = "0.24.1"
  enabled = var.additional_custom_origins_enabled

  attributes = ["web"]

  context = module.this.context
}

module "additional_custom_origin" {
  source  = "cloudposse/s3-website/aws"
  version = "0.16.0"
  enabled = var.additional_custom_origins_enabled

  hostname   = format("%s.%s", module.additional_custom_origin_label.id, var.parent_zone_name)

  context = module.additional_custom_origin_label.context
}

module "additional_custom_failover_origin_label" {
  source  = "cloudposse/label/null"
  version = "0.24.1"
  enabled = var.additional_custom_origins_enabled

  attributes = ["web", "fo"]

  context = module.this.context
}

module "additional_custom_failover_origin" {
  source  = "cloudposse/s3-website/aws"
  version = "0.16.0"
  enabled = var.additional_custom_origins_enabled

  hostname   = format("%s.%s", module.additional_custom_failover_origin_label.id, var.parent_zone_name)

  context = module.additional_custom_failover_origin_label.context
}
