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
    source      = list(object({
      filename = string
      content  = string
    }))
    runtime      = string
    handler      = string
    event_type   = string
    include_body = bool
  }))
}