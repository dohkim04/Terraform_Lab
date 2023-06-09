terraform {
  # Configuraiton Block to set required terraform version
  required_version = ">= 1.0.0" #This works well! 

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0" # "~> 3.0" #instead of 4.0 
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

/*
$ terraform init

Initializing the backend...

Initializing provider plugins...
- Reusing previous version of hashicorp/local from the dependency lock file
- Reusing previous version of hashicorp/tls from the dependency lock file
- Reusing previous version of hashicorp/aws from the dependency lock file
- Reusing previous version of hashicorp/http from the dependency lock file
- Reusing previous version of hashicorp/random from the dependency lock file
- Using previously-installed hashicorp/local v2.1.0
- Using previously-installed hashicorp/tls v3.1.0
- Using previously-installed hashicorp/aws v3.76.1
- Using previously-installed hashicorp/http v2.1.0
- Using previously-installed hashicorp/random v3.1.0

Terraform has been successfully initialized!
*/