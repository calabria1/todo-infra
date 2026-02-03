variable "function_name" {
  type = string
  description = "Nome da funcao Lambda"
}

variable "runtime" {
  type = string
  description = "Runtime da Lambda (ex: python3.11)"
}

variable "handler" {
  type = string
  description = "Handler da Lambda (ex: handler.lambda_handler)"
}

variable "s3_bucket" {
  type = string
  description = "Bucket S3 onde o zip da Lambda esta armazenado"
}

variable "s3_key" {
  type = string
  description = "Chave do objeto S3 onde o zip da Lambda esta armazenado"
}

variable "env_vars" {
  type    = map(string)
  default = {}
  description = "Variaveis de ambiente para a Lambda"
}

variable "dynamodb_table_arn" {
  type = string
  description = "ARN da tabela DynamoDB usada pela Lambda"  
}
variable "timeout" {
  type        = number
  default     = 10
  description = "Timeout da funcao Lambda em segundos"
}
variable "memory_size" {
  type        = number
  default     = 256
  description = "Memoria alocada para a funcao Lambda em MB"
}

variable "tags" {
  type    = map(string)
  default = {}
  description = "Tags para o recurso"
}
