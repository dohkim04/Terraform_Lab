resource "random_string" "random" {
  length = 10
}


# terraform -version
# check whether Terraform is working properly
# check Terraform running on your machine

# terraform -help : help for subcommands

# terraform init
# - initialize the backend and download all necessary providers needed to execute this terraform

# terraform plan
# - create a plan of our expected output for this Terraform configuration file
# - compare to State file (if not existing, anything in the configuration file will be net new resource that Terraform will manage)

# terraform plan -out myplan
# - save the above plan as myplan file
  
# terraform apply myplan
# - apply to actually build up the infrastructure per myplan file
# terraform plan -destroy
# - see what would be destroyed 
# terraform destroy
# - execute the destruction of the infrastructure