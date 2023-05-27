output "hello-world" {
  description = "Print a Hello World text output"
  value       = "Hello World"
}
output "vpc_id" {
  description = "Output the ID for the primary VPC"
  value       = aws_vpc.vpc.id
}

output "public_url" {
  description = "Public URL for our Web Server"
  value       = "https://${aws_instance.web_server.private_ip}:8080/index.html"
}
output "vpc_information" {
  description = "VPC Information about Environment"
  value = "Your ${aws_vpc.vpc.tags.Environment} VPC has an ID of ${aws_vpc
  .vpc.id}"
}

/*
$ terraform apply -auto-approve

Outputs: 

hello-world = "Hello World"
public_url = "https://10.0.101.8:8080/index.html"
vpc_id = "vpc-09ec3d7e6260935e0"
vpc_information = "Your demo_environment VPC has an ID of vpc-09ec3d7e6260935e0"

*//* Regular output format
$ terraform output
hello-world = "Hello World"
public_url = "https://10.0.101.8:8080/index.html"
vpc_id = "vpc-09ec3d7e6260935e0"
vpc_information = "Your demo_environment VPC has an ID of vpc-09ec3d7e6260935e0"

*//* JSON-style output format
$terraform output -json
{
  "hello-world": {
    "sensitive": false,
    "type": "string",
    "value": "Hello World"
  },
  "public_url": {
    "sensitive": false,
    "type": "string",
    "value": "https://10.0.101.8:8080/index.html"
  },
  "vpc_id": {
    "sensitive": false,
    "type": "string",
    "value": "vpc-09ec3d7e6260935e0"
  },
  "vpc_information": {
    "sensitive": false,
    "type": "string",
    "value": "Your demo_environment VPC has an ID of vpc-09ec3d7e6260935e0"
  }
}


*/