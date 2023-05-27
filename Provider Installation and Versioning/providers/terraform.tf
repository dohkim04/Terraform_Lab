terraform {
  # required_version = ">= 0.15.0"
  # required_version = "= 1.0.0"
  # required_version = "~> 1.0.0"
  required_version = ">= 1.0.0" # specify Terraform version
  required_providers {
    aws = {
      source = "hashicorp/AWS"
      version = "~> 3.0"
      #version = "3.76.1"      # specify provider version
    }
    
    http ={
      source ="hashicorp/http"
      version = "2.1.0"
    
    }
    random ={
      source ="hashicorp/random"
      version = "3.1.0"
    }

        local = {
      source = "hashicorp/local"
      version = "2.4.0"
    }
  }
}

/*

$terraform init
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 3.0"...
- Installing hashicorp/aws v3.76.1...
- Installed hashicorp/aws v3.76.1 (signed by HashiCorp)
....

$terraform version

Terraform v1.4.6
on linux_amd64
+ provider registry.terraform.io/hashicorp/aws v3.76.1
*/

/* Multiple provider installation

Initializing provider plugins...
- Finding hashicorp/random versions matching "3.1.0"...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Reusing previous version of hashicorp/http from the dependency lock file
- Using previously-installed hashicorp/aws v3.76.1
- Using previously-installed hashicorp/http v2.1.0
- Installing hashicorp/random v3.1.0...
- Installed hashicorp/random v3.1.0 (signed by HashiCorp)

*/
/*
$ terraform version
Terraform v1.4.6
on linux_amd64
+ provider registry.terraform.io/hashicorp/aws v3.76.1
+ provider registry.terraform.io/hashicorp/http v2.1.0
+ provider registry.terraform.io/hashicorp/local v2.4.0
+ provider registry.terraform.io/hashicorp/random v3.1.0

==> interact with multiple provides in a single configuration!! 
*/