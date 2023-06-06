terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "2.1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.1.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.1.0"
    }
  }
}
# # For s3 backend with enabling to lock s3 backend
# # terraform {
# #   backend "s3" {
# #     ## Create S3 bucket and validate Terraform Configuration and 
# #     ## Validate State on S3
# #     bucket = "my-terraform-state-dhk"
# #     key    = "prod/aws_infra"
# #     region = "us-east-1"

# #     # DynamoDB table for enabling locking for S3 backend
# #     #DynamoDB table name: terraform-lock, ID: LockID
# #     dynamodb_table = "terraform-locks"
# #     encrypt        = true
# #   }
# # }

# # Only one backend is allowed for terraform.tf
# # HTTP backend!
# terraform {
#   backend "http" {
#     address        = "http://localhost:5000/terraform_state/4cdd0c76-d78b-11e9-9bea-db9cd8374f3a"
#     lock_address   = "http://localhost:5000/terraform_lock/4cdd0c76-d78b-11e9-9bea-db9cd8374f3a"
#     lock_method    = "PUT"
#     unlock_address = "http://localhost:5000/terraform_lock/4cdd0c76-d78b-11e9-9bea-db9cd8374f3a"
#     unlock_method  = "DELETE"
#   }
# }


terraform { # Remote Backend (Terraform Cloud) also works with Terraform Enterprise as well
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "devops-test-2364" # "YOUR-ORGANIZATION"
    workspaces { # save our state into Terraform Cloud workspace
      name = "my-aws-app"
    }
  }
}
/*
Set up environment variable for AWS access
*/