output "cf_id" {
  value       = module.cloudfront_s3_cdn.cf_id
  description = "ID of AWS CloudFront distribution"
}

output "cf_arn" {
  value       = module.cloudfront_s3_cdn.cf_arn
  description = "ARN of AWS CloudFront distribution"
}

output "cf_status" {
  value       = module.cloudfront_s3_cdn.cf_status
  description = "Current status of the distribution"
}

output "cf_domain_name" {
  value       = module.cloudfront_s3_cdn.cf_domain_name
  description = "Domain name corresponding to the distribution"
}

output "cf_etag" {
  value       = module.cloudfront_s3_cdn.cf_etag
  description = "Current version of the distribution's information"
}

output "cf_hosted_zone_id" {
  value       = module.cloudfront_s3_cdn.cf_hosted_zone_id
  description = "CloudFront Route 53 zone ID"
}

output "cf_identity_iam_arn" {
  value       = module.cloudfront_s3_cdn.cf_identity_iam_arn
  description = "CloudFront Origin Access Identity IAM ARN"
}

output "cf_origin_groups" {
  value       = module.cloudfront_s3_cdn.cf_origin_groups
  description = "List of Origin Groups in the CloudFront distribution."
}

output "cf_origin_ids" {
  value       = module.cloudfront_s3_cdn.cf_origin_ids
  description = "List of Origin IDs in the CloudFront distribution."
}

output "cf_s3_canonical_user_id" {
  value       = module.cloudfront_s3_cdn.cf_s3_canonical_user_id
  description = "Canonical user ID for CloudFront Origin Access Identity"
}

output "s3_bucket" {
  value       = module.cloudfront_s3_cdn.s3_bucket
  description = "Name of S3 bucket"
}

output "s3_bucket_domain_name" {
  value       = module.cloudfront_s3_cdn.s3_bucket_domain_name
  description = "Domain of S3 bucket"
}

output "s3_bucket_policy" {
  value       = module.cloudfront_s3_cdn.s3_bucket_policy
  description = "Final computed S3 bucket policy"
}

output "lambda_function_association" {
  description = "The Lambda@Edge function association configuration."
  value       = module.lambda_at_edge.lambda_function_association
}
