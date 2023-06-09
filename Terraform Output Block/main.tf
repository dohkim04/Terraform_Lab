# Comments does not affect infrastructure or configuration of Terraform Code!
# "#" for Single-line comment; /* */ for multi-line comments 

# Title: IaC Buildout for Terraform Associate Exam
/*
Name: IaC Buildout for Terraform Associate Exam
Description: AWS Infrastructure Buildout
*/

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

locals {
  team        = "api_mgmt_dev"
  application = "corp_api"
  server_name = "ec2-${var.environment}-api-${var.variables_sub_az}"
}

#Retrieve the list of AZs in the current AWS region
data "aws_availability_zones" "available" {}
data "aws_region" "current" {} ### data block, aws_region type, data block name called current. 
### Let's use this data source!

# Terraform Data Block - Lookup Ubuntu 20.04   ## Previously, Lookup Ubuntu 16.04
data "aws_ami" "ubuntu_20_04" { ## Previously, "Ubuntu_16_04"
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


#Define the VPC
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name        = var.vpc_name
    Environment = "demo_environment"
    Terraform   = "true"
    # Added Region tag using data block below
    Region = data.aws_region.current.name #data.datatype.nameofblock.nameattribute
    # Where can I find this above data?  AWS provider itself - metadata data source - data source - region
    # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/regions
    # Export the particular attribute from attribute references.
    # grab a lot of information from the dta lookup under Data Source section

  }
}


#Deploy the private subnets
resource "aws_subnet" "private_subnets" {
  for_each          = var.private_subnets
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, each.value)
  availability_zone = tolist(data.aws_availability_zones.available.names)[each.value]
  # running the exact same Terraform in multiple regions 
  # and it would work without modifications, 
  # since the AZs are dynamically obtained by the data source.
  tags = {
    Name      = each.key
    Terraform = "true"
  }
}

#Deploy the public subnets
resource "aws_subnet" "public_subnets" {
  for_each                = var.public_subnets
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, each.value + 100)
  availability_zone       = tolist(data.aws_availability_zones.available.names)[each.value]
  map_public_ip_on_launch = true

  tags = {
    Name      = each.key
    Terraform = "true"
  }
}

#Create route tables for public and private subnets
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
    #nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
    Name      = "demo_public_rtb"
    Terraform = "true"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    # gateway_id     = aws_internet_gateway.internet_gateway.id
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
    Name      = "demo_private_rtb"
    Terraform = "true"
  }
}

#Create route table associations
resource "aws_route_table_association" "public" {
  depends_on     = [aws_subnet.public_subnets]
  route_table_id = aws_route_table.public_route_table.id
  for_each       = aws_subnet.public_subnets
  subnet_id      = each.value.id
}

resource "aws_route_table_association" "private" {
  depends_on     = [aws_subnet.private_subnets]
  route_table_id = aws_route_table.private_route_table.id
  for_each       = aws_subnet.private_subnets
  subnet_id      = each.value.id
}

#Create Internet Gateway
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "demo_igw"
  }
}

#Create EIP for NAT Gateway
resource "aws_eip" "nat_gateway_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.internet_gateway]
  tags = {
    Name = "demo_igw_eip"
  }
}

#Create NAT Gateway
resource "aws_nat_gateway" "nat_gateway" {
  depends_on    = [aws_subnet.public_subnets]
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = aws_subnet.public_subnets["public_subnet_1"].id
  tags = {
    Name = "demo_nat_gateway"
  }
}

# Terraform Resource Block - To Build EC2 instance in Public Subnet
resource "aws_instance" "web_server" {
  ami           = data.aws_ami.ubuntu_20_04.id # data.aws_ami.ubuntu_16_04.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnets["public_subnet_1"].id
  tags = {
    Name  = local.server_name
    Owner = local.team
    App   = local.application
  }
}


resource "aws_subnet" "variables-subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.variables_sub_cidr
  availability_zone       = var.variables_sub_az
  map_public_ip_on_launch = var.variables_sub_auto_ip

  tags = {
    Name      = "sub-variables-${var.variables_sub_az}"
    Terraform = "true"
  }
}

/* Plan: 1 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_subnet.variables-subnet: Creating...
aws_subnet.variables-subnet: Still creating... [10s elapsed]
aws_subnet.variables-subnet: Creation complete after 11s [id=subnet-0765a010c30b258f5]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed. */

########
/*
Data Block => upgrade aws_ami webserver upgrade ubuntu-16.04 => ubuntu-20.04
Plan: 1 to add, 0 to change, 1 to destroy.
aws_instance.web_server: Destroying... [id=i-071e56077f7e3abf6]
aws_instance.web_server: Still destroying... [id=i-071e56077f7e3abf6, 10s elapsed]
aws_instance.web_server: Still destroying... [id=i-071e56077f7e3abf6, 20s elapsed]
aws_instance.web_server: Still destroying... [id=i-071e56077f7e3abf6, 30s elapsed]
aws_instance.web_server: Destruction complete after 40s
aws_instance.web_server: Creating...
aws_instance.web_server: Still creating... [10s elapsed]
aws_instance.web_server: Still creating... [20s elapsed]
aws_instance.web_server: Still creating... [30s elapsed]
aws_instance.web_server: Creation complete after 31s [id=i-0de81007420ed2bdd]

Apply complete! Resources: 1 added, 0 changed, 1 destroyed.
*/
#########
/* Configuration Block allows to specify a specific version of Terraform
   Please note that previous version is not supported 
   But this is a way of pinning a specific version depending on your needs 
   Please refer to terraform.tf file and look at 'required_version' there
*/
