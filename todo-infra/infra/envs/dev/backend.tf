terraform {
  backend "s3" {
    # TODO: preencha:
    # bucket         = "SEU_BUCKET_STATE"
    # key            = "todo/dev/terraform.tfstate"
    # region         = "sa-east-1"
    # dynamodb_table = "SEU_LOCK_TABLE" # opcional, recomendado
    # encrypt        = true
  }
}
