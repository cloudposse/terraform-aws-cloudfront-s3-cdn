## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| acm_certificate_arn | Existing ACM Certificate ARN | string | `` | no |
| aliases | List of FQDN's - Used to set the Alternate Domain Names (CNAMEs) setting on Cloudfront | list | `<list>` | no |
| allowed_methods | List of allowed methods (e.g. GET, PUT, POST, DELETE, HEAD) for AWS CloudFront | list | `<list>` | no |
| attributes | Additional attributes (e.g. `1`) | list | `<list>` | no |
| bucket_domain_format | Format of bucket domain name | string | `%s.s3.amazonaws.com` | no |
| cached_methods | List of cached methods (e.g. GET, PUT, POST, DELETE, HEAD) | list | `<list>` | no |
| comment | Comment for the origin access identity | string | `Managed by Terraform` | no |
| compress | Compress content for web requests that include Accept-Encoding: gzip in the request header | string | `false` | no |
| cors_allowed_headers | List of allowed headers for S3 bucket | list | `<list>` | no |
| cors_allowed_methods | List of allowed methods (e.g. GET, PUT, POST, DELETE, HEAD) for S3 bucket | list | `<list>` | no |
| cors_allowed_origins | List of allowed origins (e.g. example.com, test.com) for S3 bucket | list | `<list>` | no |
| cors_expose_headers | List of expose header in the response for S3 bucket | list | `<list>` | no |
| cors_max_age_seconds | Time in seconds that browser can cache the response for S3 bucket | string | `3600` | no |
| custom_error_response | List of one or more custom error response element maps | list | `<list>` | no |
| default_root_object | Object that CloudFront return when requests the root URL | string | `index.html` | no |
| default_ttl | Default amount of time (in seconds) that an object is in a CloudFront cache | string | `60` | no |
| delimiter | Delimiter to be used between `namespace`, `stage`, `name` and `attributes` | string | `-` | no |
| enabled | Select Enabled if you want CloudFront to begin processing requests as soon as the distribution is created, or select Disabled if you do not want CloudFront to begin processing requests after the distribution is created. | string | `true` | no |
| forward_cookies | Time in seconds that browser can cache the response for S3 bucket | string | `none` | no |
| forward_header_values | A list of whitelisted header values to forward to the origin | list | `<list>` | no |
| forward_query_string | Forward query strings to the origin that is associated with this cache behavior | string | `false` | no |
| geo_restriction_locations | List of country codes for which  CloudFront either to distribute content (whitelist) or not distribute your content (blacklist) | list | `<list>` | no |
| geo_restriction_type | Method that use to restrict distribution of your content by country: `none`, `whitelist`, or `blacklist` | string | `none` | no |
| is_ipv6_enabled | State of CloudFront IPv6 | string | `true` | no |
| lambda_function_association | A config block that triggers a lambda function with specific actions | list | `<list>` | no |
| log_expiration_days | Number of days after which to expunge the objects | string | `90` | no |
| log_glacier_transition_days | Number of days after which to move the data to the glacier storage tier | string | `60` | no |
| log_include_cookies | Include cookies in access logs | string | `false` | no |
| log_prefix | Path of logs in S3 bucket | string | `` | no |
| log_standard_transition_days | Number of days to persist in the standard storage tier before moving to the glacier tier | string | `30` | no |
| max_ttl | Maximum amount of time (in seconds) that an object is in a CloudFront cache | string | `31536000` | no |
| min_ttl | Minimum amount of time that you want objects to stay in CloudFront caches | string | `0` | no |
| minimum_protocol_version | Cloudfront TLS minimum protocol version | string | `TLSv1` | no |
| name | Name  (e.g. `bastion` or `app`) | string | - | yes |
| namespace | Namespace (e.g. `eg` or `cp`) | string | - | yes |
| null | an empty string | string | `` | no |
| origin_bucket | Name of S3 bucket | string | `` | no |
| origin_force_destroy | Delete all objects from the bucket  so that the bucket can be destroyed without error (e.g. `true` or `false`) | string | `false` | no |
| origin_path | An optional element that causes CloudFront to request your content from a directory in your Amazon S3 bucket or your custom origin. It must begin with a /. Do not add a / at the end of the path. | string | `` | no |
| parent_zone_id | ID of the hosted zone to contain this record  (or specify `parent_zone_name`) | string | `` | no |
| parent_zone_name | Name of the hosted zone to contain this record (or specify `parent_zone_id`) | string | `` | no |
| price_class | Price class for this distribution: `PriceClass_All`, `PriceClass_200`, `PriceClass_100` | string | `PriceClass_100` | no |
| stage | Stage (e.g. `prod`, `dev`, `staging`) | string | - | yes |
| static_s3_bucket | aws-cli is a bucket owned by amazon that will perminantly exist. It allows for the data source to be called during the destruction process without failing. It doesn't get used for anything else, this is a safe workaround for handling the fact that if a data source like the one `aws_s3_bucket.selected` gets an error, you can't continue the terraform process which also includes the 'destroy' command, where is doesn't even need this data source! Don't change this bucket name, it's a variable so that we can provide this description. And this works around a problem that is an edge case. | string | `aws-cli` | no |
| tags | Additional tags (e.g. map(`BusinessUnit`,`XYZ`) | map | `<map>` | no |
| trusted_signers | The AWS accounts, if any, that you want to allow to create signed URLs for private content. 'self' is acceptable. | list | `<list>` | no |
| use_regional_s3_endpoint | When set to 'true' the s3 origin_bucket will use the regional endpoint address instead of the global endpoint address | string | `false` | no |
| viewer_protocol_policy | allow-all, redirect-to-https | string | `redirect-to-https` | no |
| web_acl_id | ID of the AWS WAF web ACL that is associated with the distribution | string | `` | no |

## Outputs

| Name | Description |
|------|-------------|
| cf_arn | ARN of AWS CloudFront distribution |
| cf_domain_name | Domain name corresponding to the distribution |
| cf_etag | Current version of the distribution's information |
| cf_hosted_zone_id | CloudFront Route 53 zone ID |
| cf_id | ID of AWS CloudFront distribution |
| cf_status | Current status of the distribution |
| s3_bucket | Name of S3 bucket |
| s3_bucket_domain_name | Domain of S3 bucket |

