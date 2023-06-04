variable "ami"{} # this ami refers to the module server ami
variable "size"{ 
    default = "t2.micro"
}
variable "subnet_id"{} # this subnet_id refers to the module server subnet_id
variable "security_groups" { # this security_groups refers to the module security_groups
    type = list(any)
}
resource "aws_instance" "web" { # create resource in this server module
    ami = var.ami
    instance_type = var.size
    subnet_id = var.subnet_id   
    vpc_security_group_ids = var.security_groups
    tags = {
        "Name" = "Server from Module" 
        "Environment" = "Training" 
    } 
}

output "public_ip4" {
    value = aws_instance.web.public_ip
}
output "public_dns4" {
    value = aws_instance.web.public_dns
}

