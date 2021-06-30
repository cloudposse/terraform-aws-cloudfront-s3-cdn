locals {
  default_s3_origin_configuration = {
    domain_name      = null
    origin_id        = null
    origin_path      = null
    s3_origin_config = {
      origin_access_identity = ""
    }
  }
  s3_origins = [
    merge(local.default_s3_origin_configuration, {
      domain_name    = module.additional_s3_origin.bucket_regional_domain_name
      origin_id      = module.additional_s3_origin.bucket_id
    })
  ]
  s3_failover_origins = {
    (module.additional_s3_origin.bucket_id) = merge(local.default_s3_origin_configuration, {
      domain_name    = module.additional_s3_failover_origin.bucket_regional_domain_name
      origin_id      = module.additional_s3_failover_origin.bucket_id
    })
  }
}

module "additional_s3_origin" {
  source  = "cloudposse/s3-bucket/aws"
  version = "0.36.0"
  enabled = var.additional_s3_origins_enabled

  acl                = "private"
  force_destroy      = true
  user_enabled       = false
  versioning_enabled = false
  attributes         = ["s3"]

  context = module.this.context
}

module "additional_s3_failover_origin" {
  source  = "cloudposse/s3-bucket/aws"
  version = "0.36.0"
  enabled = var.additional_s3_origins_enabled

  acl                = "private"
  force_destroy      = true
  user_enabled       = false
  versioning_enabled = false
  attributes         = ["s3", "fo"]

  context = module.this.context
}
