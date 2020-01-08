output "cf_id" {
  value       = aws_cloudfront_distribution.default.id
  description = "ID of AWS CloudFront distribution"
}

output "cf_arn" {
  value       = aws_cloudfront_distribution.default.arn
  description = "ARN of AWS CloudFront distribution"
}

output "cf_status" {
  value       = aws_cloudfront_distribution.default.status
  description = "Current status of the distribution"
}

output "cf_domain_name" {
  value       = aws_cloudfront_distribution.default.domain_name
  description = "Domain name corresponding to the distribution"
}

output "cf_etag" {
  value       = aws_cloudfront_distribution.default.etag
  description = "Current version of the distribution's information"
}

output "cf_hosted_zone_id" {
  value       = aws_cloudfront_distribution.default.hosted_zone_id
  description = "CloudFront Route 53 zone ID"
}

output "s3_bucket" {
  value       = local.bucket
  description = "Name of S3 bucket"
}

output "s3_bucket_domain_name" {
  value       = local.bucket_domain_name
  description = "Domain of S3 bucket"
}

output "aliases" {
  value       = var.aliases
  description = "Aliases of the CloudFront distibution"
}
