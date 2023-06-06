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
#Explicit a backend
# (1) Full Terraform State Configuration with local backend
# Execute $ terraform init 
# terraform {
#   backend "local" {
#     path = "terraform.tfstate"
#   }
# }
####################################
# (2) local backend partial configuration 
# -> dev_local.hcl (path ="terraform.dev.tfstate"), 
# -> test_local.hcl (terraform.test.tfstate), 
# terraform init -backend-config=state_configuration/dev_local.hcl -migrate-state
# terraform init -backend-config=state_configuration/test_local.hcl -migrate-state
# -> command line directly indicating "path=terraform.prod.tfstate"
# terraform init -backend-config="path=terraform.prod.tfstate"
# Always make sure to execute terraform plan and terraform apply (apply will pull out TF state!! update tfstate file)
#######################################
# (3) Full Terraform State Configuration with S3 backend
# terraform {
#   backend "s3" {
#     bucket = "my-terraform-state-dhk"
#     key    = "dev/aws_infra"
#     region = "us-east-1"
#   }
# }
# then execute => terraform init -migrate-state
###########################################
# (4) Partical Terraform State Configuration with S3 bucket
# using ***.hcl file
# terraform {
#   backend "s3" {}
# }
# example 4-1
# dev-s3-state.hcl to specify where to save TF state
#    bucket = "my-terraform-state-dhk"
#    key = "dev/aws_infra1"
#    region = "us-east-1"
# then execute => terraform init -backend-config=state_configuration/dev-s3-state.hcl -migrate-state
######################################
# example 4-2
# partial configuration with terraform.tf and
# s3-state-bucket.hcl 
#    bucket="my-terraform-state-dhk" 
#    region = "us-east-1"
# dev-s3-state-key.hcl
#    key ="dev/aws_infra2"
# then execute
# terraform init -backend-config=state_configuration/s3-state-bucket.hcl \
# -backend-config=state_configuration/dev-s3-state-key.hcl \
# -migrate-state
#############################################
# example 4-3 Partial configuration via CLI prompt
# by missing any required backend configuration
# From example 4-2, execute the following command"
# terraform init -backend-config=state_configuration/s3-state-bucket.hcl \
# -migrate-state
# [Screen shot ]
#  The path to the state file inside the bucket
#  Enter a value: dev/aws_infra3 
# [Use Case]
# omitting certain arguments may be desirable if
# some arguments are provided automatically by an automation script running Terraform
# When some or all of the arguments are ommitted, we call this a partial configuration
###############################################
# example 4-4 Backend configuration from multiple location
# main configuration is given
# then additional partial configuration override it!
# terraform {
#   backend "s3" {
#     bucket = "my-terraform-state-dhk"
#     key    = "dev/aws_infra"
#     region = "us-east-1"
#   }
# }
#=======
# prod-s3-state-key.hcl
#    key = "prod/aws_infra1"
#=======
# then execute the following:
# terraform init -backend-config=state_configuration/s3-state-bucket.hcl \
# -backend-config=state_configuration/prod-s3-state-key.hcl \
# -migrate-state
# prod-s3-state-key.hcl (partial configuration) override the main terraform configuration
# ==> change state file saving location from dev/aws_infra to prod/aws_infra1 rather than dev/aws_infra1

#################################
# Change state backend configuration to local default backend
# comment out any backend definition! 
# then execute the follwoing: terraform init -migrate-state