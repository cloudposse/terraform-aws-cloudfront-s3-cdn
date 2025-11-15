variable "extra_origin_attributes" {
  type        = list(string)
  default     = ["origin"]
  description = "Additional attributes to put onto the origin label"
}

variable "acm_certificate_arn" {
  type        = string
  description = "Existing ACM Certificate ARN"
  default     = ""
}

variable "minimum_protocol_version" {
  type        = string
  description = <<-EOT
    Cloudfront TLS minimum protocol version.
    If `var.acm_certificate_arn` is unset, only "TLSv1" can be specified. See: [AWS Cloudfront create-distribution documentation](https://docs.aws.amazon.com/cli/latest/reference/cloudfront/create-distribution.html)
    and [Supported protocols and ciphers between viewers and CloudFront](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/secure-connections-supported-viewer-protocols-ciphers.html#secure-connections-supported-ciphers) for more information.
    Defaults to "TLSv1.2_2021" unless `var.acm_certificate_arn` is unset, in which case it defaults to `TLSv1`
    EOT
  default     = ""
}

variable "aliases" {
  type        = list(string)
  description = "List of FQDN's - Used to set the Alternate Domain Names (CNAMEs) setting on Cloudfront"
  default     = []
}

variable "external_aliases" {
  type        = list(string)
  description = "List of FQDN's - Used to set the Alternate Domain Names (CNAMEs) setting on Cloudfront. No new route53 records will be created for these"
  default     = []
}

variable "additional_bucket_policy" {
  type        = string
  default     = "{}"
  description = <<-EOT
    Additional policies for the bucket. If included in the policies, the variables `$${bucket_name}`, `$${origin_path}` and `$${cloudfront_origin_access_identity_iam_arn}` will be substituted.
    It is also possible to override the default policy statements by providing statements with `S3GetObjectForCloudFront` and `S3ListBucketForCloudFront` sid.
    EOT
}

variable "override_origin_bucket_policy" {
  type        = bool
  default     = true
  description = "When using an existing origin bucket (through var.origin_bucket), setting this to 'false' will make it so the existing bucket policy will not be overriden"
}

variable "origin_bucket" {
  type        = string
  default     = null
  description = "Name of an existing S3 bucket to use as the origin. If this is not provided, it will create a new s3 bucket using `var.name` and other context related inputs"
}

variable "origin_path" {
  # http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-values-specify.html#DownloadDistValuesOriginPath
  type        = string
  description = "An optional element that causes CloudFront to request your content from a directory in your Amazon S3 bucket or your custom origin. It must begin with a /. Do not add a / at the end of the path."
  default     = ""
}

variable "origin_force_destroy" {
  type        = bool
  default     = false
  description = "Delete all objects from the bucket so that the bucket can be destroyed without error (e.g. `true` or `false`)"
}

variable "cloudfront_origin_access_control_id" {
  # https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html
  type        = string
  default     = ""
  description = "CloudFront provides two ways to send authenticated requests to an Amazon S3 origin: origin access control (OAC) and origin access identity (OAI). OAC helps you secure your origins, such as for Amazon S3."
}

variable "origin_access_control_signing_behavior" {
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control#signing_behavior
  type        = string
  default     = "always"
  description = "Specifies which requests CloudFront signs. Specify always for the most common use case. Allowed values: always, never, and no-override."

  validation {
    condition     = var.origin_access_control_signing_behavior == "always" || var.origin_access_control_signing_behavior == "no-override" || var.origin_access_control_signing_behavior == "never"
    error_message = "The origin_access_control_signing_behavior must be one of: `always`, `no-override`, or `never`."
  }
}

variable "compress" {
  type        = bool
  default     = true
  description = "Compress content for web requests that include Accept-Encoding: gzip in the request header"
}

variable "default_root_object" {
  type        = string
  default     = "index.html"
  description = "Object that CloudFront return when requests the root URL"
}

variable "comment" {
  type        = string
  default     = "Managed by Terraform"
  description = "Comment/description of the CloudFront distribution."
}

variable "log_standard_transition_days" {
  type        = number
  default     = 30
  description = <<-EOT
    Number of days after object creation to move Cloudfront Access Log objects to the infrequent access tier.
    Only effective if `cloudfront_access_log_create_bucket` is `true`.
    EOT
}

variable "log_glacier_transition_days" {
  type        = number
  default     = 60
  description = <<-EOT
    Number of days after object creation to move Cloudfront Access Log objects to the glacier tier.
    Only effective if `cloudfront_access_log_create_bucket` is `true`.
    EOT
}

variable "log_expiration_days" {
  type        = number
  default     = 90
  description = <<-EOT
    Number of days after object creation to expire Cloudfront Access Log objects.
    Only effective if `cloudfront_access_log_create_bucket` is `true`.
    EOT
}

variable "log_versioning_enabled" {
  type        = bool
  default     = false
  description = <<-EOT
    Set `true` to enable object versioning in the created Cloudfront Access Log S3 Bucket.
    Only effective if `cloudfront_access_log_create_bucket` is `true`.
    EOT
}

variable "forward_query_string" {
  type        = bool
  default     = false
  description = "Forward query strings to the origin that is associated with this cache behavior (incompatible with `cache_policy_id`)"
}

variable "query_string_cache_keys" {
  type        = list(string)
  description = "When `forward_query_string` is enabled, only the query string keys listed in this argument are cached (incompatible with `cache_policy_id`)"
  default     = []
}

variable "cors_allowed_headers" {
  type        = list(string)
  default     = ["*"]
  description = "List of allowed headers for S3 bucket"
}

variable "cors_allowed_methods" {
  type        = list(string)
  default     = ["GET"]
  description = "List of allowed methods (e.g. GET, PUT, POST, DELETE, HEAD) for S3 bucket"
}

variable "cors_allowed_origins" {
  type        = list(string)
  default     = []
  description = "List of allowed origins (e.g. example.com, test.com) for S3 bucket"
}

variable "cors_expose_headers" {
  type        = list(string)
  default     = ["ETag"]
  description = "List of expose header in the response for S3 bucket"
}

variable "cors_max_age_seconds" {
  type        = number
  default     = 3600
  description = "Time in seconds that browser can cache the response for S3 bucket"
}

variable "forward_cookies" {
  type        = string
  default     = "none"
  description = "Specifies whether you want CloudFront to forward all or no cookies to the origin. Can be 'all' or 'none'"
}

variable "forward_cookies_whitelisted_names" {
  type        = list(string)
  description = "List of forwarded cookie names"
  default     = []
}

variable "forward_header_values" {
  type        = list(string)
  description = "A list of whitelisted header values to forward to the origin (incompatible with `cache_policy_id`)"
  default     = ["Access-Control-Request-Headers", "Access-Control-Request-Method", "Origin"]
}

variable "price_class" {
  type        = string
  default     = "PriceClass_100"
  description = "Price class for this distribution: `PriceClass_All`, `PriceClass_200`, `PriceClass_100`"
}

variable "response_headers_policy_id" {
  type        = string
  description = "The identifier for a response headers policy"
  default     = ""
}

variable "viewer_protocol_policy" {
  type        = string
  description = "Limit the protocol users can use to access content. One of `allow-all`, `https-only`, or `redirect-to-https`"
  default     = "redirect-to-https"
}

variable "allowed_methods" {
  type        = list(string)
  default     = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
  nullable    = false
  description = "List of allowed methods (e.g. GET, PUT, POST, DELETE, HEAD) for AWS CloudFront"
}

variable "cached_methods" {
  type        = list(string)
  default     = ["GET", "HEAD"]
  nullable    = false
  description = "List of cached methods (e.g. GET, PUT, POST, DELETE, HEAD)"
}

variable "cache_policy_id" {
  type        = string
  default     = null
  description = <<-EOT
    The unique identifier of the existing cache policy to attach to the default cache behavior.
    If not provided, this module will add a default cache policy using other provided inputs.
    EOT
}

variable "origin_request_policy_id" {
  type        = string
  default     = null
  description = <<-EOT
    The unique identifier of the origin request policy that is attached to the behavior.
    Should be used in conjunction with `cache_policy_id`.
    EOT
}

variable "default_ttl" {
  type        = number
  default     = 60
  description = "Default amount of time (in seconds) that an object is in a CloudFront cache"
}

variable "min_ttl" {
  type        = number
  default     = 0
  description = "Minimum amount of time that you want objects to stay in CloudFront caches"
}

variable "max_ttl" {
  type        = number
  default     = 31536000
  description = "Maximum amount of time (in seconds) that an object is in a CloudFront cache"
}

variable "trusted_signers" {
  type        = list(string)
  default     = []
  description = "The AWS accounts, if any, that you want to allow to create signed URLs for private content. 'self' is acceptable."
}

variable "trusted_key_groups" {
  type        = list(string)
  default     = []
  description = "A list of key group IDs that CloudFront can use to validate signed URLs or signed cookies."
}

variable "geo_restriction_type" {
  type = string

  # e.g. "whitelist"
  default     = "none"
  description = "Method that use to restrict distribution of your content by country: `none`, `whitelist`, or `blacklist`"
}

variable "geo_restriction_locations" {
  type = list(string)

  # e.g. ["US", "CA", "GB", "DE"]
  default     = []
  description = "List of country codes for which  CloudFront either to distribute content (whitelist) or not distribute your content (blacklist)"
}

variable "parent_zone_id" {
  type        = string
  default     = null
  description = "ID of the hosted zone to contain this record (or specify `parent_zone_name`). Requires `dns_alias_enabled` set to true"
}

variable "parent_zone_name" {
  type        = string
  default     = ""
  description = "Name of the hosted zone to contain this record (or specify `parent_zone_id`). Requires `dns_alias_enabled` set to true"
}

variable "dns_alias_enabled" {
  type        = bool
  default     = false
  description = "Create a DNS alias for the CDN. Requires `parent_zone_id` or `parent_zone_name`"
}

variable "dns_allow_overwrite" {
  type        = bool
  default     = false
  description = "Allow creation of DNS records in Terraform to overwrite an existing record, if any. This does not affect the ability to update the record in Terraform and does not prevent other resources within Terraform or manual Route 53 changes outside Terraform from overwriting this record. false by default. This configuration is not recommended for most environments"
}

variable "custom_error_response" {
  # http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/custom-error-pages.html#custom-error-pages-procedure
  # https://www.terraform.io/docs/providers/aws/r/cloudfront_distribution.html#custom-error-response-arguments
  type = list(object({
    error_caching_min_ttl = optional(number, null)
    error_code            = string
    response_code         = optional(number, null)
    response_page_path    = optional(string, null)
  }))

  description = "List of one or more custom error response element maps"
  default     = []
}

variable "lambda_function_association" {
  type = list(object({
    event_type   = string
    include_body = optional(bool, false)
    lambda_arn   = string
  }))

  description = "A config block that triggers a lambda@edge function with specific actions"
  default     = []
}

variable "function_association" {
  type = list(object({
    event_type   = string
    function_arn = string
  }))

  description = <<-EOT
    A config block that triggers a CloudFront function with specific actions.
    See the [aws_cloudfront_distribution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution#function-association)
    documentation for more information.
  EOT
  default     = []
}

variable "web_acl_id" {
  type        = string
  default     = ""
  description = "ID of the AWS WAF web ACL that is associated with the distribution"
}

variable "wait_for_deployment" {
  type        = bool
  default     = true
  description = "When set to 'true' the resource will wait for the distribution status to change from InProgress to Deployed"
}

variable "encryption_enabled" {
  type        = bool
  default     = true
  description = "When set to 'true' the resource will have aes256 encryption enabled by default"
}

variable "index_document" {
  type        = string
  default     = "index.html"
  description = "Amazon S3 returns this index document when requests are made to the root domain or any of the subfolders"
}

variable "redirect_all_requests_to" {
  type        = string
  default     = ""
  description = "A hostname to redirect all website requests for this distribution to. If this is set, it overrides other website settings"
}

variable "error_document" {
  type        = string
  default     = ""
  description = "An absolute path to the document to return in case of a 4XX error"
}

variable "routing_rules" {
  type        = string
  default     = ""
  description = "A json array containing routing rules describing redirect behavior and when redirects are applied"
}

variable "ipv6_enabled" {
  type        = bool
  default     = true
  description = "Set to true to enable an AAAA DNS record to be set as well as the A record"
}

variable "ordered_cache" {
  type = list(object({
    target_origin_id = string
    path_pattern     = string

    allowed_methods    = optional(list(string), ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"])
    cached_methods     = optional(list(string), ["GET", "HEAD"])
    compress           = optional(bool, false)
    trusted_signers    = optional(list(string), [])
    trusted_key_groups = optional(list(string), [])

    cache_policy_id          = optional(string, null)
    origin_request_policy_id = optional(string, null)
    realtime_log_config_arn  = optional(string, null)

    viewer_protocol_policy     = optional(string, "redirect-to-https")
    min_ttl                    = optional(number, 0)
    default_ttl                = optional(number, 60)
    max_ttl                    = optional(number, 31536000)
    response_headers_policy_id = optional(string, "")

    grpc_config = optional(object({
      enabled = bool
    }), { enabled = false })

    forward_query_string              = optional(bool, false)
    forward_header_values             = optional(list(string), [])
    forward_cookies                   = optional(string, "none")
    forward_cookies_whitelisted_names = optional(list(string), [])

    lambda_function_association = optional(list(object({
      event_type   = string
      include_body = optional(bool, false)
      lambda_arn   = string
    })), [])

    function_association = optional(list(object({
      event_type   = string
      function_arn = string
    })), [])
  }))
  default     = []
  description = <<-EOT
    An ordered list of [cache behaviors](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution#cache-behavior-arguments) resource for this distribution.
    List in order of precedence (first match wins). This is in addition to the default cache policy.
    Set `target_origin_id` to `""` to specify the S3 bucket origin created by this module.
    EOT
}

variable "custom_origins" {
  type = list(object({
    domain_name              = string
    origin_id                = string
    origin_path              = optional(string, "")
    origin_access_control_id = optional(string, null)
    custom_headers = optional(list(object({
      name  = string
      value = string
    })), [])
    custom_origin_config = object({
      http_port                = optional(number, 80)
      https_port               = optional(number, 443)
      origin_protocol_policy   = optional(string, "https-only")
      origin_ssl_protocols     = optional(list(string), ["TLSv1.2"])
      origin_keepalive_timeout = optional(number, 5)
      origin_read_timeout      = optional(number, 30)
    })
    origin_shield = optional(object({
      enabled = optional(bool, false)
      region  = optional(string, null)
    }), null)
  }))
  default     = []
  description = <<-EOT
    A list of additional custom website [origins](https://www.terraform.io/docs/providers/aws/r/cloudfront_distribution.html#origin-arguments) for this distribution.
    The `origin_access_control_id` field specifies the Origin Access Control configuration to use for this origin.
    This is used to configure secure access between CloudFront and the origin.
    EOT
}

variable "s3_origins" {
  type = list(object({
    domain_name              = string
    origin_id                = string
    origin_path              = optional(string, "")
    origin_access_control_id = optional(string, null)
    s3_origin_config = optional(object({
      origin_access_identity = string
    }), null)
    origin_shield_enabled = optional(bool, false)
  }))
  default     = []
  description = <<-EOT
    A list of S3 [origins](https://www.terraform.io/docs/providers/aws/r/cloudfront_distribution.html#origin-arguments) (in addition to the one created by this module) for this distribution.
    S3 buckets configured as websites are `custom_origins`, not `s3_origins`.
    Specifying `s3_origin_config.origin_access_identity` as `null` or `""` will have it translated to the `origin_access_identity` used by the origin created by the module.
    EOT
}

variable "website_enabled" {
  type        = bool
  default     = false
  description = <<-EOT
    Set to true to enable the created S3 bucket to serve as a website independently of Cloudfront,
    and to use that website as the origin. See the README for details and caveats. See also `s3_website_password_enabled`.
    EOT
}

variable "deployment_principal_arns" {
  type        = map(list(string))
  default     = {}
  description = <<-EOT
    (Optional) Map of IAM Principal ARNs to lists of S3 path prefixes to grant `deployment_actions` permissions.
    Resource list will include the bucket itself along with all the prefixes. Prefixes should not begin with '/'.
    EOT
}

variable "deployment_actions" {
  type        = list(string)
  default     = ["s3:PutObject", "s3:PutObjectAcl", "s3:GetObject", "s3:DeleteObject", "s3:ListBucket", "s3:ListBucketMultipartUploads", "s3:GetBucketLocation", "s3:AbortMultipartUpload"]
  description = "List of actions to permit `deployment_principal_arns` to perform on bucket and bucket prefixes (see `deployment_principal_arns`)"
}

variable "origin_access_type" {
  type        = string
  default     = "origin_access_identity"
  description = "Choose to use `origin_access_control` or `orgin_access_identity`"
  validation {
    condition     = var.origin_access_type == "origin_access_control" || var.origin_access_type == "origin_access_identity"
    error_message = "The origin_access_type must be `origin_access_control` or `origin_access_identity`."
  }
}

variable "cloudfront_origin_access_identity_iam_arn" {
  type        = string
  default     = ""
  description = "Existing cloudfront origin access identity iam arn that is supplied in the s3 bucket policy"
}

variable "cloudfront_origin_access_identity_path" {
  type        = string
  default     = ""
  description = "Existing cloudfront origin access identity path used in the cloudfront distribution's s3_origin_config content"
}

variable "custom_origin_headers" {
  type        = list(object({ name = string, value = string }))
  default     = []
  description = "A list of origin header parameters that will be sent to origin"
}

variable "origin_ssl_protocols" {
  type        = list(string)
  default     = ["TLSv1", "TLSv1.1", "TLSv1.2"]
  description = "The SSL/TLS protocols that you want CloudFront to use when communicating with your origin over HTTPS."
}

variable "origin_keepalive_timeout" {
  type        = number
  description = "The Custom KeepAlive timeout, in seconds. By default, AWS enforces a limit of 60. But you can request an increase."
  default     = 5
}

variable "origin_read_timeout" {
  type        = number
  description = "The Custom Read timeout, in seconds. By default, AWS enforces a limit of 60. But you can request an increase."
  default     = 30
}

variable "block_origin_public_access_enabled" {
  type        = bool
  default     = false
  description = "When set to 'true' the s3 origin bucket will have public access block enabled"
}

variable "s3_access_logging_enabled" {
  type        = bool
  default     = null
  description = <<-EOF
    Set `true` to deliver S3 Access Logs to the `s3_access_log_bucket_name` bucket.
    Defaults to `false` if `s3_access_log_bucket_name` is empty (the default), `true` otherwise.
    Must be set explicitly if the access log bucket is being created at the same time as this module is being invoked.
    EOF
}

variable "s3_access_log_bucket_name" {
  type        = string # diff hint
  default     = ""     # diff hint
  description = "Name of the existing S3 bucket where S3 Access Logs will be delivered. Default is not to enable S3 Access Logging."
}

variable "s3_access_log_prefix" {
  type        = string # diff hint
  default     = ""     # diff hint
  description = "Prefix to use for S3 Access Log object keys. Defaults to `logs/$${module.this.id}`"
}

variable "s3_object_ownership" {
  type        = string
  default     = "ObjectWriter"
  description = "Specifies the S3 object ownership control on the origin bucket. Valid values are `ObjectWriter`, `BucketOwnerPreferred`, and 'BucketOwnerEnforced'."
}

variable "cloudfront_access_logging_enabled" {
  type        = bool
  default     = true
  description = "Set true to enable delivery of Cloudfront Access Logs to an S3 bucket"
}

variable "cloudfront_access_log_create_bucket" {
  type        = bool
  default     = true
  description = <<-EOT
    When `true` and `cloudfront_access_logging_enabled` is also true, this module will create a new,
    separate S3 bucket to receive Cloudfront Access Logs.
    EOT
}

variable "extra_logs_attributes" {
  type        = list(string)
  default     = ["logs"]
  description = <<-EOT
    Additional attributes to add to the end of the generated Cloudfront Access Log S3 Bucket name.
    Only effective if `cloudfront_access_log_create_bucket` is `true`.
    EOT
}


variable "cloudfront_access_log_bucket_name" {
  type        = string # diff hint
  default     = ""     # diff hint
  description = <<-EOT
    When `cloudfront_access_log_create_bucket` is `false`, this is the name of the existing S3 Bucket where
    Cloudfront Access Logs are to be delivered and is required. IGNORED when `cloudfront_access_log_create_bucket` is `true`.
    EOT
}

variable "cloudfront_access_log_include_cookies" {
  type        = bool
  default     = false
  description = "Set true to include cookies in Cloudfront Access Logs"
}

variable "cloudfront_access_log_prefix" {
  type        = string # diff hint
  default     = ""     # diff hint
  description = "Prefix to use for Cloudfront Access Log object keys. Defaults to no prefix."
}

variable "distribution_enabled" {
  type        = bool
  default     = true
  description = "Set to `false` to create the distribution but still prevent CloudFront from serving requests."
}

variable "s3_website_password_enabled" {
  type        = bool
  default     = false
  description = <<-EOT
    If set to true, and `website_enabled` is also true, a password will be required in the `Referrer` field of the
    HTTP request in order to access the website, and Cloudfront will be configured to pass this password in its requests.
    This will make it much harder for people to bypass Cloudfront and access the S3 website directly via its website endpoint.
    EOT
}

variable "origin_groups" {
  type = list(object({
    primary_origin_id  = string
    failover_origin_id = string
    failover_criteria  = list(string)
  }))
  default     = []
  description = <<-EOT
    List of [Origin Groups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution#origin-group-arguments) to create in the distribution.
    The values of `primary_origin_id` and `failover_origin_id` must correspond to origin IDs existing in `var.s3_origins` or `var.custom_origins`.

    If `primary_origin_id` is set to `null` or `""`, then the origin id of the origin created by this module will be used in its place.
    This is to allow for the use case of making the origin created by this module the primary origin in an origin group.
  EOT
}

# Variables below here are DEPRECATED and should not be used anymore

variable "access_log_bucket_name" {
  type        = string
  default     = null
  description = "DEPRECATED. Use `s3_access_log_bucket_name` instead."
}

variable "logging_enabled" {
  type        = bool
  default     = null
  description = "DEPRECATED. Use `cloudfront_access_logging_enabled` instead."
}

variable "log_include_cookies" {
  type        = bool
  default     = null
  description = "DEPRECATED. Use `cloudfront_access_log_include_cookies` instead."
}

variable "log_prefix" {
  type        = string
  default     = null
  description = "DEPRECATED. Use `cloudfront_access_log_prefix` instead."
}

variable "realtime_log_config_arn" {
  type        = string
  default     = null
  description = "The ARN of the real-time log configuration that is attached to this cache behavior"
}

variable "allow_ssl_requests_only" {
  type        = bool
  default     = true
  description = "Set to `true` to require requests to use Secure Socket Layer (HTTPS/SSL). This will explicitly deny access to HTTP requests"
}

variable "origin_shield_enabled" {
  type        = bool
  default     = false
  description = "If enabled, origin shield will be enabled for the default origin"
}

variable "http_version" {
  type        = string
  default     = "http2"
  description = "The maximum HTTP version to support on the distribution. Allowed values are http1.1, http2, http2and3 and http3"
}

variable "bucket_versioning" {
  type        = string
  default     = "Disabled"
  description = "State of bucket versioning option"

  validation {
    condition     = contains(["Enabled", "Disabled", "Suspended"], var.bucket_versioning)
    error_message = "Please choose one of 'Enabled', 'Disabled', or 'Suspended'"
  }
}
