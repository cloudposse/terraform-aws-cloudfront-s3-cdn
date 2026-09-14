variable "region" {
  type        = string
  description = "AWS region"
}

variable "logging_enabled" {
  type        = bool
  default     = false
  description = "When true, CloudFront access logs are sent to a newly created S3 bucket"
}
