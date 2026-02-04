resource "aws_dynamodb_table" "this" {
  name         = var.name
  billing_mode = var.billing_mode
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "criado_por"
    type = "S"
  }

  attribute {
    name = "data_criacao"
    type = "S"
  }

  global_secondary_index {
    name            = "criado_por-index"
    hash_key        = "criado_por"
    range_key       = "data_criacao"
    projection_type = "ALL"
  }

  point_in_time_recovery { enabled = true }

  tags = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

output "table_name" { value = aws_dynamodb_table.this.name }
output "table_arn"  { value = aws_dynamodb_table.this.arn }
