# terraform {
#   backend "s3" {
#     bucket = "my-tf-state-project-fortstack-bucket"
#     key    = "tfstate"
#     region = "us-east-1"
#     dynamodb_table = "terraform-lock-state-table"
#   }
# }
