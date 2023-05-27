terraform {
  # Configuraiton Block to set required terraform version
  required_version = ">= 1.0.0" #This works well! 
  #required_version ="1.0.0" 
  /* The version 1.0.0 is not accepted due to its potential incompatibility issue 
     since the current Terraform version in our system is 1.4.6.*/
  /* This is a way to pin and run only a specific Terraform version 
     based on configuration file.
  
  $terraform init
  Initializing the backend...
╷
│ Error: Unsupported Terraform Core version
│ 
│   on terraform.tf line 4, in terraform:
│    4:   required_version ="1.0.0"
│ 
│ This configuration does not support Terraform version 1.4.6. To
│ proceed, either choose another supported Terraform version or update
│ this version constraint. Version constraints are normally set for good
│ reason, so updating the constraint may lead to other errors or
│ unexpected behavior.
  */

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0" #instead of 4.0 
    }

    http = {
      source  = "hashicorp/http"
      version = "2.1.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.1.0" # Let's downgrade from 3.1.0 to 3.0.0
      # Let's change back to 3.1.0 !
      # Check how the .terraform.lock.hcl file content is updated 
      # upon executing "terraform init -upgrade" command
      # after chaning this random provider version number
      # share your lock file with your colleague
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