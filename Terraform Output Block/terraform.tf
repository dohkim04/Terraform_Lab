terraform {
  # Configuraiton Block to set required terraform version
  # required_version = ">= 1.0.0" This works well! 
  # required_version = "1.0.0"
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
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
  }
}