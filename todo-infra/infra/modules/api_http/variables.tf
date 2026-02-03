variable "name" { type = string }

variable "lambda_invoke_arn" { type = string }
variable "lambda_name" { type = string }

variable "routes" {
  type = list(object({
    method = string
    path   = string
  }))
}

variable "tags" { type = map(string), default = {} }
