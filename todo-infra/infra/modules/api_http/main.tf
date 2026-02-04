resource "aws_apigatewayv2_api" "this" {
  name          = var.name
  protocol_type = "HTTP"

  # API aberta (sem auth) e sem dor de CORS
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["*"]
    max_age       = 86400
  }

  tags = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                  = aws_apigatewayv2_api.this.id
  integration_type        = "AWS_PROXY"
  integration_uri         = var.lambda_invoke_arn
  payload_format_version  = "2.0"
}

resource "aws_apigatewayv2_route" "routes" {
  for_each = { for r in var.routes : "${r.method} ${r.path}" => r }

  api_id    = aws_apigatewayv2_api.this.id
  route_key = "${each.value.method} ${each.value.path}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"

  lifecycle {
    prevent_destroy = true
  }
}

output "api_url" {
  value = aws_apigatewayv2_api.this.api_endpoint
}

output "api_id" {
  value = aws_apigatewayv2_api.this.id
}
