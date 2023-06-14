#!/bin/bash
sudo yum update -y
sudo yum install -y httpd 
sudo chown -R $USER:$USER /var/www
sudo systemctl start httpd  
sudo systemctl enable httpd  
sudo chmod -R 755 /var/www
cd /var/www/html/
INTERFACE=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/)
Instance=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
SubnetIDInfo=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/${INTERFACE}/subnet-id)
PublicIPv4Info=$(curl -s ifconfig.me)
echo "<!DOCTYPE html><html><title>Projet 16: 2-Tier Architecture by Terraform</title>" >> index.html
echo "<body><h3>InstanceID: $Instance</h3><h3>Subnet: $SubnetIDInfo </h3>" >> index.html
echo "<h3>Public IPv4: $PublicIPv4Info</h3></body></html>" >> index.html