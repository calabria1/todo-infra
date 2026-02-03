provider "aws" {
  region = var.aws_region
}

# ---------- S3 Artifacts ----------
resource "aws_s3_bucket" "artifacts" {
  bucket = var.artifacts_bucket
}

# ---------- DynamoDB ----------
resource "aws_dynamodb_table" "tarefas" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# ---------- IAM ----------
data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = var.iam_role_name
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Scan"
    ]
    resources = [aws_dynamodb_table.tarefas.arn]
  }
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = var.iam_policy_name
  role   = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.lambda_policy.json
}

# ---------- Lambda ----------
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = var.log_group_name
  retention_in_days = 14
}

resource "aws_lambda_function" "tarefas" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_role.arn
  runtime       = "python3.11"
  handler       = "handler.lambda_handler"

  s3_bucket = aws_s3_bucket.artifacts.bucket
  s3_key    = "lambdas/tasks/${var.lambda_artifact_version}.zip"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.tarefas.name
    }
  }
}

# ---------- API Gateway ----------
resource "aws_apigatewayv2_api" "api" {
  name          = var.api_name
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.tarefas.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "tarefas" {
  for_each = toset([
    "POST /tarefas",
    "GET /tarefas",
    "GET /tarefas/{id}",
    "PUT /tarefas/{id}",
    "DELETE /tarefas/{id}"
  ])

  api_id    = aws_apigatewayv2_api.api.id
  route_key = each.value
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_lambda_permission" "api" {
  statement_id  = "AllowInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tarefas.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

output "api_url" {
  value = aws_apigatewayv2_api.api.api_endpoint
}
