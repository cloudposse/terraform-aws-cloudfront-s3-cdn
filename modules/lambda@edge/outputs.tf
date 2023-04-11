output "lambda_function_association" {
  description = "The Lambda@Edge function association configuration to pass to `var.lambda_function_association` in the parent module."
  value = [
    for k, v in local.functions : {
      event_type   = v.event_type
      include_body = v.include_body
      lambda_arn   = aws_lambda_function.default[k].qualified_arn
    }
  ]
}

output "lambda_functions" {
  description = "The Lambda@Edge functions"
  value = {
    for key, value in local.functions : key => {
      arn           = aws_lambda_function.default[key].arn,
      qualified_arn = aws_lambda_function.default[key].qualified_arn,
      role_arn      = aws_lambda_function.default[key].role
    }
  }
}
