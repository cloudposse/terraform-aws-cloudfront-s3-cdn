variable "region" {
  description = "The AWS region this distribution should reside in."
}

variable "parent_zone_name" {
  description = "The name of the parent Route53 zone to use for the distribution."
  type        = string
}

variable "additional_custom_origins_enabled" {
  type        = bool
  description = "Whether or not to enable additional custom origins."
  default     = false
}

variable "additional_s3_origins_enabled" {
  type        = bool
  description = "Whether or not to enable additional s3 origins."
  default     = false
}

variable "origin_group_failover_criteria_status_codes" {
  type        = list(string)
  description = "List of HTTP Status Codes to use as the failover criteria for origin groups."
  default = [
    403,
    404,
    500,
    502
  ]
}

variable "lambda_at_edge_enabled" {
  type        = bool
  description = "Whether or not to enable Lambda@Edge functions."
  default     = false
}
