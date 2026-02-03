variable "name" {
  type        = string
  description = "Nome da API"
}

variable "lambda_invoke_arn" {
  type        = string
  description = "ARN de invocacao da Lambda"
}

variable "lambda_name" {
  type        = string
  description = "Nome da funcao Lambda"
}

variable "routes" {
  type = list(object({
    method = string
    path   = string
  }))
  description = "Lista de rotas da API"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags para o recurso"
}
