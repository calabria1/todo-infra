variable "function_name" { type = string }
variable "runtime" { type = string }
variable "handler" { type = string }

variable "s3_bucket" { type = string }
variable "s3_key" { type = string }

variable "env_vars" { type = map(string), default = {} }
variable "dynamodb_table_arn" { type = string }

variable "tags" { type = map(string), default = {} }
