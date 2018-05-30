output "cf_id" {
  value = "${module.cdn.cf_id}"
}

output "cf_arn" {
  value = "${module.cdn.cf_arn}"
}

output "cf_status" {
  value = "${module.cdn.cf_status}"
}

output "cf_domain_name" {
  value = "${module.cdn.cf_domain_name}"
}

output "cf_etag" {
  value = "${module.cdn.cf_etag}"
}

output "cf_hosted_zone_id" {
  value = "${module.cdn.cf_hosted_zone_id}"
}

output "s3_bucket" {
  value = "${module.cdn.s3_bucket}"
}

output "s3_bucket_domain_name" {
  value = "${module.cdn.s3_bucket_domain_name}"
}
