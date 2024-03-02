locals {
  enabled                   = module.this.enabled
  destruction_delay_enabled = local.enabled && try(length(var.destruction_delay), 0) > 0
  functions                 = local.enabled ? var.functions : {}
}

# Lambda@Edge functions are replicated and cannot be destroyed immediately.
# If var.destruction_delay is set to null or "", no delay will be introduced.
# You may or may not want to introduce this delay to your projects, but this delay is necessary for automated tests.
# See: https://github.com/hashicorp/terraform-provider-aws/issues/1721
resource "time_sleep" "lambda_at_edge_destruction_delay" {
  for_each = local.destruction_delay_enabled ? aws_lambda_function.default : {}

  destroy_duration = var.destruction_delay

  # Any changes to the ARN of the functions will result in a destruction delay.
  triggers = {
    arn = each.value.arn
  }
}

module "function_label" {
  for_each = local.functions

  source  = "cloudposse/label/null"
  version = "0.25.0"

  attributes = [each.key]

  context = module.this.context
}

data "aws_iam_policy_document" "lambda_write_logs" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}

module "role" {
  for_each = local.functions

  source  = "cloudposse/iam-role/aws"
  version = "0.19.0"

  use_fullname       = true
  policy_description = "Allow ${module.function_label[each.key].id} Lambda function to write to CloudWatch Logs"
  role_description   = "IAM role for ${module.function_label[each.key].id} Lambda function"

  principals = {
    Service = [
      "lambda.amazonaws.com",
      "edgelambda.amazonaws.com"
    ]
  }

  policy_documents = [
    data.aws_iam_policy_document.lambda_write_logs.json,
  ]

  context = module.function_label[each.key].context
}

resource "aws_lambda_function" "default" {
  #bridgecrew:skip=BC_AWS_GENERAL_64:Lambda@Edge functions associated with CF distributions do not support DLQs.
  #bridgecrew:skip=BC_AWS_SERVERLESS_4:Lambda@Edge functions do not support X-Ray tracing.
  #bridgecrew:skip=BC_AWS_GENERAL_65:Lambda@Edge functions cannot be configured for connectivity inside a VPC.
  #bridgecrew:skip=BC_AWS_GENERAL_63:Lambda@Edge functions cannot be configured for reserved concurrency.
  for_each = local.functions

  function_name    = module.function_label[each.key].id
  runtime          = each.value.runtime
  handler          = each.value.handler
  role             = module.role[each.key].arn
  filename         = each.value.source_zip != null ? data.local_file.lambda_zip[each.key].filename : data.archive_file.lambda_zip[each.key].output_path
  source_code_hash = each.value.source_zip != null ? sha256(data.local_file.lambda_zip[each.key].content_base64) : data.archive_file.lambda_zip[each.key].output_base64sha256
  publish          = true
}

resource "aws_lambda_permission" "allow_cloudfront" {
  for_each = local.functions

  function_name = aws_lambda_function.default[each.key].function_name
  statement_id  = "AllowExecutionFromCloudFront"
  action        = "lambda:GetFunction"
  principal     = "edgelambda.amazonaws.com"
}