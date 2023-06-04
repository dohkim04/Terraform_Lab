/*
Name: IaC Buildout for Terraform Associate Exam
Description: AWS Infrastructure Buildout
Contributors: Bryan and Gabe
*/

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

#Retrieve the list of AZs in the current AWS region
data "aws_availability_zones" "available" {}
data "aws_region" "current" {}

#Define the VPC 
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name        = var.vpc_name
    Environment = "demo_environment"
    Terraform   = "true"
  }

  enable_dns_hostnames = true
}

#Deploy the private subnets
resource "aws_subnet" "private_subnets" {
  for_each          = var.private_subnets
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, each.value)
  availability_zone = tolist(data.aws_availability_zones.available.names)[each.value]

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


resource "random_string" "random" {
  length = 10
}

# Terraform Data Block - To Lookup Latest Ubuntu 20.04 AMI Image
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

# Terraform Resource Block - To Build EC2 instance in Public Subnet
resource "aws_instance" "ubuntu_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnets["public_subnet_1"].id
  security_groups             = [aws_security_group.vpc-ping.id, aws_security_group.ingress-ssh.id, aws_security_group.vpc-web.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.generated.key_name
  connection {
    user        = "ubuntu"
    private_key = tls_private_key.generated.private_key_pem
    host        = self.public_ip
  }

  # Leave the first part of the block unchanged and create our `local-exec` provisioner
  provisioner "local-exec" {
    command = "chmod 600 ${local_file.private_key_pem.filename}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo rm -rf /tmp",
      "sudo git clone https://github.com/hashicorp/demo-terraform-101 /tmp",
      "sudo sh /tmp/assets/setup-web.sh",
    ]
  }

  tags = {
    Name = "Ubuntu EC2 Server"
  }

  lifecycle {
    ignore_changes = [security_groups]
  }


}

# Terraform Resource Block - Security Group to Allow Ping Traffic
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

resource "tls_private_key" "generated" {
  algorithm = "RSA"
}

resource "local_file" "private_key_pem" {
  content  = tls_private_key.generated.private_key_pem
  filename = "MyAWSKey.pem"
}

resource "aws_key_pair" "generated" {
  key_name   = "MyAWSKey"
  public_key = tls_private_key.generated.public_key_openssh
}

resource "aws_security_group" "ingress-ssh" {
  name   = "allow-all-ssh"
  vpc_id = aws_vpc.vpc.id
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }
  // Terraform removes the default rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

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

# Terraform Resource Block - To Build Web Server in Public Subnet
resource "aws_instance" "web_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnets["public_subnet_1"].id
  security_groups             = [aws_security_group.vpc-ping.id, aws_security_group.ingress-ssh.id, aws_security_group.vpc-web.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.generated.key_name
  connection {
    user        = "ubuntu"
    private_key = tls_private_key.generated.private_key_pem
    host        = self.public_ip
  }

  # Leave the first part of the block unchanged and create our `local-exec` provisioner
  provisioner "local-exec" {
    command = "chmod 600 ${local_file.private_key_pem.filename}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo rm -rf /tmp",
      "sudo git clone https://github.com/hashicorp/demo-terraform-101 /tmp",
      "sudo sh /tmp/assets/setup-web.sh",
    ]
  }

  tags = {
    Name = "Web EC2 Server"
  }

  lifecycle {
    ignore_changes = [security_groups]
  }

}

# Terraform Resource Block - To Build EC2 instance in Public Subnet
resource "aws_instance" "web_server_2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnets["public_subnet_2"].id
  tags = {
    Name = "Web EC2 Server 2"
  }
}

module "server" {
  source          = "./modules/server"
  ami             = data.aws_ami.ubuntu.id
  size            = "t2.micro"
  subnet_id       = aws_subnet.public_subnets["public_subnet_3"].id
  security_groups = [aws_security_group.vpc-ping.id, aws_security_group.ingress-ssh.id, aws_security_group.vpc-web.id]
}

module "server_subnet_1" {
  source          = "./modules/web_server"
  ami             = data.aws_ami.ubuntu.id
  key_name        = aws_key_pair.generated.key_name
  user            = "ubuntu"
  private_key     = tls_private_key.generated.private_key_pem
  subnet_id       = aws_subnet.public_subnets["public_subnet_1"].id
  security_groups = [aws_security_group.vpc-ping.id, aws_security_group.ingress-ssh.id, aws_security_group.vpc-web.id]
}

output "public_ip" {
  value = module.server.public_ip
}

output "public_dns" {
  value = module.server.public_dns
}

output "size" {
  value = module.server.size
}

output "public_ip_server_subnet_1" {
  value = module.server_subnet_1.public_ip
}

output "public_dns_server_subnet_1" {
  value = module.server_subnet_1.public_dns
}

/*
In objects pane under the prod/ directory of the S3 bucket console, check on the file and click open button => Security token will allow to see the content inside the file (object)
https://my-terraform-state-dhk.s3.us-east-1.amazonaws.com/prod/aws_infra?response-content-disposition=inline&X-Amz-Security-Token=IQoJb3JpZ2luX2VjENX%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaCXVzLWVhc3QtMSJHMEUCIQCTJUf%2FK79m9SelYqmasuI54hN9qsQ4FjtfWjxCrsw7fAIgX2e4s%2FbSfHejtB3Ri1EkLeABX%2F68B9pR90oeRuemMEIq%2FwIIHRAAGgw1Mjc3NzkzOTQ4ODciDJ6hNxJ3OUnH7obUyyrcAlruSp%2F3zkcz%2B8wpZhsu2u0mJEJVyR5fsVzJ5loAwoTeb16l3XUZumoAv15ARNPXuCzuBO7g6Byu%2Bd4mEccZBAZFIH25Crp2t2KHf2aTrPHCkMJmHLLa4wm5uFQoAXCb5h%2FbLPnyuHMx%2BbLCQbYwy0oZNlDq4YhKJgG1Ak99ZZmu3w9r4tc3cLYJQ0vK54PinN1Vnz9BRN5hlVsEu%2B9mBweyQYmFQ97c8br%2FhY%2BEeu7BWLE%2FdXMp2xiQqpT%2BhhDKN8zxidK5pyBCO8F2TZvMSc15djIg81LAdLi5Xp1%2BzwB4Pk0m7W2%2BxX1CwKawi%2B5m5%2BO9cUZCA1u0IRYAJasQdA3MEBQ5vuaoUXOXv87eKnWVgTXFEIjv4wzTpZzVi8c6S%2BF6RP5kGx3NKC%2FNk6KvLUgIn4DX6mBTTYwYrBAXpipeHtHwdd11%2FA57ccv0KVqjjyHYdFpAOAmFsFK%2BxDD8lvOjBjqzAkhJ1YkmnoCEBJzvXnUtkVkyPlJvBnPDrIf1WTD1E2IHge9qS1fdCm%2BDTmGJgI6imHcmynN5x%2B%2FODqWirqHPqujLvFHdIF%2BOiCmOlMDYYdNDvt0ETCC0J3hodWuff6fw9eA2UIC4n4gCIdzUX7PZ7BKpPEv%2Fbt4MRud6C6n1ae5gyARW9q3GSn9ipMHM0Zt6rgwM6nZ84jbcfQ8k722LvSYh9SI3Jeoq8N28F%2FEYfveT6c4KZGOKhpPNhOfuyCmcmtWVQZ%2BZQmpdmBEb998QgJ%2FA%2FsPeXZF6NJvqoedFZ8csCEVsKnv8OrWYSSHCY%2FJlg1HTHj%2Bc7OQPvxyvyuw2T9iHqzvQSrIw95yYNIq75MtZDrPf5TuNBXnmp0n3XvJN3zd50LPQpw5lvbD8ErH8KDqf6QE%3D&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Date=20230604T202645Z&X-Amz-SignedHeaders=host&X-Amz-Expires=300&X-Amz-Credential=ASIAXVYQ2OVDRU6VOWOX%2F20230604%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Signature=9037ed6afd2d22affe14df3d61f779d6a036b191027835f3300421681453632d

{
  "version": 4,
  "terraform_version": "1.4.6",
  "serial": 4,
  "lineage": "38988c0f-0bef-e5a4-4e0c-1a67b91aca33",
  "outputs": {},
  "resources": [],
  "check_results": null
}

=============================
Copy URL into a web browser window => To AWS Security token available. Not allowed to access to the content of the file

https://my-terraform-state-dhk.s3.amazonaws.com/prod/aws_infra

This XML file does not appear to have any style information associated with it. The document tree is shown below.
<Error>
<Code>AccessDenied</Code>
<Message>Access Denied</Message>
<RequestId>4J5TZ6FKTTEPR448</RequestId>
<HostId>u0pja+nbsxpcOSwH51Dn2gDyiXOWJRf8BBMH1mB6OHxM+aLSutzykI6OPsK84xzflDABfmAx9sY=</HostId>
</Error>
*/