# -- root/main.tf -- #
# Date: 6/11/2023  
# Written by Do Hyung Kim
# Title: Terraform project - 2-Tier architecture
# 2 public subnets with each EC2 instance hosting an Apache webserver 

# Choose an AWS region
provider "aws" {
  region = var.region
}

# Create a VPC
resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"
  tags       = { Name = "My own VPC network" }
}

resource "aws_subnet" "public-subnet1" {
  availability_zone       = var.az1a
  tags                    = { Name = "public subnet for ${var.az1a}" }
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = cidrsubnet(var.cidr-vpc, 8, 1)
  map_public_ip_on_launch = true
}
resource "aws_subnet" "public-subnet2" {
  availability_zone       = var.az1b
  tags                    = { Name = "public subnet for ${var.az1b}" }
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = cidrsubnet(var.cidr-vpc, 8, 2)
  map_public_ip_on_launch = true
}
# 2 private subnets
resource "aws_subnet" "private-subnet1" {
  availability_zone       = var.az1a
  tags                    = { Name = "private subnet for ${var.az1a}" }
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = cidrsubnet(var.cidr-vpc, 8, 101)
  map_public_ip_on_launch = true
}
resource "aws_subnet" "private-subnet2" {
  availability_zone       = var.az1b
  tags                    = { Name = "private subnet for ${var.az1b}" }
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = cidrsubnet(var.cidr-vpc, 8, 102)
  map_public_ip_on_launch = true
}


################################################
#[2]Create a security group that allows traffic from the internet and associate it with the Auto Scaling group instances.
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "web-sg" {
  name        = "web-sg"
  description = "Control network traffic for webserver"
  vpc_id      = aws_vpc.my-vpc.id

  ingress { # Inbound
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.cidr-block]
    description = "Allow internet to connect to this webserver via SSH protocol"
  }

  ingress { # Inbound
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.cidr-block]
    description = "Allow network traffic into Apache webserver"
  }

  ingress { # Inbound
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.cidr-block]
    description = "Allow incoming ICMP Traffic"
  }
  egress { # Outbound
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr-block] # all traffic in EC2 instance go out to CIDR block
  }
  tags = {
    Name = "AutoScaling group of Http webservers"
  }
}


resource "aws_security_group" "data-sg" {
  name        = "data-sg"
  description = "Control network traffic for RDS database"
  vpc_id      = aws_vpc.my-vpc.id

  ingress { # Inbound
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web-sg.id]
    description     = "Allow inbound traffic to RDS database from webserver group"
  }
  egress { # Outbound
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.web-sg.id]
    description     = "Allow outbound traffic to webserver security group"
  }
  tags = {
    Name = "security group for RDS MySQL database"
  }
}


## TLS provider - create a resource generating RSA private key
resource "tls_private_key" "apache-privatekey" {
  algorithm = "RSA"
}
## local provider - interact with our local file system: save the RSA private key pem file as "MyAWSKey.pem"
resource "local_file" "apache-privatekey-pem" {
  content  = tls_private_key.apache-privatekey.private_key_pem
  filename = "MyServerKey.pem"
}

# Create a SSH keypair and associate it with our EC2 instance 
resource "aws_key_pair" "apache-keypair" { # generate the public key remotely
  key_name   = "MyServerKey"
  public_key = tls_private_key.apache-privatekey.public_key_openssh
  lifecycle {
    ignore_changes = [key_name]
  }
}

# aws_autoscaling-group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group
resource "aws_autoscaling_group" "project16-asg" {
  #availability_zones = ["us-east-1a", "us-east-1b"]
  desired_capacity    = var.desired-capacity
  max_size            = var.max-size
  min_size            = var.min-size
  health_check_type   = var.health-check-type
  metrics_granularity = var.metrics-granularity
  vpc_zone_identifier = [aws_subnet.public-subnet1.id, aws_subnet.public-subnet2.id]

  launch_template {
    id      = aws_launch_template.web-server.id
    version = aws_launch_template.web-server.latest_version

  }
}

resource "aws_launch_template" "web-server" {
  name                   = var.ec2template
  image_id               = var.ami
  instance_type          = var.instance_size
  key_name               = aws_key_pair.apache-keypair.key_name
  vpc_security_group_ids = [aws_security_group.web-sg.id]

  depends_on = [aws_internet_gateway.my-igw]

  # network_interfaces {
  #   associate_public_ip_address = true
  # }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "project15-tf-${var.ec2template}"
    }
  }

  user_data = filebase64("apache-server.sh")
}

##
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0" # "10.0.1.0/24"
    gateway_id = aws_internet_gateway.my-igw.id
  }

  tags = {
    Name = "Route Table for Public Subnets"
  }
}

resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.my-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.my-nat-gw.id
  }

  tags = {
    Name = "Route Table for Private Subnets"
  }
}



#Elastic IP address for NAT Gateway
resource "aws_eip" "my-nat-gw-eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.my-igw]
  tags = {
    Name = "my_igw_eip"
  }
}

# resource "aws_instance" "foo" {
#   # ... other arguments ...
#   depends_on = [aws_internet_gateway.gw]
# }




# Internet Gateway
resource "aws_internet_gateway" "my-igw" {
  vpc_id = aws_vpc.my-vpc.id
  tags = {
    Name = "my internet gateway"
  }
}
#Create NAT Gateway
resource "aws_nat_gateway" "my-nat-gw" {
  depends_on    = [aws_subnet.public-subnet1, aws_subnet.public-subnet2]
  allocation_id = aws_eip.my-nat-gw-eip.id
  subnet_id     = aws_subnet.public-subnet1.id
  tags = {
    Name = "my nat gateway"
  }
}

# #nat_gateway_id = aws_nat_gateway.nat_gateway.id
resource "aws_route_table_association" "pub-asc1" {
  depends_on     = [aws_subnet.public-subnet1]
  route_table_id = aws_route_table.public-rt.id
  #gateway_id     = aws_internet_gateway.my-igw.id
  subnet_id = aws_subnet.public-subnet1.id 
}  
resource "aws_route_table_association" "pub-asc2" {
  depends_on     = [aws_subnet.public-subnet2]
  route_table_id = aws_route_table.public-rt.id
  #gateway_id     = aws_internet_gateway.my-igw.id
  subnet_id = aws_subnet.public-subnet2.id 
  #aws_subnet.public-subnet2.id]
}
resource "aws_route_table_association" "priv-asc1" {
  depends_on     = [aws_subnet.private-subnet1]
  route_table_id = aws_route_table.private-rt.id
  #gateway_id     = aws_nat_gateway.my-nat-gw.id
  subnet_id = aws_subnet.private-subnet1.id
}
resource "aws_route_table_association" "priv-asc2" {
  depends_on     = [aws_subnet.private-subnet2]
  route_table_id = aws_route_table.private-rt.id
  #gateway_id     = aws_nat_gateway.my-nat-gw.id
  subnet_id = aws_subnet.private-subnet2.id
}

##
resource "aws_db_instance" "database" {
  allocated_storage = 20 # No less than 20 Gigabyte for allocated storage per RDS console
  db_name           = "myrds"
  engine            = "mysql"
  engine_version    = "5.7"
  instance_class    = "db.t2.micro"
  vpc_security_group_ids = [aws_security_group.data-sg.id]
  username          = "admin"
  password          = "myrdspasswd"
  parameter_group_name = "default.mysql5.7" # "database.mysql5.7" (wrong name!)
  #availability_zone = availability_zone.availzone.id
  db_subnet_group_name      = aws_db_subnet_group.db-subnet-grp.name
  delete_automated_backups  = true  # remove backup after the db instance is deleted
  skip_final_snapshot       = false
  final_snapshot_identifier = "db-backup"
  backup_retention_period   = "0"
  deletion_protection       = false
}
#data "availability_zone" "availzone" {}
output database-sg {
  value = aws_db_instance.database.vpc_security_group_ids
}
output database-ip {
  value = aws_db_instance.database
  sensitive = true
}
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group
resource "aws_db_subnet_group" "db-subnet-grp" {
  name       = "db-subnet-grp"
  subnet_ids = [aws_subnet.private-subnet1.id, aws_subnet.private-subnet2.id]
  # a list of VPC subnet IDs
  tags = {
    Name = "My DB subnet group"
  }

}

### Show your current working AWS region
output "region-code" {
  value = var.region
}
output "public-subnet1" {
  value = aws_subnet.public-subnet1.id
}
output "public-subnet2" {
  value = aws_subnet.public-subnet2.id
}
output "private-subnet1" {
  value = aws_subnet.private-subnet1.id
}
output "private-subnet2" {
  value = aws_subnet.private-subnet2.id
}