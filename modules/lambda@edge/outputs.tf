output "lambda_function_association" {
  description = "TODO"
  value = [
    for k, v in local.functions : {
      event_type   = v.event_type
      include_body = v.include_body
      lambda_arn   = aws_lambda_function.default[k].qualified_arn
    }
  ]
}