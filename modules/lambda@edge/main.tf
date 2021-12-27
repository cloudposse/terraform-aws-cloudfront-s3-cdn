locals {
  enabled   = module.this.enabled
  functions = local.enabled ? var.functions : {}
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
  version = "0.14.0"

  use_fullname       = true
  policy_description = "Allow ${module.function_label[each.key].id} Write CloudWatch Logs"
  role_description   = "IAM role for ${module.function_label[each.key].id}"

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
  filename         = data.archive_file.lambda_zip[each.key].output_path
  source_code_hash = data.archive_file.lambda_zip[each.key].output_base64sha256
  publish          = true
}

resource "aws_lambda_permission" "allow_cloudfront" {
  for_each = local.functions

  function_name = aws_lambda_function.default[each.key].function_name
  statement_id  = "AllowExecutionFromCloudFront"
  action        = "lambda:GetFunction"
  principal     = "edgelambda.amazonaws.com"
}