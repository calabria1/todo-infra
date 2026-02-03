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

## Integração com o repo todo-api
O workflow de infra **clona o repo todo-api**, builda o zip e envia pro S3.
Depois o Terraform atualiza a Lambda usando `s3_bucket` + `s3_key`.
