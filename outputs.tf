output "cf_id" {
  value = "${aws_cloudfront_distribution.cf.id}"
}

output "cf_arn" {
  value = "${aws_cloudfront_distribution.cf.arn}"
}

output "cf_status" {
  value = "${aws_cloudfront_distribution.cf.status}"
}

output "cf_domain_name" {
  value = "${aws_cloudfront_distribution.cf.domain_name}"
}

output "cf_etag" {
  value = "${aws_cloudfront_distribution.cf.etag}"
}

output "cf_hosted_zone_id" {
  value = "${aws_cloudfront_distribution.cf.hosted_zone_id}"
}

output "s3_bucket" {
  value = "${aws_s3_bucket.origin.bucket}"
}

output "s3_bucket_arn" {
  value = "${aws_s3_bucket.origin.arn}"
}
