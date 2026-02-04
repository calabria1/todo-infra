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

  tags = local.tags
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
      "dynamodb:Scan"
    ]
    resources = [aws_dynamodb_table.tarefas.arn]
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
  integration_uri        = aws_lambda_function.tarefas.invoke_arn
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
# ---------- Rotas (explícitas + fallback) ----------
resource "aws_apigatewayv2_route" "post_tarefas" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /tarefas"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "get_tarefas" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /tarefas"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "get_tarefa_id" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /tarefas/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "put_tarefa_id" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "PUT /tarefas/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "delete_tarefa_id" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "DELETE /tarefas/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Fallback: qualquer coisa abaixo de /tarefas/ vai pra lambda
resource "aws_apigatewayv2_route" "proxy_tarefas" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "ANY /tarefas/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# CORS preflight
resource "aws_apigatewayv2_route" "options_proxy" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "OPTIONS /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# ---------- Deployment forçado (garante publicação das rotas) ----------
resource "aws_apigatewayv2_deployment" "this" {
  api_id = aws_apigatewayv2_api.api.id

  triggers = {
    redeploy = sha1(join(",", [
      aws_apigatewayv2_route.post_tarefas.id,
      aws_apigatewayv2_route.get_tarefas.id,
      aws_apigatewayv2_route.get_tarefa_id.id,
      aws_apigatewayv2_route.put_tarefa_id.id,
      aws_apigatewayv2_route.delete_tarefa_id.id,
      aws_apigatewayv2_route.proxy_tarefas.id,
      aws_apigatewayv2_route.options_proxy.id
    ]))
  }

  depends_on = [
    aws_apigatewayv2_integration.lambda,
    aws_apigatewayv2_route.post_tarefas,
    aws_apigatewayv2_route.get_tarefas,
    aws_apigatewayv2_route.get_tarefa_id,
    aws_apigatewayv2_route.put_tarefa_id,
    aws_apigatewayv2_route.delete_tarefa_id,
    aws_apigatewayv2_route.proxy_tarefas,
    aws_apigatewayv2_route.options_proxy
  ]
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true

  deployment_id = aws_apigatewayv2_deployment.this.id

  tags = local.tags
}