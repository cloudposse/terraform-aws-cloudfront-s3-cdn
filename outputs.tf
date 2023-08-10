output "cf_id" {
  value       = try(aws_cloudfront_distribution.default[0].id, "")
  description = "ID of AWS CloudFront distribution"
}

output "cf_arn" {
  value       = try(aws_cloudfront_distribution.default[0].arn, "")
  description = "ARN of AWS CloudFront distribution"
}

output "cf_status" {
  value       = try(aws_cloudfront_distribution.default[0].status, "")
  description = "Current status of the distribution"
}

output "cf_domain_name" {
  value       = try(aws_cloudfront_distribution.default[0].domain_name, "")
  description = "Domain name corresponding to the distribution"
}

output "cf_etag" {
  value       = try(aws_cloudfront_distribution.default[0].etag, "")
  description = "Current version of the distribution's information"
}

output "cf_hosted_zone_id" {
  value       = try(aws_cloudfront_distribution.default[0].hosted_zone_id, "")
  description = "CloudFront Route 53 zone ID"
}

output "cf_identity_iam_arn" {
  value       = try(aws_cloudfront_origin_access_identity.default[0].iam_arn, "")
  description = "CloudFront Origin Access Identity IAM ARN"
}

output "cf_origin_groups" {
  value       = try(flatten(aws_cloudfront_distribution.default[*].origin_group), [])
  description = "List of Origin Groups in the CloudFront distribution."
}

output "cf_primary_origin_id" {
  value       = local.origin_id
  description = "The ID of the origin created by this module."
}

output "cf_origin_ids" {
  value       = try(aws_cloudfront_distribution.default[0].origin[*].origin_id, [])
  description = "List of Origin IDs in the CloudFront distribution."
}

output "cf_s3_canonical_user_id" {
  value       = try(aws_cloudfront_origin_access_identity.default[0].s3_canonical_user_id, "")
  description = "Canonical user ID for CloudFront Origin Access Identity"
}

output "s3_bucket" {
  value       = local.bucket
  description = "Name of origin S3 bucket"
}

output "s3_bucket_domain_name" {
  value       = local.bucket_domain_name
  description = "Domain of origin S3 bucket"
}

output "s3_bucket_arn" {
  value       = local.origin_bucket.arn
  description = "ARN of origin S3 bucket"
}

output "s3_bucket_policy" {
  value       = join("", aws_s3_bucket_policy.default[*].policy)
  description = "Final computed S3 bucket policy"
}

output "logs" {
  value       = module.logs
  description = "Log bucket resource"
}

output "aliases" {
  value       = var.aliases
  description = "Aliases of the CloudFront distribution."
}
