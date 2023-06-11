# -- root/variables.tf -- #
# Date: 6/8/2023 
# Written by Do Hyung Kim
# Title: Terraform project - Autoscaling group on EC2 instances

### AWS Region and Availability Zone parameters ###
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
  description = "CIDR Block"
  default     = "0.0.0.0/0"
}

### AWS EC2 Launch Template parameters ###
variable "ami" {
  description = "Amazon Linux 2" #"Canonical Ubuntu, 22.04 LTS" #"Amazon Linux 2023 AMI Free-Tier" # 
  default     = "ami-09988af04120b3591" #"ami-053b0d53c279acc90" #"ami-04a0ae173da5807d3" # 
}
variable "instance_size" {
  description = "The size of the instance"
  default     = "t2.micro"
}

### AWS Autoscaling Group parameters ###
variable "desired-capacity" {
  description = "Autoscaling - desired number of instances"
  default     = 2
}
variable "min-size" {
  description = "Autoscaling - minimum number of instances"
  default     = 2
}
variable "max-size" {
  description = "Autoscaling - maximum number of instances"
  default     = 5
}
variable "health-check-type" {
  description = "Health check type ex. EC2 or ELB"
  default     = "EC2"
}
variable "metrics-granularity" {
  description = "Metrics granularity - The period of EC2 status check"
  default     = "1Minutes" # "3Minutes", "5Minutes", etc
}
variable "ec2template" {
  description = "AWS Launch Template name"
  default     = "apache-server"
}

### S3 bucket parameters ### S3 bucket is used as Terraform Backend
variable "object-ownership" {
  description = "determine the scope of the bucket object ownership"
  default     = "BucketOwnerPreferred"
}
variable "bucket-access" {
  description = "determine whether the bucket is accessible in public or not"
  default     = "private"
}