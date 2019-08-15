module "origin_label" {
  source     = "git::https://github.com/cloudposse/terraform-terraform-label.git?ref=tags/0.4.0"
  namespace  = var.namespace
  stage      = var.stage
  name       = var.name
  delimiter  = var.delimiter
  attributes = compact(concat(var.attributes, ["origin"]))
  tags       = var.tags
}

resource "aws_cloudfront_origin_access_identity" "default" {
  comment = module.distribution_label.id
}

data "aws_region" "current" {
}

resource "aws_s3_bucket" "origin" {
  count         = signum(length(var.origin_bucket)) == 1 ? 0 : 1
  bucket        = module.origin_label.id
  acl           = "private"
  tags          = module.origin_label.tags
  force_destroy = var.origin_force_destroy
  region        = data.aws_region.current.name

  dynamic "website" {
    for_each = length(var.website_config) == 0 ? [] : list(var.website_config)
    content {
      error_document           = lookup(website.value, "error_document", null)
      index_document           = lookup(website.value, "index_document", null)
      redirect_all_requests_to = lookup(website.value, "redirect_all_requests_to", null)
      routing_rules            = lookup(website.value, "routing_rules", null)
    }
  }

  dynamic "cors_rule" {
    for_each = length(distinct(compact(concat(var.cors_allowed_origins, var.aliases)))) != 0 ? [true] : []
    content {
      allowed_headers = var.cors_allowed_headers
      allowed_methods = var.cors_allowed_methods
      allowed_origins = sort(
        distinct(compact(concat(var.cors_allowed_origins, var.aliases))),
      )
      expose_headers  = var.cors_expose_headers
      max_age_seconds = var.cors_max_age_seconds
    }
  }

  versioning {
    enabled = var.versioning_enabled
  }

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rule_enabled == null ? [] : list(var.lifecycle_rule_enabled)

    content {
      id      = module.origin_label.id
      enabled = lifecycle_rule.value
      prefix  = var.lifecycle_rule_prefix
      tags    = module.origin_label.tags

      dynamic "transition" {
        for_each = var.transition_config
        content {
          days          = lookup(transition.value, "days", 30)
          storage_class = lookup(transition.value, "storage_class", "GLACIER")
        }
      }

      dynamic "expiration" {
        for_each = var.expiration_days == null ? [] : list(var.expiration_days)
        content {
          days = expiration.value
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = var.versioning_enabled && var.noncurrent_version_transition_config != [] ? var.noncurrent_version_transition_config : []
        content {
          days          = lookup(noncurrent_version_transition.value, "days", 30)
          storage_class = lookup(noncurrent_version_transition.value, "storage_class", "GLACIER")
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = var.versioning_enabled && var.noncurrent_version_expiration_days != null ? list(var.noncurrent_version_expiration_days) : []
        content {
          days = noncurrent_version_expiration.value
        }
      }
    }
  }
}

# AWS only supports a single bucket policy on a bucket. You can combine multiple Statements into a single policy, but not attach multiple policies.
# https://github.com/hashicorp/terraform/issues/10543
resource "aws_s3_bucket_policy" "default" {
  bucket = data.aws_s3_bucket.origin.id
  policy = data.aws_iam_policy_document.origin.json
}

data "aws_iam_policy_document" "origin" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${data.aws_s3_bucket.origin.arn}${coalesce(var.origin_path, "/")}*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.default.iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = ["${data.aws_s3_bucket.origin.arn}"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.default.iam_arn]
    }
  }

  # Support replication ARNs
  dynamic "statement" {
    for_each = flatten(data.aws_iam_policy_document.replication.*.statement)
    content {
      actions       = lookup(statement.value, "actions", null)
      effect        = lookup(statement.value, "effect", null)
      not_actions   = lookup(statement.value, "not_actions", null)
      not_resources = lookup(statement.value, "not_resources", null)
      resources     = lookup(statement.value, "resources", null)
      sid           = lookup(statement.value, "sid", null)

      dynamic "condition" {
        for_each = lookup(statement.value, "condition", [])
        content {
          test     = condition.value.test
          values   = condition.value.values
          variable = condition.value.variable
        }
      }

      dynamic "not_principals" {
        for_each = lookup(statement.value, "not_principals", [])
        content {
          identifiers = not_principals.value.identifiers
          type        = not_principals.value.type
        }
      }

      dynamic "principals" {
        for_each = lookup(statement.value, "principals", [])
        content {
          identifiers = principals.value.identifiers
          type        = principals.value.type
        }
      }
    }
  }

  # Support deployment ARNs
  dynamic "statement" {
    for_each = flatten(data.aws_iam_policy_document.deployment.*.statement)
    content {
      actions       = lookup(statement.value, "actions", null)
      effect        = lookup(statement.value, "effect", null)
      not_actions   = lookup(statement.value, "not_actions", null)
      not_resources = lookup(statement.value, "not_resources", null)
      resources     = lookup(statement.value, "resources", null)
      sid           = lookup(statement.value, "sid", null)

      dynamic "condition" {
        for_each = lookup(statement.value, "condition", [])
        content {
          test     = condition.value.test
          values   = condition.value.values
          variable = condition.value.variable
        }
      }

      dynamic "not_principals" {
        for_each = lookup(statement.value, "not_principals", [])
        content {
          identifiers = not_principals.value.identifiers
          type        = not_principals.value.type
        }
      }

      dynamic "principals" {
        for_each = lookup(statement.value, "principals", [])
        content {
          identifiers = principals.value.identifiers
          type        = principals.value.type
        }
      }
    }
  }
}

data "aws_iam_policy_document" "replication" {
  count = signum(length(var.replication_source_principal_arns))

  statement {
    principals {
      type        = "AWS"
      identifiers = var.replication_source_principal_arns
    }

    actions = [
      "s3:GetBucketVersioning",
      "s3:PutBucketVersioning",
      "s3:ReplicateObject",
      "s3:ReplicateDelete"
    ]

    resources = [
      data.aws_s3_bucket.origin.arn,
      "${data.aws_s3_bucket.origin.arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "deployment" {
  count = length(keys(var.deployment_arns))

  statement {
    actions = var.deployment_actions

    resources = flatten([
      formatlist(
        "${data.aws_s3_bucket.origin.arn}%s",
        var.deployment_arns[keys(var.deployment_arns)[count.index]]
      ),
      formatlist(
        "${data.aws_s3_bucket.origin.arn}%s/*",
        var.deployment_arns[keys(var.deployment_arns)[count.index]]
      )
    ])

    principals {
      type        = "AWS"
      identifiers = [keys(var.deployment_arns)[count.index]]
    }
  }
}

module "logs" {
  source                   = "git::https://github.com/cloudposse/terraform-aws-s3-log-storage.git?ref=tags/0.5.0"
  namespace                = var.namespace
  stage                    = var.stage
  name                     = var.name
  delimiter                = var.delimiter
  attributes               = compact(concat(var.attributes, ["logs"]))
  tags                     = var.tags
  lifecycle_prefix         = var.log_prefix
  standard_transition_days = var.log_standard_transition_days
  glacier_transition_days  = var.log_glacier_transition_days
  expiration_days          = var.log_expiration_days
  force_destroy            = var.origin_force_destroy
}

module "distribution_label" {
  source     = "git::https://github.com/cloudposse/terraform-terraform-label.git?ref=tags/0.4.0"
  namespace  = var.namespace
  stage      = var.stage
  name       = var.name
  delimiter  = var.delimiter
  attributes = var.attributes
  tags       = var.tags
}

data "aws_s3_bucket" "selected" {
  bucket = local.bucket == "" ? var.static_s3_bucket : local.bucket
}

locals {
  bucket = join(
    "",
    compact(
      concat([var.origin_bucket], concat([""], aws_s3_bucket.origin.*.id)),
    ),
  )

  bucket_domain_name = length(var.website_config) != 0 ? data.aws_s3_bucket.origin.website_endpoint : (var.use_regional_s3_endpoint ? format(
    "%s.s3-%s.amazonaws.com",
    local.bucket,
    data.aws_s3_bucket.selected.region,
  ) : format(var.bucket_domain_format, local.bucket))
}

data "aws_s3_bucket" "origin" {
  bucket = local.bucket
}

resource "aws_cloudfront_distribution" "default" {
  enabled             = var.enabled
  is_ipv6_enabled     = var.is_ipv6_enabled
  comment             = var.comment
  default_root_object = var.default_root_object
  price_class         = var.price_class
  depends_on          = [aws_s3_bucket.origin]

  logging_config {
    include_cookies = var.log_include_cookies
    bucket          = module.logs.bucket_domain_name
    prefix          = var.log_prefix
  }

  aliases = var.aliases

  origin {
    domain_name = local.bucket_domain_name
    origin_id   = module.distribution_label.id
    origin_path = var.origin_path

    dynamic "s3_origin_config" {
      for_each = length(var.website_config) == 0 ? [true] : []
      content {
        origin_access_identity = aws_cloudfront_origin_access_identity.default.cloudfront_access_identity_path
      }
    }

    dynamic "custom_origin_config" {
      for_each = length(var.website_config) == 0 ? [] : list(var.website_config)
      content {
        http_port                = var.origin_http_port
        https_port               = var.origin_https_port
        origin_protocol_policy   = var.origin_protocol_policy
        origin_ssl_protocols     = var.origin_ssl_protocols
        origin_keepalive_timeout = var.origin_keepalive_timeout
        origin_read_timeout      = var.origin_read_timeout
      }
    }
  }

  viewer_certificate {
    acm_certificate_arn            = var.acm_certificate_arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = var.minimum_protocol_version
    cloudfront_default_certificate = var.acm_certificate_arn == "" ? true : false
  }

  default_cache_behavior {
    allowed_methods  = var.allowed_methods
    cached_methods   = var.cached_methods
    target_origin_id = module.distribution_label.id
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

  tags = module.distribution_label.tags
}

module "dns" {
  source           = "git::https://github.com/cloudposse/terraform-aws-route53-alias.git?ref=tags/0.3.0"
  enabled          = var.enabled && length(var.parent_zone_id) > 0 || length(var.parent_zone_name) > 0 ? true : false
  aliases          = var.aliases
  parent_zone_id   = var.parent_zone_id
  parent_zone_name = var.parent_zone_name
  target_dns_name  = aws_cloudfront_distribution.default.domain_name
  target_zone_id   = aws_cloudfront_distribution.default.hosted_zone_id
}
