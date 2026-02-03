project    = "gestao-tarefas"
env        = "dev"
aws_region = "sa-east-1"

artifacts_bucket = "gestao-tarefas-dev-artifacts-calabria1-sa-east-1"

lambda_artifact_version = "latest"

# 7 nomes explícitos (case-friendly)
api_name               = "gestao-tarefas-dev-api"
lambda_function_name   = "gestao-tarefas-dev-tarefas-handler"
dynamodb_table_name    = "gestao-tarefas-dev-tarefas"
iam_role_name          = "gestao-tarefas-dev-lambda-exec-role"
iam_policy_name        = "gestao-tarefas-dev-lambda-dynamodb-policy"
log_group_name = "/aws/lambda/gestao-tarefas-dev-tarefas-handler"
