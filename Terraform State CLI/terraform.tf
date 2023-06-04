terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
    source = "hashicorp/aws"
    version = "~> 3.0"
    }
    http = {
      source = "hashicorp/http"
    version = "2.1.0" 
    }
    random = {
      source = "hashicorp/random"
    version = "3.0.0" 
    }
    local = {
      source = "hashicorp/local"
    version = "2.1.0" 
    }
    tls = {
      source = "hashicorp/tls"
    version = "3.1.0" 
    }
  }
}/*
Error: Failed to query available provider packages
│ 
│ Could not retrieve the list of available versions for
│ provider hashicorp/aws: locked provider
│ registry.terraform.io/hashicorp/aws 5.0.1 does not match
│ configured version constraint ~> 3.0; must use terraform
│ init -upgrade to allow selection of new versions
*/