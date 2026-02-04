# ---------- Rotas ----------
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

# (opcional) proxy e options — pode manter
resource "aws_apigatewayv2_route" "proxy" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "options" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "OPTIONS /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# ---------- Deployment forçado (pra não “ficar preso” em cache) ----------
resource "aws_apigatewayv2_deployment" "this" {
  api_id = aws_apigatewayv2_api.api.id

  triggers = {
    redeploy = sha1(join(",", [
      aws_apigatewayv2_route.post_tarefas.id,
      aws_apigatewayv2_route.get_tarefas.id,
      aws_apigatewayv2_route.get_tarefa_id.id,
      aws_apigatewayv2_route.put_tarefa_id.id,
      aws_apigatewayv2_route.delete_tarefa_id.id
    ]))
  }

  depends_on = [
    aws_apigatewayv2_integration.lambda,
    aws_apigatewayv2_route.post_tarefas,
    aws_apigatewayv2_route.get_tarefas,
    aws_apigatewayv2_route.get_tarefa_id,
    aws_apigatewayv2_route.put_tarefa_id,
    aws_apigatewayv2_route.delete_tarefa_id,
    aws_apigatewayv2_route.proxy,
    aws_apigatewayv2_route.options
  ]
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true

  deployment_id = aws_apigatewayv2_deployment.this.id

  tags = local.tags
}
