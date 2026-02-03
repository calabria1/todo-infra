project    = "todo"
env        = "dev"
aws_region = "sa-east-1"

# bucket S3 onde vamos guardar o zip da lambda (artefatos)
artifacts_bucket = "todo-calabria1-artifacts-123"

# versão do zip que o Terraform vai procurar no S3
# por enquanto fixo; depois o workflow passa o SHA do commit
lambda_artifact_version = "dev"

# repo da API (owner/repo) — usado pelo pipeline quando formos buildar e zipar
api_repo = "calabria1/todo-api"
