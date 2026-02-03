terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  name = "${var.project}-${var.env}"

  tags = {
    project    = var.project
    env        = var.env
    managed_by = "terraform"
  }
}

# =========================================
# S3 Bucket para Artefatos
# =========================================
module "artifacts" {
  source = "../../modules/s3"

  name = var.artifacts_bucket
  tags = local.tags
}

# =========================================
# DynamoDB Table
# =========================================
module "dynamodb" {
  source = "../../modules/dynamodb"

  name         = "${local.name}-tasks"
  billing_mode = "PAY_PER_REQUEST"
  tags         = local.tags
}

# =========================================
# Lambda Function
# =========================================
module "lambda_tasks" {
  source = "../../modules/lambda"

  function_name = "${local.name}-tasks"
  runtime       = "python3.11"
  handler       = "handler.lambda_handler"

  s3_bucket = module.artifacts.bucket_id
  s3_key    = "lambdas/tasks/${var.lambda_artifact_version}.zip"

  env_vars = {
    TABLE_NAME = module.dynamodb.table_name
    ENV        = var.env
  }

  dynamodb_table_arn = module.dynamodb.table_arn
  tags               = local.tags
}

# =========================================
# API Gateway HTTP
# =========================================
module "api" {
  source = "../../modules/api_http"

  name               = "${local.name}-api"
  lambda_invoke_arn  = module.lambda_tasks.invoke_arn
  lambda_name        = module.lambda_tasks.function_name

  routes = [
    { method = "POST",   path = "/tasks" },
    { method = "GET",    path = "/tasks" },
    { method = "GET",    path = "/tasks/{id}" },
    { method = "PUT",    path = "/tasks/{id}" },
    { method = "DELETE", path = "/tasks/{id}" }
  ]

  tags = local.tags
}

# =========================================
# Outputs
# =========================================
output "api_url" {
  description = "Url da API"
  value       = module.api.api_url
}

output "dynamodb_table_name" {
  description = "Nome da tabela DynamoDB"
  value       = module.dynamodb.table_name
}

output "lambda_function_name" {
  description = "Nome da funcao Lambda"
  value       = module.lambda_tasks.function_name
}

output "artifacts_bucket" {
  description = "Nome do bucket S3 de artefatos"
  value       = module.artifacts.bucket_id
}
