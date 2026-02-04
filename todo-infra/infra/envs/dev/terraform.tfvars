project    = "gestao-tarefas"
env        = "dev"
aws_region = "sa-east-1"

# bucket S3 onde ficam os artefatos (zip da lambda) - já existente
artifacts_bucket = "gestao-tarefas-dev-artifacts-calabria1-sa-east-1"

# versionamento do artefato (o workflow manda ${sha:0:7} ou latest)
lambda_artifact_version = "latest"
