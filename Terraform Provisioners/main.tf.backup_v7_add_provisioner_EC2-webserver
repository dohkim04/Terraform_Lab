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


# data "aws_ami" "ubuntu" => name aws_ami resource as "ubuntu"
# to correct the undeclared resource error message shown below 
/*$ terraform validate
│ Error: Reference to undeclared resource
│   on main.tf line 157, in resource "aws_instance" "ubuntu_server":
│  157:   ami                         = data.aws_ami.ubuntu.id
│ A data resource "aws_ami" "ubuntu" has not been declared in the root module.
*/


# Provisioner lesson Task 3. 
# Create connection block using keypair module outputs
resource "aws_instance" "ubuntu_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnets["public_subnet_1"].id
  security_groups             = [aws_security_group.vpc-ping.id, aws_security_group.ingress-ssh.id, aws_security_group.vpc-web.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.generated.key_name
  connection { ## Here is connection block for login feature to your instance
    user        = "ubuntu"
    private_key = tls_private_key.generated.private_key_pem
    host        = self.public_ip
  }

  # Provisioner lesson Task 4. Use locl-exec privisioner 
  # to change permission on your local SSH key

  # Leave the first part of the block unchanged and create our `local-exec` provisioner
  provisioner "local-exec" {
    command = "chmod 600 ${local_file.private_key_pem.filename}"
  }

  # Provisioner lesson Task 5. 
  # Create a remote-exec provisioner block to pull down web application.
  provisioner "remote-exec" {
    inline = [
      "sudo rm -rf /tmp",                                                    # clean up temp directory on the server
      "sudo git clone https://github.com/hashicorp/demo-terraform-101 /tmp", #clone down the web app to the tmp directory
      "sudo sh /tmp/assets/setup-web.sh",                                    # execute the deployment script (setup-web.sh) in the web app folder
    ]
  }

  tags = {
    Name = "Ubuntu EC2 Server"
  }


  lifecycle {
    ignore_changes = [security_groups]
  }
}
# 
# The following aws_instance resource will be replaced with the above new resource!!!
# Terraform Resource Block - To Build EC2 instance in Public Subnet
/* resource "aws_instance" "web_server" {
  ami           = data.aws_ami.ubuntu_20_04.id # data.aws_ami.ubuntu_16_04.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnets["public_subnet_1"].id
  tags = {
    Name  = local.server_name
    Owner = local.team
    App   = local.application
  }
} */

# Privisioner lesson Task 6. 
# Apply your configuration and watch for the remote connection
# Let's check the configuration validity: terraform validate
# Let's execute terraform code : terraform apply
/* Captured major parts of the log message below:
aws_instance.web_server: Destroying... [id=i-0afb32dd084662bd5]
aws_security_group.vpc-ping: Creation complete after 2s [id=sg-082fdfdcbf2d9435d]
aws_security_group.ingress-ssh: Creation complete after 2s [id=sg-0c3d217d34e6f983c]
aws_security_group.vpc-web: Creation complete after 2s [id=sg-0c09f29899181de1d]
aws_instance.ubuntu_server: Creating...
(...)
aws_instance.ubuntu_server: Provisioning with 'local-exec'...
aws_instance.ubuntu_server (local-exec): Executing: ["/bin/sh" "-c" "chmod 600 MyAWSKey.pem"]
aws_instance.ubuntu_server: Provisioning with 'remote-exec'...
aws_instance.ubuntu_server (remote-exec): Connecting to remote host via SSH...
aws_instance.ubuntu_server (remote-exec):   Host: 3.231.50.91
aws_instance.ubuntu_server (remote-exec):   User: ubuntu
aws_instance.ubuntu_server (remote-exec):   Password: false
aws_instance.ubuntu_server (remote-exec):   Private key: true
aws_instance.ubuntu_server (remote-exec):   Certificate: false
aws_instance.ubuntu_server (remote-exec):   SSH Agent: false
aws_instance.ubuntu_server (remote-exec):   Checking Host Key: false
aws_instance.ubuntu_server (remote-exec):   Target Platform: unix
aws_instance.ubuntu_server (remote-exec): Connecting to remote host via SSH...
aws_instance.ubuntu_server (remote-exec):   Host: 3.231.50.91
aws_instance.ubuntu_server (remote-exec):   User: ubuntu
aws_instance.ubuntu_server (remote-exec):   Password: false
aws_instance.ubuntu_server (remote-exec):   Private key: true
aws_instance.ubuntu_server (remote-exec):   Certificate: false
aws_instance.ubuntu_server (remote-exec):   SSH Agent: false
aws_instance.ubuntu_server (remote-exec):   Checking Host Key: false
aws_instance.ubuntu_server (remote-exec):   Target Platform: unix
aws_instance.ubuntu_server: Still creating... [40s elapsed]
aws_instance.ubuntu_server (remote-exec): Connected!
aws_instance.ubuntu_server (remote-exec): Cloning into '/tmp'...
aws_instance.ubuntu_server (remote-exec): remote: Enumerating objects: 449, done.
aws_instance.ubuntu_server (remote-exec): remote: Counting objects:   3% (1/32)
(...)
aws_instance.ubuntu_server (remote-exec): Resolving deltas: 100% (142/142), done.
aws_instance.ubuntu_server (remote-exec): Created symlink /etc/systemd/system/multi-user.target.wants/webapp.service → /lib/systemd/system/webapp.service.
aws_instance.ubuntu_server: Creation complete after 48s [id=i-01bb35d6a811afb4a]

*/

# Provisioner lesson Task 7
# Pull up the web application and ssh into the web server (optional)
/* You can now visit your web application by pointing your browser a
t the public_ip output for your EC2 instance. 
To get that address you can look at the state details of
the EC2 instance by performing the following command:
$ terraform state show aws_instance.ubuntu_server
*/

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

#################################
## TLS provider - create a resource generating RSA private key
resource "tls_private_key" "generated" {
  algorithm = "RSA"
}
## Saving the above key file using local provider
## local provider to interact with local file system to save the generated key
## in this resource block to a file named MyAWSKey.pem
resource "local_file" "private_key_pem" {
  content  = tls_private_key.generated.private_key_pem
  filename = "MyAWSKey.pem"
}

######## Terraform Provisioners lessons
# used to model specific actions on the local or remote machine 
# to preapare servers or other infrastructure objects for service

# Provisioner lesson Task 1
# Create SSH keypair and associate it to your instance 
resource "aws_key_pair" "generated" { # generate public key remotely
  key_name   = "MyAWSKey"
  public_key = tls_private_key.generated.public_key_openssh

  lifecycle {
    ignore_changes = [key_name]
  }
}
/* After creating SSH keypair and associate it to your instance
Terraform will perform the following actions:

  # aws_key_pair.generated will be created
  + resource "aws_key_pair" "generated" {
      + arn             = (known after apply)
      + fingerprint     = (known after apply)
      + id              = (known after apply)
      + key_name        = "MyAWSKey"
      + key_name_prefix = (known after apply)
      + key_pair_id     = (known after apply)
      + public_key      = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGBNaFXVvCOlSMstiOxwnchLKZ3dLs9MUA5IcwxCcGgnp/nTsHQyWo3GxeS64OeygvWIGGpiVE2zS1Ky8F8F4/zF+7R4CcJDLHNwP8aZut5nAFKyw2xRFUHTMajiKMwArjnc8NjuAQuYTmQiWphtYAy/WF1Xg1qO7QI0uYmBjK+U5On2pikkL+pwKsBOIVyCjVAmQ8j0Vq3ks36a7nfhE+k0MZ7iIcHc1kPFgL38H3HhVYKIzZ7BHiX66Z2kEHLyYxIPV5zsI9z5oc55KbgWzptVorBlUpbsL44yp9UMH1dynz871SM3iJOwnEfjMRxivI8zu5kfTSb7w0VNiA2cfN"
      + tags_all        = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.
aws_key_pair.generated: Creating...
aws_key_pair.generated: Creation complete after 0s [id=MyAWSKey]
*/

# Provisioner lesson Task 2-1
# Create a Security Group allowing SSH to your instance
# Security Groups
resource "aws_security_group" "ingress-ssh" {
  name   = "allow-all-ssh"
  vpc_id = aws_vpc.vpc.id
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }
  // Terraform removes the default rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# Provisioner lesson Task 2-2
# Add resource block to create a Security group 
# allowing web traffic over the standard HTTP and HTTPS ports.
# Create Security Group - Web Traffic
resource "aws_security_group" "vpc-web" {
  name        = "vpc-web-${terraform.workspace}"
  vpc_id      = aws_vpc.vpc.id
  description = "Web Traffic"
  ingress {
    description = "Allow Port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow Port 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow all ip and ports outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# Provisioner lesson Task 2-3. 
# Add resource block to create a Security group 
# allowing ICMP for Ping access
resource "aws_security_group" "vpc-ping" {
  name        = "vpc-ping"
  vpc_id      = aws_vpc.vpc.id
  description = "ICMP for Ping Access"
  ingress {
    description = "Allow ICMP Traffic"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all ip and ports outboun"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



########
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
