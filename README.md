# tf_cdn_s3

Terraform module to easily provision CloudFront CDN with an S3 or custom origin.

## Usage

### Generating ACM Certificate

Use the AWS cli to [request new ACM certifiates](http://docs.aws.amazon.com/acm/latest/userguide/gs-acm-request.html) (requires email validation)
```
aws acm request-certificate --domain-name example.com --subject-alternative-names a.example.com b.example.com *.c.example.com
```


## Variables

|  Name                        |  Default       |  Description                                            | Required |
|:-----------------------------|:--------------:|:--------------------------------------------------------|:--------:|
| namespace                    | ``             | Namespace (e.g. `cp` or `cloudposse`)                   | Yes      |
| stage                        | ``             | Stage (e.g. `prod`, `dev`, `staging`)                   | Yes      |
| name                         | ``             | Name  (e.g. `bastion` or `db`)                          | Yes      | 
| attributes                   | []             | Additional attributes (e.g. `policy` or `role`)         | No       | 
| tags                         | {}             | Additional tags  (e.g. `map("BusinessUnit","XYZ")`      | No       |

## Outputs

| Name              | Decription            |
|:------------------|:----------------------|
| id                | Disambiguated ID      |


## Known Issues

If the bucket is creatd in a region other than `us-east-1`, it will take a while for the distribution to become fully operational.

> All buckets have at least two REST endpoint hostnames. In eu-west-1, they are example-bucket.s3-eu-west-1.amazonaws.com and example-bucket.s3.amazonaws.com. The first one will be immediately valid when the bucket is created. The second one -- sometimes referred to as the "global endpoint" -- which is the one CloudFront uses -- will not, unless the bucket is in us-east-1. Over a period of seconds to minutes, variable by location and other factors, it becomes globally accessible as well. Before that, the 307 redirect is returned. Hence, the bucket was not ready.

Via: https://stackoverflow.com/questions/38706424/aws-cloudfront-returns-http-307-when-origin-is-s3-bucket
 
