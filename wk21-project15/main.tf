# -- root/main.tf -- #
# Date: 6/8/2023  
# Written by Do Hyung Kim
# Title: Terraform project - Autoscaling group on EC2 instances

# Define a AWS region
provider "aws" {
  region = var.region
}
# Define a default VPC
resource "aws_default_vpc" "vpc" {
  tags = { Name = "Default VPC" }
}
# Define 2 default subnets in the current region, "us-east-1".
resource "aws_default_subnet" "subnet1" {
  availability_zone = var.az1a
  tags              = { Name = "Default subnet for ${var.az1a}" }
}
resource "aws_default_subnet" "subnet2" {
  availability_zone = var.az1b
  tags              = { Name = "Default subnet for ${var.az1b}" }
}
################################################
#[2]Create a security group that allows traffic from the internet and associate it with the Auto Scaling group instances.
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "http-sg" {
  name        = "webserver-sg"
  description = "Control network traffic for webserver"
  vpc_id      = aws_default_vpc.vpc.id
  #The following is a list of 2 CIDR blocks corresponding to the respective 2 subnets: 
  #[aws_default_subnet.subnet1.cidr_block, aws_default_subnet.subnet2.cidr_block]

  ingress { # Inbound
    description = "SSH connection to our servers"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.cidr-block] # come into CIDR blocks
  }

  ingress { # Inbound
    description = "Apache HTTP webserver"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.cidr-block] # come into CIDR blocks
  }

  ingress { # Inbound
    description = "Allow incoming ICMP Traffic"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.cidr-block] # come into CIDR blocks
  }
  egress { # Outbound
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr-block] # go out to CIDR block
  }
  tags = {
    Name = "AutoScaling group of Http webservers"
  }
}


## TLS provider - create a resource generating RSA private key
resource "tls_private_key" "apache-privatekey" {
  algorithm = "RSA"
}
## local provider - interact with our local file system: save the RSA private key pem file as "MyAWSKey.pem"
resource "local_file" "apache-privatekey-pem" {
  content  = tls_private_key.apache-privatekey.private_key_pem
  filename = "MyAWSKey.pem"
}

# Create a SSH keypair and associate it with our EC2 instance 
resource "aws_key_pair" "apache-SSH-key-pair" { # generate the public key remotely
  key_name   = "MyAWSKey"
  public_key = tls_private_key.apache-privatekey.public_key_openssh
  lifecycle {
    ignore_changes = [key_name]
  }
}

##################################################
# Resource: aws_autoscaling-group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group
resource "aws_autoscaling_group" "project15-asg" {
  #availability_zones = ["us-east-1a", "us-east-1b"]
  desired_capacity  = var.desired-capacity  
  max_size          = var.max-size          
  min_size          = var.min-size         
  health_check_type = var.health-check-type  
  metrics_granularity = var.metrics-granularity
  vpc_zone_identifier = [aws_default_subnet.subnet1.id, aws_default_subnet.subnet2.id]

  launch_template {
    id = aws_launch_template.apache-server.id
    #version = aws_launch_template.apache-server.latest_version
  }
}

resource "aws_launch_template" "apache-server" {
  name                   = var.ec2template
  image_id               = var.ami
  instance_type          = var.instance_size
  key_name               = aws_key_pair.apache-SSH-key-pair.key_name
  vpc_security_group_ids = [aws_security_group.http-sg.id]
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "project15-tf-${var.ec2template}"
    }
  }

  user_data = filebase64("apache-server.sh")
}

resource "random_id" "randomness" {
  byte_length = 16
}
#[2-2] Create an AWS S3 bucket to store Terraform State
random string will be created and placed within "${...}" below
resource "aws_s3_bucket" "my-tf-project15" {
  bucket = "my-tf-project15-${random_id.randomness.hex}"
}
#[2-3] The bucket objects are under the bucket owner's control 
# the bucket objects are not visible to external users
resource "aws_s3_bucket_ownership_controls" "my-tf-project15" {
  bucket = aws_s3_bucket.my-tf-project15.id
  rule { object_ownership = var.object-ownership }
}

#[2-4] Set your bucket as private and it is not visible to external users 
resource "aws_s3_bucket_acl" "my-tf-project15" {
  depends_on = [aws_s3_bucket_ownership_controls.my-tf-project15]
  bucket     = aws_s3_bucket.my-tf-project15.id
  acl        = var.bucket-access
}



#4 To verify everything is working check the public ip addresses of the two instances. 
# Manually terminate one of the instances to verify that another one spins up to meet the minimum requirement of 2 instances.

#5 Create an S3 bucket and set it as your remote backend. => Refer to Terraform.tf configuration file

output bucket-name {
  value = aws_s3_bucket.my-tf-project15.bucket
}
output region-code {
  value = var.region
}
