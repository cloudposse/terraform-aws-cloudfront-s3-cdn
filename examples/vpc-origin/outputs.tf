output "cdn_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = module.cdn.cf_domain_name
}

output "cdn_id" {
  description = "ID of the CloudFront distribution"
  value       = module.cdn.cf_id
}

output "vpc_origin_id" {
  description = "ID of the CloudFront VPC origin"
  value       = aws_cloudfront_vpc_origin.this.id
}

output "alb_dns_name" {
  description = "DNS name of the internal ALB used as the VPC origin"
  value       = aws_lb.internal.dns_name
}
