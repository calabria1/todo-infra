# todo-infra (Terraform + GitHub Actions)

Provisiona a infra inteira na AWS:
- S3 (artefatos da Lambda)
- DynamoDB (tasks)
- Lambda (aponta para zip no S3)
- API Gateway HTTP API (aberta, sem auth)
- IAM (role/policy para lambda)
- CloudWatch Logs (via AWS padrão)

> Você vai preencher alguns valores (bucket names/estado/backend) e depois rdodar via GitHub Actions.

## Pré-requisitos
- Terraform 14s.6+
- AWS region (ex: sa-east-1)
- OIDC GitHub Actions já configurado (role ARN nos secrets)

## Como usar
1) Configure os **Secrets** no GitHub (Actions):
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

### Opção 2 (recomendada): importar recursos no state sem apagar nada
Essa opção aproveita o que já existe na AWS e recria o state local.

**Passo A — criar o state local**
```bash
cd infra/envs/dev
terraform init
```

**Passo B — importar cada recurso existente**

S3 (bucket + public access block + versioning):
```bash
terraform import module.artifacts.aws_s3_bucket.this <nome-do-bucket>
terraform import module.artifacts.aws_s3_bucket_public_access_block.this <nome-do-bucket>
terraform import module.artifacts.aws_s3_bucket_versioning.this <nome-do-bucket>
```

DynamoDB (tabela):
```bash
terraform import module.dynamodb.aws_dynamodb_table.this <nome-da-tabela>
```

IAM (role + policy da Lambda):
```bash
terraform import module.lambda_tasks.aws_iam_role.this <nome-da-role>
terraform import module.lambda_tasks.aws_iam_role_policy.this <nome-da-role>:<nome-da-policy>
```

> Se você também precisar importar Lambda e API Gateway, mantenha os imports abaixo
> (opcional, conforme o que já existir na conta):
```bash
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
O workflow de infra empacota a Lambda localmente (em `services/tasks`)
e envia o zip para o S3. Depois o Terraform atualiza a Lambda usando
`s3_bucket` + `s3_key` com o SHA do commit.
