## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| acm_certificate_arn | Existing ACM Certificate ARN | string | `` | no |
| additional_bucket_policy | Additional policies for the bucket. If included in the policies, the variables `$${bucket_name}`, `$${origin_path}` and `$${cloudfront_origin_access_identity_iam_arn}` will be substituted. It is also possible to override the default policy statements by providing statements with `S3GetObjectForCloudFront` and `S3ListBucketForCloudFront` sid. | string | `{}` | no |
| aliases | List of FQDN's - Used to set the Alternate Domain Names (CNAMEs) setting on Cloudfront | list(string) | `<list>` | no |
| allowed_methods | List of allowed methods (e.g. GET, PUT, POST, DELETE, HEAD) for AWS CloudFront | list(string) | `<list>` | no |
| attributes | Additional attributes (e.g. `1`) | list(string) | `<list>` | no |
| bucket_domain_format | Format of bucket domain name | string | `%s.s3.amazonaws.com` | no |
| cached_methods | List of cached methods (e.g. GET, PUT, POST, DELETE, HEAD) | list(string) | `<list>` | no |
| comment | Comment for the origin access identity | string | `Managed by Terraform` | no |
| compress | Compress content for web requests that include Accept-Encoding: gzip in the request header | bool | `false` | no |
| cors_allowed_headers | List of allowed headers for S3 bucket | list(string) | `<list>` | no |
| cors_allowed_methods | List of allowed methods (e.g. GET, PUT, POST, DELETE, HEAD) for S3 bucket | list(string) | `<list>` | no |
| cors_allowed_origins | List of allowed origins (e.g. example.com, test.com) for S3 bucket | list(string) | `<list>` | no |
| cors_expose_headers | List of expose header in the response for S3 bucket | list(string) | `<list>` | no |
| cors_max_age_seconds | Time in seconds that browser can cache the response for S3 bucket | number | `3600` | no |
| custom_error_response | List of one or more custom error response element maps | object | `<list>` | no |
| default_root_object | Object that CloudFront return when requests the root URL | string | `index.html` | no |
| default_ttl | Default amount of time (in seconds) that an object is in a CloudFront cache | number | `60` | no |
| delimiter | Delimiter to be used between `namespace`, `stage`, `name` and `attributes` | string | `-` | no |
| enabled | Select Enabled if you want CloudFront to begin processing requests as soon as the distribution is created, or select Disabled if you do not want CloudFront to begin processing requests after the distribution is created. | bool | `true` | no |
| encryption_enabled | When set to 'true' the resource will have aes256 encryption enabled by default | bool | `false` | no |
| error_document | An absolute path to the document to return in case of a 4XX error | string | `` | no |
| extra_logs_attributes | Additional attributes to put onto the log bucket label | list(string) | `<list>` | no |
| extra_origin_attributes | Additional attributes to put onto the origin label | list(string) | `<list>` | no |
| forward_cookies | Specifies whether you want CloudFront to forward all or no cookies to the origin. Can be 'all' or 'none' | string | `none` | no |
| forward_header_values | A list of whitelisted header values to forward to the origin | list(string) | `<list>` | no |
| forward_query_string | Forward query strings to the origin that is associated with this cache behavior | bool | `false` | no |
| geo_restriction_locations | List of country codes for which  CloudFront either to distribute content (whitelist) or not distribute your content (blacklist) | list(string) | `<list>` | no |
| geo_restriction_type | Method that use to restrict distribution of your content by country: `none`, `whitelist`, or `blacklist` | string | `none` | no |
| index_document | Amazon S3 returns this index document when requests are made to the root domain or any of the subfolders | string | `index.html` | no |
| ipv6_enabled | Set to true to enable an AAAA DNS record to be set as well as the A record | bool | `true` | no |
| lambda_function_association | A config block that triggers a lambda function with specific actions | object | `<list>` | no |
| log_expiration_days | Number of days after which to expunge the objects | number | `90` | no |
| log_glacier_transition_days | Number of days after which to move the data to the glacier storage tier | number | `60` | no |
| log_include_cookies | Include cookies in access logs | bool | `false` | no |
| log_prefix | Path of logs in S3 bucket | string | `` | no |
| log_standard_transition_days | Number of days to persist in the standard storage tier before moving to the glacier tier | number | `30` | no |
| logging_enabled | When true, access logs will be sent to a newly created s3 bucket | bool | `true` | no |
| max_ttl | Maximum amount of time (in seconds) that an object is in a CloudFront cache | number | `31536000` | no |
| min_ttl | Minimum amount of time that you want objects to stay in CloudFront caches | number | `0` | no |
| minimum_protocol_version | Cloudfront TLS minimum protocol version | string | `TLSv1` | no |
| name | Name  (e.g. `bastion` or `app`) | string | - | yes |
| namespace | Namespace (e.g. `eg` or `cp`) | string | `` | no |
| ordered_cache | An ordered list of cache behaviors resource for this distribution. List from top to bottom in order of precedence. The topmost cache behavior will have precedence 0. The fields can be described by the other variables in this file. For example, the field 'lambda_function_association' in this object has a description in var.lambda_function_association variable earlier in this file. The only difference is that fields on this object are in ordered caches, whereas the rest of the vars in this file apply only to the default cache. | object | `<list>` | no |
| origin_bucket | Origin S3 bucket name | string | `` | no |
| origin_force_destroy | Delete all objects from the bucket so that the bucket can be destroyed without error (e.g. `true` or `false`) | bool | `false` | no |
| origin_path | An optional element that causes CloudFront to request your content from a directory in your Amazon S3 bucket or your custom origin. It must begin with a /. Do not add a / at the end of the path. | string | `` | no |
| override_origin_bucket_policy | When using an existing origin bucket (through var.origin_bucket), setting this to 'false' will make it so the existing bucket policy will not be overriden | bool | `true` | no |
| parent_zone_id | ID of the hosted zone to contain this record  (or specify `parent_zone_name`) | string | `` | no |
| parent_zone_name | Name of the hosted zone to contain this record (or specify `parent_zone_id`) | string | `` | no |
| price_class | Price class for this distribution: `PriceClass_All`, `PriceClass_200`, `PriceClass_100` | string | `PriceClass_100` | no |
| redirect_all_requests_to | A hostname to redirect all website requests for this distribution to. If this is set, it overrides other website settings | string | `` | no |
| routing_rules | A json array containing routing rules describing redirect behavior and when redirects are applied | string | `` | no |
| stage | Stage (e.g. `prod`, `dev`, `staging`) | string | `` | no |
| static_s3_bucket | aws-cli is a bucket owned by amazon that will perminantly exist. It allows for the data source to be called during the destruction process without failing. It doesn't get used for anything else, this is a safe workaround for handling the fact that if a data source like the one `aws_s3_bucket.selected` gets an error, you can't continue the terraform process which also includes the 'destroy' command, where is doesn't even need this data source! Don't change this bucket name, it's a variable so that we can provide this description. And this works around a problem that is an edge case. | string | `aws-cli` | no |
| tags | Additional tags (e.g. map(`BusinessUnit`,`XYZ`) | map(string) | `<map>` | no |
| trusted_signers | The AWS accounts, if any, that you want to allow to create signed URLs for private content. 'self' is acceptable. | list(string) | `<list>` | no |
| use_regional_s3_endpoint | When set to 'true' the s3 origin_bucket will use the regional endpoint address instead of the global endpoint address | bool | `false` | no |
| viewer_protocol_policy | allow-all, redirect-to-https | string | `redirect-to-https` | no |
| wait_for_deployment | When set to 'true' the resource will wait for the distribution status to change from InProgress to Deployed | bool | `true` | no |
| web_acl_id | ID of the AWS WAF web ACL that is associated with the distribution | string | `` | no |
| website_enabled | Set to true to use an S3 static website as origin | bool | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| aliases | Aliases of the CloudFront distibution |
| cf_arn | ARN of AWS CloudFront distribution |
| cf_domain_name | Domain name corresponding to the distribution |
| cf_etag | Current version of the distribution's information |
| cf_hosted_zone_id | CloudFront Route 53 zone ID |
| cf_id | ID of AWS CloudFront distribution |
| cf_status | Current status of the distribution |
| s3_bucket | Name of S3 bucket |
| s3_bucket_domain_name | Domain of S3 bucket |

