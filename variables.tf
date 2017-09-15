variable "name" {}
variable "namespace" {}
variable "stage" {}

variable "tags" {
  default = {}
}

variable "delimiter" {
  default = "-"
}

variable "enabled" {
  default = "true"
}

variable "acm_certificate_arn" {
  description = "Existing ACM Certificate ARN"
  default     = ""
}

variable "aliases" {
  type    = "list"
  default = []
}

variable "origin_bucket" {
  default = ""
}

variable "origin_path" {
  default = "/"
}

variable "compress" {
  default = "false"
}

variable "is_ipv6_enabled" {
  default = "true"
}

variable "default_root_object" {
  default = "index.html"
}

variable "comment" {
  default = "Managed by Terraform"
}

variable "log_include_cookies" {
  default = "false"
}

variable "log_prefix" {
  default = ""
}

variable "log_standard_transition_days" {
  description = "Number of days to persist in the standard storage tier before moving to the glacier tier"
  default     = "30"
}

variable "log_glacier_transition_days" {
  description = "Number of days after which to move the data to the glacier storage tier"
  default     = "60"
}

variable "log_expiration_days" {
  description = "Number of days after which to expunge the objects"
  default     = "90"
}

variable "forward_query_string" {
  default = "false"
}

variable "forward_cookies" {
  default = "none"
}

variable "price_class" {
  default = "PriceClass_100"
}

variable "viewer_protocol_policy" {
  description = "allow-all, redirect-to-https"
  default     = "redirect-to-https"
}

variable "allowed_methods" {
  type    = "list"
  default = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
}

variable "cached_methods" {
  type    = "list"
  default = ["GET", "HEAD"]
}

variable "default_ttl" {
  default = "60"
}

variable "min_ttl" {
  default = "0"
}

variable "max_ttl" {
  default = "31536000"
}

variable "geo_restriction_type" {
  # e.g. "whitelist"
  default = "none"
}

variable "geo_restriction_locations" {
  type = "list"

  # e.g. ["US", "CA", "GB", "DE"]
  default = []
}

variable "default_error_object" {
  default = "404.html"
}

variable "allowed_headers" {
  type    = "list"
  default = ["*"]
}

variable "expose_headers" {
  type    = "list"
  default = ["ETag"]
}

variable "max_age_seconds" {
  default = "3000"
}

variable "dns_zone_id" {
  default = ""
}
