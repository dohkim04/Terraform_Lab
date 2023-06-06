# Lesson Section 49. Terraform State Migration 
# use default local backend 
#-> move to s3 backend 
#-> move to remote backend 
#-> move to local backend

terraform {
  #Task1: # No backend setting => Use Terraform's default local backend
  #Task4: go back from remote back end to the default local backend 

  #Task2: 
  # backend "s3" {
  #   bucket         = "my-terraform-state-dhk"
  #   key            = "prod/aws_infra"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }

  #Task3:
  # backend "remote" {
  #   hostname     = "app.terraform.io"
  #   organization = "devops-test-2364" #"Enterprise-Cloud"
  #   workspaces {
  #     name = "my-aws-app"
  #   }
  # }
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