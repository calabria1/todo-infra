variable "project" { type = string }
variable "env" { type = string }
variable "aws_region" { type = string }

# Artefatos (zip da lambda)
variable "artifacts_bucket" { type = string }

# Passado pelo pipeline (ex: commit SHA)
variable "lambda_artifact_version" { type = string }

# Repo da API para clonar no workflow (owner/repo)
variable "api_repo" { type = string }
