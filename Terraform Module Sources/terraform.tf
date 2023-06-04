terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0" # " >= 3.0.0" (X) #  '~>3.0' means around 3.0
    /* 
    https://registry.terraform.io/modules/terraform-aws-modules/autoscaling/aws/4.9.0?tab=dependencies
    Provider Dependencies
    Providers are Terraform plugins that will be automatically installed 
    during terraform init if available on the Terraform Registry.
    - aws (hashicorp/aws) >= 3.64
    */
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
/* Terraform module for AWS autoscaling resource
$ terraform providers
Providers required by configuration:
.
├── provider[registry.terraform.io/hashicorp/aws] ~> 3.0
├── provider[registry.terraform.io/hashicorp/http] 2.1.0
├── provider[registry.terraform.io/hashicorp/random] 3.1.0
├── provider[registry.terraform.io/hashicorp/local] 2.1.0
├── provider[registry.terraform.io/hashicorp/tls] 3.1.0
├── module.autoscaling
│   ├── provider[registry.terraform.io/hashicorp/aws] >= 3.30.0
│   └── provider[registry.terraform.io/hashicorp/null] >= 2.0.0
├── module.server
│   └── provider[registry.terraform.io/hashicorp/aws]
└── module.server_subnet_1
    └── provider[registry.terraform.io/hashicorp/aws]
*/