variable "project" {
  type        = string
  description = "Nome do projeto"
}

variable "env" {
  type        = string
  description = "Ambiente (dev, hom, prod)"
}

variable "aws_region" {
  type        = string
  description = "Regiao AWSs"
}

variable "artifacts_bucket" {
  type        = string
  description = "Bucket S3 para artefatos (zip da lambda) - JA EXISTE"
}

variable "lambda_artifact_version" {
  type        = string
  description = "Versao do artefato da Lambda (ex: latest ou sha curta)"
}
