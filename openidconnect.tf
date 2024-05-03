
resource "local_file" "openidconnect_secrets" {
  count    = local.create_openidconnect_auth ? 1 : 0
  filename = "${path.module}/openidconnect/lambda/config.json"
  content = templatefile("${path.module}/openidconnect/config.json.tpl", {
    openidconnect_client_id           = var.openidconnect_client_id
    openidconnect_jwt_secret          = var.openidconnect_jwt_secret
    openidconnect_tenant_id           = var.openidconnect_tenant_id
    openidconnect_client_secret       = var.openidconnect_client_secret
    openidconnect_domain              = var.openidconnect_domain
    openidconnect_timeout_ms          = var.openidconnect_timeout_ms
    openidconnect_auth_cookie_name    = var.openidconnect_auth_cookie_name
    openidconnect_auth_cookie_ttl_sec = var.openidconnect_auth_cookie_ttl_sec
    openidconnect_role                = var.openidconnect_role
  })
  provisioner "local-exec" {
    command = "cd ${path.module}/openidconnect/lambda/ && npm install --only=prod"
  }
}

data "archive_file" "openidconnect_archive" {
  count       = local.create_openidconnect_auth ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/openidconnect/lambda"
  output_path = "${path.module}/openidconnect.zip"
  depends_on  = [local_file.openidconnect_secrets]
}

resource "aws_lambda_function" "openidconnect" {
  count            = local.create_openidconnect_auth ? 1 : 0
  provider         = aws.us-east-1
  function_name    = module.this.id
  role             = aws_iam_role.auth_lambda[0].arn
  filename         = data.archive_file.openidconnect_archive[0].output_path
  source_code_hash = data.archive_file.openidconnect_archive[0].output_base64sha256
  runtime          = "nodejs20.x"
  handler          = "index.auth"
  publish          = true
  tracing_config {
    mode = "PassThrough"
  }
}

resource "aws_iam_role" "auth_lambda" {
  count = local.create_openidconnect_auth ? 1 : 0
  name  = "${module.this.id}-auth-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
        }
      },
    ]
  })
  inline_policy {
    name = "cwlogs"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
          Effect   = "Allow"
          Resource = "arn:aws:logs:*:*:*"
        },
      ]
    })
  }
}

