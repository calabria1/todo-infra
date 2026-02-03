variable "name" {
  type = string
  description = "Nome da tabela DynamoDB"
}

variable "billing_mode" {
  type    = string
  default = "PAY_PER_REQUEST"
  description = "modo de cobranca (PAY_PER_REQUEST ou PROVISIONED)"
}

variable "tags" {
  type    = map(string)
  default = {}
  description = "Tags para o recurso"
}
