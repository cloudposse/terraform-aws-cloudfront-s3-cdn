resource "aws_route53_zone" "venom_cloud" {
  name = local.domain_name

  tags = {
    "Environment" = "${local.env}"
  }
}