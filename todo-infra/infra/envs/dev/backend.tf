# Backend S3 para persistir o state do Terraform
# IMPORTANTE: O bucket deve existir ANTES de rodar terraform init
# Crie manualmente via AWS Console ou CLI uma unica vez

terraform {
  backend "s3" {
    bucket  = "todo-calabrial-artifacts-123"
    key     = "tfstate/dev/terraform.tfstate"
    region  = "sa-east-1"
    encrypt = true

    # Opcional: tabela DynamoDB para lock (evita conflitos em deploys simultaneos)
    # dynamodb_table = "terraform-locks"
  }
}