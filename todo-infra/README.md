# todo-infra (Terraform + GitHub Actions)

Provisiona a infra inteira na AWS:
- S3 (artefatos da Lambda)
- DynamoDB (tasks)
- Lambda (aponta para zip no S3)
- API Gateway HTTP API (aberta, sem auth)
- IAM (role/policy para lambda)
- CloudWatch Logs (via AWS padrão)

> Você vai preencher alguns valores (bucket names/estado/backend) e depois rodar via GitHub Actions.

## Pré-requisitos
- Terraform 1.6+
- AWS region (ex: sa-east-1)
- OIDC GitHub Actions já configurado (role ARN nos secrets)

## Como usar
1) Configure os **Secrets** no GitHub:
- `AWS_ROLE_ARN`
- `AWS_REGION`

2) Ajuste `infra/envs/dev/terraform.tfvars` (bucket/state/nomes)

3) Rode o workflow `terraform.yml` (plan/apply) ou local:
```bash
cd infra/envs/dev
terraform init
terraform plan
terraform apply
```

## Se a infra já existir na AWS
Se os recursos já foram criados anteriormente (e o state local não existe mais),
o workflow do GitHub Actions faz um **import best-effort** antes do `plan/apply`
para reaproveitar a infra existente e só aplicar mudanças reais.

Se preferir rodar localmente, você pode importar manualmente:

```bash
cd infra/envs/dev
terraform init
terraform import module.artifacts.aws_s3_bucket.this <nome-do-bucket>
terraform import module.dynamodb.aws_dynamodb_table.this <nome-da-tabela>
terraform import module.lambda_tasks.aws_iam_role.this <nome-da-role>
terraform import module.lambda_tasks.aws_lambda_function.this <nome-da-lambda>
terraform import module.api.aws_apigatewayv2_api.this <id-da-api>
terraform import module.api.aws_apigatewayv2_stage.default <id-da-api>/$default
terraform import module.api.aws_apigatewayv2_integration.lambda <id-da-api>/<id-da-integracao>
terraform import module.api.aws_apigatewayv2_route.routes["GET /tasks"] <id-da-api>/<id-da-rota>
terraform import module.api.aws_apigatewayv2_route.routes["POST /tasks"] <id-da-api>/<id-da-rota>
terraform import module.api.aws_apigatewayv2_route.routes["GET /tasks/{id}"] <id-da-api>/<id-da-rota>
terraform import module.api.aws_apigatewayv2_route.routes["PUT /tasks/{id}"] <id-da-api>/<id-da-rota>
terraform import module.api.aws_apigatewayv2_route.routes["DELETE /tasks/{id}"] <id-da-api>/<id-da-rota>
terraform import module.api.aws_lambda_permission.allow_apigw <lambda-name>/AllowExecutionFromAPIGateway
```

## Integração com o repo todo-api
O workflow de infra **clona o repo todo-api**, builda o zip e envia pro S3.
Depois o Terraform atualiza a Lambda usando `s3_bucket` + `s3_key`.
