terraform {
  backend "s3" {
    # Configured via terraform init -backend-config:
    #   bucket         = "my-tf-state-bucket"
    #   key            = "opencord/terraform.tfstate"
    #   region         = "us-east-1"
    #   dynamodb_table = "tf-lock-table"
    #   encrypt        = true
  }
}
