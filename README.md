# tf_cdn

Terraform module to easily provision CloudFront CDN with an S3 or custom origin.

## Usage

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
