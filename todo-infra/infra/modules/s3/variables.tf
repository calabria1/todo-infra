variable "name" {
  type        = string
  description = "Nome do bucket S3"
}

variable "tags" {
  type        = map(string)
  description = "Tags para o bucket"
  default     = {}
}
