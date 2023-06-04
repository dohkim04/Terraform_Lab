variable "ami" {}
variable "size" {
  # default = "t2.micro" # commenting out this size variable within this server module make the variable required!
}
variable "subnet_id" {}
variable "security_groups" {
  type = list(any)
}

/* In root module, execute "terraform validate" 
│ Error: Missing required argument
│ 
│   on main.tf line 318, in module "server":
│  318: module "server" {
│ 
│ The argument "size" is required, but no definition was
│ found. (because the default value of the variable size was commented out in this server module!)
Therefore, main.tf root module needs to specify the value of the size varaible.
*/