locals {
  website_config = {
    redirect_all = [
      {
        redirect_all_requests_to = var.redirect_all_requests_to
      }
    ]
    default = [
      {
        index_document = var.index_document
        error_document = var.error_document
        routing_rules  = var.routing_rules
      }
    ]
  }

  regions_s3_website_use_dash = [
    "us-east-1",
    "us-west-1",
    "us-west-2",
    "ap-southeast-1",
    "ap-southeast-2",
    "ap-northeast-1",
    "sa-east-1"
  ]
}

module "origin_label" {
  source     = "cloudposse/label/null"
  version    = "0.24.1"
  context    = module.this.context
  attributes = compact(concat(module.this.attributes, var.extra_origin_attributes))
}

resource "aws_cloudfront_origin_access_identity" "default" {
  count = module.this.enabled && local.using_existing_cloudfront_origin ? 0 : 1

  comment = module.this.id
}

data "aws_iam_policy_document" "origin" {
  override_json = var.additional_bucket_policy

  statement {
    sid = "S3GetObjectForCloudFront"

    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${local.bucket}${local.origin_path}*"]

    principals {
      type        = "AWS"
      identifiers = [local.cloudfront_origin_access_identity_iam_arn]
    }
  }

  statement {
    sid = "S3ListBucketForCloudFront"

    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${local.bucket}"]

    principals {
      type        = "AWS"
      identifiers = [local.cloudfront_origin_access_identity_iam_arn]
    }
  }
}

data "aws_iam_policy_document" "origin_website" {
  override_json = var.additional_bucket_policy

  statement {
    sid = "S3GetObjectForCloudFront"

    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${local.bucket}${local.origin_path}*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "default" {
  count  = module.this.enabled && ! local.using_existing_origin || var.override_origin_bucket_policy ? 1 : 0
  bucket = join("", aws_s3_bucket.origin.*.bucket)
  policy = local.iam_policy_document
}

resource "aws_s3_bucket" "origin" {
  #bridgecrew:skip=BC_AWS_S3_13:Skipping `Enable S3 Bucket Logging` check until bridgecrew will support dynamic blocks (https://github.com/bridgecrewio/checkov/issues/776).
  #bridgecrew:skip=BC_AWS_S3_14:Skipping `Ensure all data stored in the S3 bucket is securely encrypted at rest` check until bridgecrew will support dynamic blocks (https://github.com/bridgecrewio/checkov/issues/776).
  #bridgecrew:skip=CKV_AWS_52:Skipping `Ensure S3 bucket has MFA delete enabled` due to issue in terraform (https://github.com/hashicorp/terraform-provider-aws/issues/629).
  count         = module.this.enabled && local.using_existing_origin ? 0 : 1
  bucket        = module.origin_label.id
  acl           = "private"
  tags          = module.origin_label.tags
  force_destroy = var.origin_force_destroy

  dynamic "server_side_encryption_configuration" {
    for_each = var.encryption_enabled ? ["true"] : []

    content {
      rule {
        apply_server_side_encryption_by_default {
          sse_algorithm = "AES256"
        }
      }
    }
  }

  versioning {
    enabled = var.versioning_enabled
  }

  dynamic "logging" {
    for_each = var.access_log_bucket_name != "" ? [1] : []
    content {
      target_bucket = var.access_log_bucket_name
      target_prefix = "logs/${module.this.id}/"
    }
  }

  dynamic "website" {
    for_each = var.website_enabled ? local.website_config[var.redirect_all_requests_to == "" ? "default" : "redirect_all"] : []
    content {
      error_document           = lookup(website.value, "error_document", null)
      index_document           = lookup(website.value, "index_document", null)
      redirect_all_requests_to = lookup(website.value, "redirect_all_requests_to", null)
      routing_rules            = lookup(website.value, "routing_rules", null)
    }
  }

  dynamic "cors_rule" {
    for_each = distinct(compact(concat(var.cors_allowed_origins, var.aliases)))
    content {
      allowed_headers = var.cors_allowed_headers
      allowed_methods = var.cors_allowed_methods
      allowed_origins = [cors_rule.value]
      expose_headers  = var.cors_expose_headers
      max_age_seconds = var.cors_max_age_seconds
    }
  }
}

resource "aws_s3_bucket_public_access_block" "origin" {
  count                   = module.this.enabled && ! local.using_existing_origin && var.block_origin_public_access_enabled ? 1 : 0
  bucket                  = local.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Don't ty and modify this bucket in two ways at the same time, S3 API will
  # complain.
  depends_on = [aws_s3_bucket_policy.default]
}

module "logs" {
  source                   = "cloudposse/s3-log-storage/aws"
  version                  = "0.20.0"
  enabled                  = module.this.enabled && var.logging_enabled
  attributes               = compact(concat(module.this.attributes, var.extra_logs_attributes))
  lifecycle_prefix         = var.log_prefix
  standard_transition_days = var.log_standard_transition_days
  glacier_transition_days  = var.log_glacier_transition_days
  expiration_days          = var.log_expiration_days
  force_destroy            = var.origin_force_destroy
  versioning_enabled       = var.log_versioning_enabled

  context = module.this.context
}

data "aws_s3_bucket" "selected" {
  bucket = local.bucket == "" ? var.static_s3_bucket : local.bucket
}

locals {
  using_existing_origin = signum(length(var.origin_bucket)) == 1

  using_existing_cloudfront_origin = var.cloudfront_origin_access_identity_iam_arn != "" && var.cloudfront_origin_access_identity_path != ""

  origin_path                               = coalesce(var.origin_path, "/")
  cloudfront_origin_access_identity_iam_arn = local.using_existing_cloudfront_origin ? var.cloudfront_origin_access_identity_iam_arn : join("", aws_cloudfront_origin_access_identity.default.*.iam_arn)
  iam_policy_document                       = var.website_enabled ? data.aws_iam_policy_document.origin_website.json : data.aws_iam_policy_document.origin.json

  bucket = join("",
    compact(
      concat([var.origin_bucket], concat([""], aws_s3_bucket.origin.*.id))
    )
  )

  bucket_domain_name = (var.use_regional_s3_endpoint || var.website_enabled) ? format(
    var.website_enabled ? "%s.s3-website%s%s.amazonaws.com" : "%s.s3%s%s.amazonaws.com",
    local.bucket,
    (var.website_enabled && contains(local.regions_s3_website_use_dash, data.aws_s3_bucket.selected.region)) ? "-" : ".",
    data.aws_s3_bucket.selected.region,
  ) : format(var.bucket_domain_format, local.bucket)
}

resource "aws_cloudfront_distribution" "default" {
  count = module.this.enabled ? 1 : 0

  #bridgecrew:skip=BC_AWS_LOGGING_20:Skipping `CloudFront Access Logging` check until bridgecrew will support dynamic blocks (https://github.com/bridgecrewio/checkov/issues/776).
  enabled             = var.distribution_enabled
  is_ipv6_enabled     = var.ipv6_enabled
  comment             = var.comment
  default_root_object = var.default_root_object
  price_class         = var.price_class
  depends_on          = [aws_s3_bucket.origin]

  dynamic "logging_config" {
    for_each = var.logging_enabled ? ["true"] : []
    content {
      include_cookies = var.log_include_cookies
      bucket          = module.logs.bucket_domain_name
      prefix          = var.log_prefix
    }
  }

  aliases = var.acm_certificate_arn != "" ? var.aliases : []

  origin {
    domain_name = local.bucket_domain_name
    origin_id   = module.this.id
    origin_path = var.origin_path

    dynamic "s3_origin_config" {
      for_each = ! var.website_enabled ? [1] : []
      content {
        origin_access_identity = local.using_existing_cloudfront_origin ? var.cloudfront_origin_access_identity_path : join("", aws_cloudfront_origin_access_identity.default.*.cloudfront_access_identity_path)
      }
    }

    dynamic "custom_origin_config" {
      for_each = var.website_enabled ? [1] : []
      content {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "http-only"
        origin_ssl_protocols   = var.origin_ssl_protocols
      }
    }
    dynamic "custom_header" {
      for_each = var.custom_origin_headers
      content {
        name  = custom_header.value["name"]
        value = custom_header.value["value"]
      }
    }
  }

  dynamic "origin" {
    for_each = var.custom_origins
    content {
      domain_name = origin.value.domain_name
      origin_id   = origin.value.origin_id
      origin_path = lookup(origin.value, "origin_path", "")
      dynamic "custom_header" {
        for_each = lookup(origin.value, "custom_headers", [])
        content {
          name  = custom_header.value["name"]
          value = custom_header.value["value"]
        }
      }
      custom_origin_config {
        http_port                = lookup(origin.value.custom_origin_config, "http_port", null)
        https_port               = lookup(origin.value.custom_origin_config, "https_port", null)
        origin_protocol_policy   = lookup(origin.value.custom_origin_config, "origin_protocol_policy", "https-only")
        origin_ssl_protocols     = lookup(origin.value.custom_origin_config, "origin_ssl_protocols", ["TLSv1.2"])
        origin_keepalive_timeout = lookup(origin.value.custom_origin_config, "origin_keepalive_timeout", 60)
        origin_read_timeout      = lookup(origin.value.custom_origin_config, "origin_read_timeout", 60)
      }
    }
  }

  viewer_certificate {
    acm_certificate_arn            = var.acm_certificate_arn
    ssl_support_method             = var.acm_certificate_arn == "" ? "" : "sni-only"
    minimum_protocol_version       = var.minimum_protocol_version
    cloudfront_default_certificate = var.acm_certificate_arn == "" ? true : false
  }

  default_cache_behavior {
    allowed_methods  = var.allowed_methods
    cached_methods   = var.cached_methods
    target_origin_id = module.this.id
    compress         = var.compress
    trusted_signers  = var.trusted_signers

    forwarded_values {
      query_string = var.forward_query_string
      headers      = var.forward_header_values

      cookies {
        forward = var.forward_cookies
      }
    }

    viewer_protocol_policy = var.viewer_protocol_policy
    default_ttl            = var.default_ttl
    min_ttl                = var.min_ttl
    max_ttl                = var.max_ttl

    dynamic "lambda_function_association" {
      for_each = var.lambda_function_association
      content {
        event_type   = lambda_function_association.value.event_type
        include_body = lookup(lambda_function_association.value, "include_body", null)
        lambda_arn   = lambda_function_association.value.lambda_arn
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.ordered_cache

    content {
      path_pattern = ordered_cache_behavior.value.path_pattern

      allowed_methods  = ordered_cache_behavior.value.allowed_methods
      cached_methods   = ordered_cache_behavior.value.cached_methods
      target_origin_id = ordered_cache_behavior.value.target_origin_id == "" ? module.this.id : ordered_cache_behavior.value.target_origin_id
      compress         = ordered_cache_behavior.value.compress
      trusted_signers  = var.trusted_signers

      forwarded_values {
        query_string = ordered_cache_behavior.value.forward_query_string
        headers      = ordered_cache_behavior.value.forward_header_values

        cookies {
          forward = ordered_cache_behavior.value.forward_cookies
        }
      }

      viewer_protocol_policy = ordered_cache_behavior.value.viewer_protocol_policy
      default_ttl            = ordered_cache_behavior.value.default_ttl
      min_ttl                = ordered_cache_behavior.value.min_ttl
      max_ttl                = ordered_cache_behavior.value.max_ttl

      dynamic "lambda_function_association" {
        for_each = ordered_cache_behavior.value.lambda_function_association
        content {
          event_type   = lambda_function_association.value.event_type
          include_body = lookup(lambda_function_association.value, "include_body", null)
          lambda_arn   = lambda_function_association.value.lambda_arn
        }
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_locations
    }
  }

  dynamic "custom_error_response" {
    for_each = var.custom_error_response
    content {
      error_caching_min_ttl = lookup(custom_error_response.value, "error_caching_min_ttl", null)
      error_code            = custom_error_response.value.error_code
      response_code         = lookup(custom_error_response.value, "response_code", null)
      response_page_path    = lookup(custom_error_response.value, "response_page_path", null)
    }
  }

  web_acl_id          = var.web_acl_id
  wait_for_deployment = var.wait_for_deployment

  tags = module.this.tags
}

module "dns" {
  source           = "cloudposse/route53-alias/aws"
  version          = "0.12.0"
  enabled          = module.this.enabled && var.dns_alias_enabled ? true : false
  aliases          = var.aliases
  parent_zone_id   = var.parent_zone_id
  parent_zone_name = var.parent_zone_name
  target_dns_name  = aws_cloudfront_distribution.default[0].domain_name
  target_zone_id   = aws_cloudfront_distribution.default[0].hosted_zone_id
  ipv6_enabled     = var.ipv6_enabled

  context = module.this.context
}
