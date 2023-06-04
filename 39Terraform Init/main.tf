# provider "aws" {
#   region = "us-east-1"
# } ## regions is necessary for s3 bucket deployment
/*
│ Error: Missing required argument
│ The argument "region" is required, but was not set.
*/
resource "random_string" "random" {
  length = 10
}

resource "random_pet" "server" {
  length = 2
}

# Changes on the file path:
# Refer to this site for more detail: https://registry.terraform.io/modules/terraform-aws-modules/s3-bucket/aws/2.10.0/examples/complete
/*
Provision Instructions
Copy and paste into your Terraform configuration, insert the variables, and run terraform init:
*/
# module "s3-bucket_example_complete" {
#   #source  = "terraform-aws-modules/s3-bucket/aws/examples/complete"
#   source  = "terraform-aws-modules/s3-bucket/aws//examples/complete"
#   version = "2.10.0"
# }
/*Decided to use new example!! 
https://registry.terraform.io/modules/terraform-aws-modules/s3-bucket/aws/3.11.0/examples/complete
*/

module "s3-bucket_example_complete" {
  source  = "terraform-aws-modules/s3-bucket/aws//examples/complete"
  version = "3.11.0"
}

/*  $terraform providers
Providers required by configuration:
.
├── provider[registry.terraform.io/hashicorp/http] 2.1.0
├── provider[registry.terraform.io/hashicorp/random] 3.1.0
├── provider[registry.terraform.io/hashicorp/local] 2.1.0
├── provider[registry.terraform.io/hashicorp/tls] 3.1.0
├── provider[registry.terraform.io/hashicorp/azurerm] 2.84.0
├── provider[registry.terraform.io/hashicorp/aws] ~> 3.0
└── module.s3-bucket_example_complete
    ├── provider[registry.terraform.io/hashicorp/aws] >= 3.60.0
    ├── provider[registry.terraform.io/hashicorp/random] >= 2.0.0
    ├── module.s3_bucket
    │   └── provider[registry.terraform.io/hashicorp/aws] >= 3.50.0
    ├── module.cloudfront_log_bucket
    │   └── provider[registry.terraform.io/hashicorp/aws] >= 3.50.0
    └── module.log_bucket
        └── provider[registry.terraform.io/hashicorp/aws] >= 3.50.0
*/