variable "first_name" {
  type      = string
  sensitive = true
  default   = "Terraform"
}
variable "last_name" {
  type      = string
  sensitive = true
  default   = "Tom"
}
variable "phone_number" {
  type      = string
  sensitive = true
  default   = "867-5309"
}
locals {
  contact_info = {
    first_name   = var.first_name
    last_name    = var.last_name
    phone_number = var.phone_number
  }
  my_number = nonsensitive(var.phone_number)
}

output "first_name" {
  value = local.contact_info.first_name
     sensitive = true
}
output "last_name" {
  value = local.contact_info.last_name
     sensitive = true
}
output "phone_number" {
  value = local.contact_info.phone_number
     sensitive = true
}
output "my_number" { # to showcase difference settings between sensitive vs nonsensitive
  value = local.my_number
}

/* terraform apply
Changes to Outputs:
  + first_name                 = (sensitive value)
  + last_name                  = (sensitive value)
  + my_number                  = "867-5309"
  + phone_number               = (sensitive value)
*/

/* 
Outputs:

first_name = <sensitive>
last_name = <sensitive>
my_number = "867-5309"
phone_number = <sensitive>
*/

/* redact sensitive information from the logs
and from the outputs as long as we set the sensitive argument
equal to be true */


/* Still sensitive information is clear 
on the Terraform.tfstate text file
as you can still see the value of each sensitiv information */

/* Treat as Terraform State File as sensitive// 

Depending on Terraform Resource State,database password or credentials, etc.
very important to protect Terraform State stored Terraform State in a backend that supports
encryption if possible


Instad of storing your state in a local Terraform to state file, 
use one of the nativel supported backend - AWS S3, Azure Blob Storage or Terraform Cloud that support encryption 

# the information in the State file will be still available in plain text,
the data itself will be stored in an encrypted manner.

Choose a Terraform State backend that supports encryption both in transit and on disk.

Make sure we control access to the state file
who can access Terraform Backend?

Who can acess to the back end storing Terraform State file that contains secrets?

s3 backen - AWS IAM policy that solely grants access to that S3 backend to a small number of
trusted developers and operators.

Terraform Cloud also uspport the ability to control acess to the TF state

In picking up your state backend, 
make sure to have the ability to control
who can and who cannot have access to the Terraform State information

*/