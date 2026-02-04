data "aws_s3_bucket" "this" {
  bucket = var.name
}

output "bucket_id" {
  value = data.aws_s3_bucket.this.id
}

output "bucket_name" {
  value = data.aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  value = data.aws_s3_bucket.this.arn
}
