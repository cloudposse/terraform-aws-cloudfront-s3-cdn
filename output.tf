output "cf_id" {
  value       = module.venom_cloud.cf_id
  description = "ID of AWS CloudFront distribution"
}

output "cf_arn" {
  value       = module.venom_cloud.cf_arn
  description = "ARN of AWS CloudFront distribution"
}

output "cf_status" {
  value       = module.venom_cloud.cf_status
  description = "Current status of the distribution"
}

output "cf_domain_name" {
  value       = module.venom_cloud.cf_domain_name
  description = "Domain name corresponding to the distribution"
}

output "cf_etag" {
  value       = module.venom_cloud.cf_etag
  description = "Current version of the distribution's information"
}

output "cf_hosted_zone_id" {
  value       = module.venom_cloud.cf_hosted_zone_id
  description = "CloudFront Route 53 zone ID"
}

output "cf_identity_iam_arn" {
  value       = module.venom_cloud.cf_identity_iam_arn
  description = "CloudFront Origin Access Identity IAM ARN"
}

output "cf_origin_groups" {
  value       = module.venom_cloud.cf_origin_groups
  description = "List of Origin Groups in the CloudFront distribution."
}

output "cf_origin_ids" {
  value       = module.venom_cloud.cf_origin_ids
  description = "List of Origin IDs in the CloudFront distribution."
}

output "cf_s3_canonical_user_id" {
  value       = module.venom_cloud.cf_s3_canonical_user_id
  description = "Canonical user ID for CloudFront Origin Access Identity"
}

output "s3_bucket" {
  value       = module.venom_cloud.s3_bucket
  description = "Name of S3 bucket"
}

output "s3_bucket_domain_name" {
  value       = module.venom_cloud.s3_bucket_domain_name
  description = "Domain of S3 bucket"
}

output "aws_acm_certificate__development_athliance_co_arn" {
  value = module.acm.acm_certificate_arn
}

output "validation_domains" {
  description = "List of distinct domain validation options. This is useful if subject alternative names contain wildcards."
  value       = module.acm.validation_domains
}

output "validation_route53_record_fqdns" {
  description = "List of FQDNs built using the zone domain and name."
  value       = module.acm.validation_route53_record_fqdns
}