locals {
  domain = "symbiotes.org"
  env    = "development"
  # Removes trailing dot from domain
  domain_name = trimsuffix(local.domain, ".")
  s3_origin_id = "CDNS3Origin"
}
