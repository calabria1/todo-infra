variable "name" { type = string }
variable "billing_mode" { type = string, default = "PAY_PER_REQUEST" }
variable "tags" { type = map(string), default = {} }
