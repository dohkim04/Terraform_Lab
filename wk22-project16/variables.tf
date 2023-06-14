# -- root/variables.tf -- #
# Date: 6/8/2023 
# Written by Do Hyung Kim
# Title: Terraform project - Autoscaling group on EC2 instances

### AWS Region and 2 Availability Zones ###
variable "region" {
  description = "an AWS region"
  default     = "us-east-1"
}
variable "az1a" {
  description = "an AWS availability zone 1a"
  default     = "us-east-1a"
}
variable "az1b" {
  description = "an AWS availability zone 1b"
  default     = "us-east-1b"
}

### Security Group parameters ###
# CIDR blocks used for security group to access to EC2 instance
variable "cidr-block" {
  description = "CIDR Block - Internet"
  default     = "0.0.0.0/0"
}
variable "cidr-vpc" {
  description = "CIDR Block for your VPC"
  default     = "10.0.0.0/16"
}
## The parameter values for AWS EC2 instances 
variable "ami" {
  description = "Amazon Linux 2"        #"Canonical Ubuntu, 22.04 LTS" #"Amazon Linux 2023 AMI Free-Tier" # 
  default     = "ami-09988af04120b3591" #"ami-053b0d53c279acc90" #"ami-04a0ae173da5807d3" # 
}
variable "instance_size" {
  description = "The size of the instance"
  default     = "t2.micro"
}

### AWS Autoscaling Group parameters ### maintain 2 EC2 instance all the time
variable "desired-capacity" {
  description = "Autoscaling - target number of instances"
  default     = 2
}
variable "min-size" {
  description = "Autoscaling - minimum number of instances"
  default     = 2
}
variable "max-size" {
  description = "Autoscaling - maximum number of instances"
  default     = 2
}
variable "health-check-type" { # check EC2 health status
  description = "Health check type ex. EC2 or ELB"
  default     = "EC2"
}
variable "metrics-granularity" { # 
  description = "Metrics granularity - The period of EC2 status check"
  default     = "1Minutes" # "3Minutes", "5Minutes", etc
}
variable "ec2template" {
  description = "AWS Launch Template name"
  default     = "apache-server"
}

variable "private_subnets" {
  default = {
    "private_subnet_1" = 1
    "private_subnet_2" = 2
  }
}
variable "public_subnets" {
  default = {
    "public_subnet_1" = 1
    "public_subnet_2" = 2
  }
}