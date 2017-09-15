module "origin_label" {
  source     = "git::https://github.com/cloudposse/tf_label.git?ref=tags/0.2.0"
  namespace  = "${var.namespace}"
  stage      = "${var.stage}"
  name       = "${var.name}"
  delimiter  = "${var.delimiter}"
  attributes = ["origin"]
  tags       = "${var.tags}"
}

resource "aws_cloudfront_origin_access_identity" "default" {
  comment = "${module.distribution_label.id}"
}

data "template_file" "bucket_policy_file" {
  count    = "${signum(length(var.custom_bucket_domain_name)) == 1 ? 0 : 1}"
  template = "${file("${path.module}/policy.json")}"

  vars {
    origin_path = "${var.origin_path}"
    bucket_name = "${module.origin_label.id}"
  }
}

resource "aws_s3_bucket" "origin" {
  count  = "${signum(length(var.custom_bucket_domain_name)) == 1 ? 0 : 1}"
  bucket = "${module.origin_label.id}"
  acl    = "private"
  policy = "${data.template_file.bucket_policy.rendered}"
  tags   = "${module.origin_label.tags}"

  cors_rule {
    allowed_headers = "${var.allowed_headers}"
    allowed_methods = "${var.allowed_methods}"
    allowed_origins = ["${var.aliases}"]
    expose_headers  = ["${var.expose_headers}"]
    max_age_seconds = "${var.max_age_seconds}"
  }

  depends_on = ["data.template_file.bucket_policy"]
}

module "logs" {
  source                   = "git::https://github.com/cloudposse/tf_log_storage.git?ref=init"
  namespace                = "${var.namespace}"
  stage                    = "${var.stage}"
  name                     = "${var.name}"
  delimiter                = "${var.delimiter}"
  attributes               = ["logs"]
  tags                     = "${var.tags}"
  prefix                   = "${var.log_prefix}"
  standard_transition_days = "${var.log_standard_transition_days}"
  glacier_transition_days  = "${var.log_glacier_transition_days}"
  expiration_days          = "${var.log_expiration_days}"
}

module "distribution_label" {
  source    = "git::https://github.com/cloudposse/tf_label.git?ref=tags/0.2.0"
  namespace = "${var.namespace}"
  stage     = "${var.stage}"
  name      = "${var.name}"
  delimiter = "${var.delimiter}"
  tags      = "${var.tags}"
}

resource "null_resource" "default" {
  triggers {
    domain_name = "${signum(length(var.custom_bucket_domain_name)) == 1 ? var.custom_bucket_domain_name : join("", aws_s3_bucket.origin.*.bucket_domain_name) }"
  }
}

resource "aws_cloudfront_distribution" "default" {
  enabled             = "${var.enabled}"
  is_ipv6_enabled     = "${var.is_ipv6_enabled}"
  comment             = "${var.comment}"
  default_root_object = "${var.default_root_object}"
  price_class         = "${var.price_class}"

  logging_config = {
    include_cookies = "${var.log_include_cookies}"
    bucket          = "${module.logs.bucket_domain_name}"
    prefix          = "${var.log_prefix}"
  }

  aliases = ["${var.aliases}"]

  origin {
    domain_name = "${null_resource.default.triggers.domain_name}"
    origin_id   = "${module.distribution_label.id}"
    origin_path = "${var.origin_path}"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.default.cloudfront_access_identity_path}"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = "${var.acm_certificate_arn}"
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1"
    cloudfront_default_certificate = "${signum(length(var.acm_certificate_arn))}"
  }

  default_cache_behavior {
    allowed_methods  = "${var.allowed_methods}"
    cached_methods   = "${var.cached_methods}"
    target_origin_id = "${module.distribution_label.id}"
    compress         = "${var.compress}"

    forwarded_values {
      query_string = "${var.forward_query_string}"

      cookies {
        forward = "${var.forward_cookies}"
      }
    }

    viewer_protocol_policy = "${var.viewer_protocol_policy}"
    default_ttl            = "${var.default_ttl}"
    min_ttl                = "${var.min_ttl}"
    max_ttl                = "${var.max_ttl}"
  }

  restrictions {
    geo_restriction {
      restriction_type = "${var.geo_restriction_type}"
      locations        = "${var.geo_restriction_locations}"
    }
  }

  tags = "${module.distribution_label.tags}"
}

module "dns_aliases" {
  source          = "git::https://github.com/cloudposse/tf_vanity.git?ref=generalize"
  aliases         = ["${var.aliases}"]
  zone_id         = "${var.dns_zone_id}"
  target_dns_name = "${aws_cloudfront_distribution.default.domain_name}"
  target_zone_id  = "${aws_cloudfront_distribution.default.hosted_zone_id}"
}
