provider "aws" {
  region = var.region
}

locals {
  vpc_origin_id      = "${module.this.id}-alb"
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
}

# -----------------------------------------------------------------------------
# Private origin: an internal ALB reachable only through a CloudFront VPC origin
# -----------------------------------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = merge(module.this.tags, { Name = module.this.id })
}

# CloudFront requires an internet gateway attached to the VPC, but it does not
# use it to route traffic to the origin and the private subnets need no route to it.
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(module.this.tags, { Name = module.this.id })
}

resource "aws_subnet" "private" {
  for_each = toset(local.availability_zones)

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.value
  cidr_block              = cidrsubnet(aws_vpc.this.cidr_block, 8, index(local.availability_zones, each.value))
  map_public_ip_on_launch = false

  tags = merge(module.this.tags, { Name = "${module.this.id}-${each.value}" })
}

resource "aws_security_group" "alb" {
  name_prefix = "${module.this.id}-"
  vpc_id      = aws_vpc.this.id

  tags = module.this.tags
}

resource "aws_vpc_security_group_egress_rule" "alb_all_outbound" {
  security_group_id = aws_security_group.alb.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = module.this.tags
}

# CloudFront creates this service-managed security group in the VPC when the
# first VPC origin is deployed. The origin security group must allow it in.
data "aws_security_group" "cloudfront_vpc_origins" {
  vpc_id = aws_vpc.this.id
  name   = "CloudFront-VPCOrigins-Service-SG"

  depends_on = [aws_cloudfront_vpc_origin.this]
}

resource "aws_vpc_security_group_ingress_rule" "alb_from_cloudfront_vpc_origins" {
  security_group_id            = aws_security_group.alb.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = data.aws_security_group.cloudfront_vpc_origins.id

  tags = module.this.tags
}

resource "aws_lb" "internal" {
  name               = module.this.id
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = values(aws_subnet.private)[*].id

  tags = module.this.tags
}

resource "aws_lb_target_group" "internal" {
  name     = module.this.id
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.this.id

  tags = module.this.tags
}

resource "aws_lb_listener" "internal" {
  load_balancer_arn = aws_lb.internal.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal.arn
  }
}

# -----------------------------------------------------------------------------
# CloudFront VPC origin, deliberately managed outside the CDN module
# -----------------------------------------------------------------------------

resource "aws_cloudfront_vpc_origin" "this" {
  vpc_origin_endpoint_config {
    name                   = module.this.id
    arn                    = aws_lb.internal.arn
    http_port              = 80
    https_port             = 443
    origin_protocol_policy = "http-only"

    origin_ssl_protocols {
      items    = ["TLSv1.2"]
      quantity = 1
    }
  }

  tags = module.this.tags

  depends_on = [aws_internet_gateway.this]
}

# -----------------------------------------------------------------------------
# S3-backed CDN with an additional cache behavior routed to the VPC origin
# -----------------------------------------------------------------------------

module "cdn" {
  source = "../../"

  origin_force_destroy                = true
  cloudfront_access_logging_enabled   = var.logging_enabled
  cloudfront_access_log_create_bucket = var.logging_enabled

  custom_origins = [{
    domain_name = aws_lb.internal.dns_name
    origin_id   = local.vpc_origin_id
    vpc_origin_config = {
      vpc_origin_id = aws_cloudfront_vpc_origin.this.id
    }
  }]

  ordered_cache = [{
    target_origin_id = local.vpc_origin_id
    path_pattern     = "/private/*"
  }]

  context = module.this.context

  depends_on = [aws_vpc_security_group_ingress_rule.alb_from_cloudfront_vpc_origins]
}
