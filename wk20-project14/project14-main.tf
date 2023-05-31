# Project 14 Terraform (Week 20)
# Name: Do Hyung Kim
# Establish Jenkins Server 

/* Discussion:
There are two ways to install Jenkins applications under "aws_instances" resource. 
==> user-data or provisioner under the resource "aws_instance"

Result: using provisioner resulted in failing Jenkins installation due to a missing script file
while using user-data completed Jenkins installation. 

User-data approach: 
- Advantage: 
   1. reduced significant time to install and configure Jenkins and Java applications using the embedded script file
   2. tolerable to potential errors as executing all files are done during the creation of EC2 instance as superuser mode. 
- Disadvantage:
   1. unable to see the progress of the installation and configuration

Provisioner approach:
- Advantage:
   1. every step of installation and configuration can be visibly monitored
- Disadvantage:
   1. takes a long time to install and configure Jenkins and Java applicatins as each command should be executed one at a time
   2. volunerable to any an error during the creation of EC2 instance as normal user mode.
   
# This draft is based on the default VPC in AWS
*/
provider "aws" {
  region = "us-east-1"
}

####################################
#(2) Create a S3 bucket for your Jenkins Artifacts that is not open to the public
#[2-1] Configure a resource for random provider to create S3 bucket name
resource "random_id" "randomness" {
  byte_length = 16
}
#[2-2] Create an AWS S3 bucket to store Jenkins Artifacts
# random string will be created and placed within "${...}" below
resource "aws_s3_bucket" "jenkinsbucket" {
  bucket = "my-tf-jenkinsbucket-${random_id.randomness.hex}"
}
#[2-3] The bucket objects are under the bucket owner's control 
# The bucket objects are not visible to external users
resource "aws_s3_bucket_ownership_controls" "jenkinsbucket" {
  bucket = aws_s3_bucket.jenkinsbucket.id
  rule { object_ownership = "BucketOwnerPreferred" }
}
#[2-4] Set your bucket as private and it is not visible to external users 
resource "aws_s3_bucket_acl" "jenkinsbucket" {
  depends_on = [aws_s3_bucket_ownership_controls.jenkinsbucket]
  bucket     = aws_s3_bucket.jenkinsbucket.id
  acl        = "private"
}

#[3] Spin up an EC2 instance in the default VPC for Jenkins 

## TLS provider - create a resource generating RSA private key
resource "tls_private_key" "jenkins-private-key" {
  algorithm = "RSA"
}

## local provider - interact with a local file system 
#                   to save the generated RSA private key into a file, "MyAWSKey.pem"
resource "local_file" "jenkins-private-key-pem" {
  content  = tls_private_key.jenkins-private-key.private_key_pem
  filename = "MyAWSKey.pem"
}

# Create SSH keypair and associate it with your EC2 instance 
resource "aws_key_pair" "jenkins-SSH-key-pair" { # generate public key remotely
  key_name   = "MyAWSKey"
  public_key = tls_private_key.jenkins-private-key.public_key_openssh
  lifecycle {
    ignore_changes = [key_name]
  }
}
################
resource "aws_instance" "ubuntu-server" {
  ami           = "ami-0261755bbcb8c4a84" # Ubuntu AMI
  instance_type = "t2.micro"
  vpc_security_group_ids = [
    aws_security_group.vpc-ssh.id,
    aws_security_group.vpc-web.id,
    aws_security_group.vpc-ping.id
  ]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.jenkins-SSH-key-pair.key_name
  user_data                   = <<EOF
#!/bin/bash  
# Install Jenkins
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
/usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
/etc/apt/sources.list.d/jenkins.list > /dev/null

apt-get -y update
apt-get -y install jenkins

# Installation Java Runtime Environment
apt -y update
apt -y install openjdk-11-jre
java -version
/* After logging into this server using SSH, check the installed Java version below
ubuntu@ip-172-31-81-120:~$ java -version
openjdk version "11.0.19" 2023-04-18
OpenJDK Runtime Environment (build 11.0.19+7-post-Ubuntu-0ubuntu120.04.1)
OpenJDK 64-Bit Server VM (build 11.0.19+7-post-Ubuntu-0ubuntu120.04.1, mixed mode, sharing)
*/
# Start Jenkins
systemctl enable jenkins # You can enable the Jenkins service to start at boot with this command
systemctl start jenkins # You can start the Jenkins service with this command
systemctl status jenkins # You can check the status of the Jenkins service using this command
EOF

  # If everything has been set up correctly, you should see an output like this:
  #Loaded: loaded (/lib/systemd/system/jenkins.service; enabled; vendor preset: enabled)
  #Active: active (running) since Tue 2018-11-13 16:19:01 +03; 4min 57s ago
  tags = {
    Name = "Ubuntu EC2 Server - Jenkins Group server"
  }

  lifecycle {
    ignore_changes = [security_groups]
  }
}

#####
#[4-1] Ingress SSH security group: 
# Allow traffic on port 22 (SSH) to your instance
resource "aws_security_group" "vpc-ssh" {
  name = "vpc-ssh"
  #vpc_id = aws_vpc.my-vpc.id

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
#[4-2] Web traffic security group: 
# Allowing web traffic via the standard HTTP, HTTPS ports as well as port 8080
resource "aws_security_group" "vpc-web" {
  name = "vpc-web"
  #vpc_id      = aws_vpc.my-vpc.id
  description = "Web Traffic"
  ingress { # Inbound traffic via HTTP
    description = "Allow Inbound access to Port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress { # Inbound traffic via HTTPS
    description = "Allow Inbound access to Port 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress { # Inbound traffic via port 8080
    description = "Allow Inbound access to Port 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress { # Outbound traffic
    description = "Allow all IPs and Ports Outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# [4-3] Ping access security group 
# Allow ICMP for Ping access
resource "aws_security_group" "vpc-ping" {
  name = "vpc-ping"
  #vpc_id      = aws_vpc.my-vpc.id
  description = "ICMP for Ping Access"
  ingress {
    description = "Allow ICMP Traffic"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow All IPs and Ports Outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


