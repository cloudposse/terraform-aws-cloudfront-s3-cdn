module "origin_label" {
  source     = "git::https://github.com/cloudposse/terraform-terraform-label.git?ref=tags/0.1.6"
  namespace  = "${var.namespace}"
  stage      = "${var.stage}"
  name       = "${var.name}"
  delimiter  = "${var.delimiter}"
  attributes = ["${compact(concat(var.attributes, list("origin")))}"]
  tags       = "${var.tags}"
}

resource "aws_cloudfront_origin_access_identity" "default" {
  comment = "${module.distribution_label.id}"
}

data "aws_iam_policy_document" "origin" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::$${bucket_name}$${origin_path}*"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.default.iam_arn}"]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::$${bucket_name}"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.default.iam_arn}"]
    }
  }
}

data "template_file" "default" {
  template = "${data.aws_iam_policy_document.origin.json}"

  vars {
    origin_path = "${coalesce(var.origin_path, "/")}"
    bucket_name = "${local.bucket}"
  }
}

resource "aws_s3_bucket_policy" "default" {
  bucket = "${local.bucket}"
  policy = "${data.template_file.default.rendered}"
}

data "aws_region" "current" {}

resource "aws_s3_bucket" "origin" {
  count         = "${signum(length(var.origin_bucket)) == 1 ? 0 : 1}"
  bucket        = "${module.origin_label.id}"
  acl           = "private"
  tags          = "${module.origin_label.tags}"
  force_destroy = "${var.origin_force_destroy}"
  region        = "${data.aws_region.current.name}"

  cors_rule {
    allowed_headers = "${var.cors_allowed_headers}"
    allowed_methods = "${var.cors_allowed_methods}"
    allowed_origins = "${sort(distinct(compact(concat(var.cors_allowed_origins, var.aliases))))}"
    expose_headers  = "${var.cors_expose_headers}"
    max_age_seconds = "${var.cors_max_age_seconds}"
  }
}

module "logs" {
  source                   = "git::https://github.com/cloudposse/terraform-aws-s3-log-storage.git?ref=tags/0.2.0"
  namespace                = "${var.namespace}"
  stage                    = "${var.stage}"
  name                     = "${var.name}"
  delimiter                = "${var.delimiter}"
  attributes               = ["${compact(concat(var.attributes, list("logs")))}"]
  tags                     = "${var.tags}"
  prefix                   = "${var.log_prefix}"
  standard_transition_days = "${var.log_standard_transition_days}"
  glacier_transition_days  = "${var.log_glacier_transition_days}"
  expiration_days          = "${var.log_expiration_days}"
  force_destroy            = "${var.origin_force_destroy}"
}

module "distribution_label" {
  source     = "git::https://github.com/cloudposse/terraform-terraform-label.git?ref=tags/0.1.6"
  namespace  = "${var.namespace}"
  stage      = "${var.stage}"
  name       = "${var.name}"
  delimiter  = "${var.delimiter}"
  attributes = "${var.attributes}"
  tags       = "${var.tags}"
}

data "aws_s3_bucket" "selected" {
  bucket = "${local.bucket == "" ? var.static_s3_bucket : local.bucket}"
}

locals {
  bucket             = "${join("", compact(concat(list(var.origin_bucket), concat(list(""), aws_s3_bucket.origin.*.id))))}"
  bucket_domain_name = "${var.use_regional_s3_endpoint == "true" ? format("%s.s3-%s.amazonaws.com" , local.bucket, data.aws_s3_bucket.selected.region): format(var.bucket_domain_format, local.bucket)}"
}

resource "aws_cloudfront_distribution" "default" {
  enabled             = "${var.enabled}"
  is_ipv6_enabled     = "${var.is_ipv6_enabled}"
  comment             = "${var.comment}"
  default_root_object = "${var.default_root_object}"
  price_class         = "${var.price_class}"
  depends_on          = ["aws_s3_bucket.origin"]

  logging_config = {
    include_cookies = "${var.log_include_cookies}"
    bucket          = "${module.logs.bucket_domain_name}"
    prefix          = "${var.log_prefix}"
  }

  aliases = ["${var.aliases}"]

  origin {
    domain_name = "${local.bucket_domain_name}"
    origin_id   = "${module.distribution_label.id}"
    origin_path = "${var.origin_path}"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.default.cloudfront_access_identity_path}"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = "${var.acm_certificate_arn}"
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "${var.minimum_protocol_version}"
    cloudfront_default_certificate = "${var.acm_certificate_arn == "" ? true : false}"
  }

  default_cache_behavior {
    allowed_methods  = "${var.allowed_methods}"
    cached_methods   = "${var.cached_methods}"
    target_origin_id = "${module.distribution_label.id}"
    compress         = "${var.compress}"

    forwarded_values {
      query_string = "${var.forward_query_string}"
      headers      = ["${var.forward_header_values}"]

      cookies {
        forward = "${var.forward_cookies}"
      }
    }

    viewer_protocol_policy = "${var.viewer_protocol_policy}"
    default_ttl            = "${var.default_ttl}"
    min_ttl                = "${var.min_ttl}"
    max_ttl                = "${var.max_ttl}"

    lambda_function_association = ["${var.lambda_function_association}"]
  }

  restrictions {
    geo_restriction {
      restriction_type = "${var.geo_restriction_type}"
      locations        = "${var.geo_restriction_locations}"
    }
  }

  custom_error_response = ["${var.custom_error_response}"]
  web_acl_id            = "${var.web_acl_id}"

  tags = "${module.distribution_label.tags}"
}

module "dns" {
  source           = "git::https://github.com/cloudposse/terraform-aws-route53-alias.git?ref=tags/0.2.5"
  enabled          = "${var.enabled}"
  aliases          = "${var.aliases}"
  parent_zone_id   = "${var.parent_zone_id}"
  parent_zone_name = "${var.parent_zone_name}"
  target_dns_name  = "${aws_cloudfront_distribution.default.domain_name}"
  target_zone_id   = "${aws_cloudfront_distribution.default.hosted_zone_id}"
}
