project    = "gestao-tarefas"
env        = "dev"
aws_region = "sa-east-1"

# bucket ja existente (nao criar pelo terraform)
artifacts_bucket = "gestao-tarefas-dev-artifacts-calabria1-sa-east-1"

# o workflow do todo-api sobe latest.zip e também ${sha}.zip
lambda_artifact_version = "latest"
