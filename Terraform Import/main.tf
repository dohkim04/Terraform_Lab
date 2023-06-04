provider "aws" {
  region = "us-east-1"
  default_tags {
    tags ={
    Environment = "${terraform.workspace}"
    Owner = "Do Hyung Kim"
    Provisioned = "Terraform"
    }
  }
}

resource "aws_instance" "aws_linux"{
  ami = "ami-0f57ffe8bd04fa66d"
   instance_type = "t2.micro"
}

# resource "aws_instance" "aws_linux" {
#   ami                           = "ami-0f57ffe8bd04fa66d"
#   instance_type = "t2.micro"
# }

# resource "aws_instance" "aws_linux"{
#     ami = data.aws_ami.ubuntu.id # for us-west-2## for us-east-1, use "ami-0bef6cc322bfff646"
#     instance_type = "t2.micro"
#     tags = {
#     Name = "Amzon EC2 Server"
#   }
# }

data "aws_ami" "ubuntu" { ## Previously, "Ubuntu_16_04". Recently, "ubuntu_20_04"
  most_recent = true
  filter { # grab ami using filter
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  } # previou path: "ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"
  # refer to resource block defining "aws_instance", where ami = data.aws_ami.ubuntu_20_04.id 
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

