resource "aws_dynamodb_table" "this" {
  name         = var.name
  billing_mode = var.billing_mode
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  point_in_time_recovery { enabled = true }

  tags = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

output "table_name" { value = aws_dynamodb_table.this.name }
output "table_arn"  { value = aws_dynamodb_table.this.arn }
