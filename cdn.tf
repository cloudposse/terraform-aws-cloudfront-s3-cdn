
module "venom_cloud" {
  source = "cloudposse/cloudfront-s3-cdn/aws"
  # version                  = don't mind me not pinning versions to this module
  namespace           = local.domain_name
  stage               = local.env
  name                = "s3"
  encryption_enabled  = true
  parent_zone_id      = aws_route53_zone.venom_cloud.id
  acm_certificate_arn = module.acm.acm_certificate_arn
  aliases             = [local.domain_name]
  ipv6_enabled        = true
  default_ttl         = 300
  compress            = true
  website_enabled     = true
  dns_alias_enabled = true
#   s3_website_password_enabled = true 
  index_document      = "index.html" # absolute path in the S3 bucket
  error_document      = "error.html" # absolute path in the S3 bucket

  tags = {
    "Environment" = "Dev"
  }
}