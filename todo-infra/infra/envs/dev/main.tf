provider "aws" {
  region = var.aws_region
}

locals {
  prefix = "${var.project}-${var.env}"

  tags = {
    project    = var.project
    env        = var.env
    managed_by = "terraform"
  }
}

# ---------- S3 Artifacts (JA EXISTE) ----------
data "aws_s3_bucket" "artifacts" {
  bucket = var.artifacts_bucket
}

# ---------- DynamoDB ----------
resource "aws_dynamodb_table" "tarefas" {
  name         = "${local.prefix}-tarefas"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "criado_por"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "data_criacao"
    type = "S"
  }

  global_secondary_index {
    name            = "criado_por-index"
    hash_key        = "criado_por"
    range_key       = "data_criacao"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "status-index"
    hash_key        = "status"
    range_key       = "data_criacao"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "all_tasks-index"
    hash_key        = "pk"
    range_key       = "data_criacao"
    projection_type = "ALL"
  }

  point_in_time_recovery { enabled = true }

  tags = local.tags

  lifecycle {
    prevent_destroy = true
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
  name               = "${local.prefix}-lambda-exec-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = local.tags
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
      "dynamodb:Query"
    ]
    resources = [
      aws_dynamodb_table.tarefas.arn,
      "${aws_dynamodb_table.tarefas.arn}/index/*"
    ]
  }
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "${local.prefix}-lambda-dynamodb-policy"
  role   = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.lambda_policy.json
}

# ---------- CloudWatch Logs ----------
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${local.prefix}-tarefas-handler"
  retention_in_days = 14
  tags              = local.tags
}

# ---------- Lambda ----------
resource "aws_lambda_function" "tarefas" {
  function_name = "${local.prefix}-tarefas-handler"
  role          = aws_iam_role.lambda_role.arn
  runtime       = "python3.11"
  handler       = "handler.lambda_handler"

  s3_bucket = data.aws_s3_bucket.artifacts.bucket
  s3_key    = "lambdas/tasks/${var.lambda_artifact_version}.zip"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.tarefas.name
    }
  }

  tags = local.tags
}

# ---------- API Gateway HTTP ----------
resource "aws_apigatewayv2_api" "api" {
  name          = "${local.prefix}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["*"]
    max_age       = 86400
  }

  tags = local.tags
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.tarefas.arn}/invocations"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "tarefas" {
  for_each = toset([
    "POST /tarefas",
    "GET /tarefas",
    "GET /tarefas/{id}",
    "PUT /tarefas/{id}",
    "DELETE /tarefas/{id}",
    "OPTIONS /{proxy+}"
  ])

  api_id    = aws_apigatewayv2_api.api.id
  route_key = each.value
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# ✅ stage obrigatório pra HTTP API publicar rotas
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
  tags        = local.tags
}

resource "aws_lambda_permission" "allow_invoke" {
  statement_id  = "AllowInvokeFromHttpApi"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tarefas.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

output "api_url" {
  value = aws_apigatewayv2_api.api.api_endpoint
}
