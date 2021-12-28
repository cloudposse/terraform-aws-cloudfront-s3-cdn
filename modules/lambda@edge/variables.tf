variable "functions" {
  description = <<-EOT
  Lambda@Edge functions to create.

  The key of this map is the name label of the Lambda@Edge function.

  `source.filename` and `source.content` dictate the name and content of the files that will make up the Lambda function
  source, respectively.

  `runtime` and `handler` correspond to the attributes of the same name in the [lambda_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function)
  resource.

  `event_type` and `include_body` correspond to the attributes of the same name in the [Lambda Function association block
  of the cloudfront_distribution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution#lambda-function-association)
  resource.
  EOT
  type = map(object({
    source = list(object({
      filename = string
      content  = string
    }))
    runtime      = string
    handler      = string
    event_type   = string
    include_body = bool
  }))
}

variable "destruction_delay" {
  type        = string
  description = <<-EOT
  The delay, in [Golang ParseDuration](https://pkg.go.dev/time#ParseDuration) format, to wait before destroying the Lambda@Edge
  functions.

  This delay is meant to circumvent Lambda@Edge functions not being immediately deletable following their dissociation from
  a CloudFront distribution, since they are replicated to CloudFront Edge servers around the world.

  If set to `null`, no delay will be introduced.

  By default, the delay is 20 minutes. This is because it takes about 3 minutes to destroy a CloudFront distribution, and
  around 15 minutes until the Lambda@Edge function is available for deletion, in most cases.

  For more information, see: https://github.com/hashicorp/terraform-provider-aws/issues/1721.
  EOT
  default     = "20m"
}