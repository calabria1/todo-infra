terraform {
  backend "s3" {
    bucket  = "gestao-tarefas-dev-artifacts-calabria1-sa-east-1"
    key     = "terraform/dev/terraform.tfstate"
    region  = "sa-east-1"
    encrypt = true
  }
}
