# Date: 6/11/2023
# 2-Tier architecture project using Terraform
# This is a Terraform configuration file
# written by Do Hyung Kim
terraform {
  backend "local" { # setting default local backend
    path = "terraform.tfstate"
  }
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0" #"~> 3.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "2.1.0" #"3.3.0" #
    }
    # random = {
    #   source  = "hashicorp/random"
    #   version = "3.1.0"
    # }
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

# For s3 backend with enabling to lock s3 backend
# terraform {
#   backend "s3" {
#     ## Create S3 bucket and validate Terraform Configuration and 
#     ## Validate State on S3
#     bucket = "my-tf-project15-0891ca570c7af7dc3317dcdc591cce07"
#     key    = "apache_server/aws_infrastructure"
#     region = "us-east-1"
#   }
# }
# DynamoDB table for enabling locking for S3 backend
# DynamoDB table name: terraform-lock
# ID: LockID
# dynamodb_table = "terraform-locks"
# encrypt        = true

