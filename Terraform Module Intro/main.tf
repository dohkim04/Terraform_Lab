module "subnet_addrs" {
  source          = "hashicorp/subnets/cidr"
  version         = "1.0.0"
  base_cidr_block = "10.0.0.0/22"
  networks = [
    {
      name     = "module_network_a"
      new_bits = 2
    },
    {
      name     = "module_network_b"
      new_bits = 2
    },
  ]
}
output "subnet_addrs" {
    value = module.subnet_addrs.network_cidr_blocks
}

/* 
$terraform validate
╷
│ Error: Module not installed
│ 
│   on main.tf line 1:
│    1: module "subnet_addrs" {
│ 
│ This module is not yet installed. Run "terraform init" to install all modules
│ required by this configuration.
*//* ########################################################
$ terraform init ==> downloaded terraform module 
Initializing the backend...
Initializing modules...
Downloading registry.terraform.io/hashicorp/subnets/cidr 1.0.0 for subnet_addrs...
- subnet_addrs in .terraform/modules/subnet_addrs

Initializing provider plugins...

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.

*//* ##############################################
$ terraform plan  ==> ex. split CIDR block and deploy smaller subnets to public cloud.
                  ==> can reference the output of the module to be input of new subnets
Changes to Outputs:
  + subnet_addrs = {
      + module_network_a = "10.0.0.0/24"
      + module_network_b = "10.0.1.0/24"
    }

You can apply this plan to save these new output values to the Terraform state,
without changing any real infrastructure.
*//*


*/
