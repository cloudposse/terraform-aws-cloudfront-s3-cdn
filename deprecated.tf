# Phase out variables by changing the default to `null` and using the replacement variables when they are `null`
locals {

  s3_access_log_bucket_name = var.access_log_bucket_name == null ? var.s3_access_log_bucket_name : var.access_log_bucket_name

  cloudfront_access_logging_enabled     = local.enabled && (var.logging_enabled == null ? var.cloudfront_access_logging_enabled : var.logging_enabled)
  cloudfront_access_log_include_cookies = var.log_include_cookies == null ? var.cloudfront_access_log_include_cookies : var.log_include_cookies
  cloudfront_access_log_prefix          = var.log_prefix == null ? var.cloudfront_access_log_prefix : var.log_prefix

  # New variables, but declare them here for consistency
  cloudfront_access_log_create_bucket = var.cloudfront_access_log_create_bucket
}

