module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 3.0"

  domain_name         = local.domain_name
  zone_id             = aws_route53_zone.venom_cloud.id
  wait_for_validation = true

  tags = {
    Name = "wildcard.${local.env}.${local.domain_name}"
  }
}