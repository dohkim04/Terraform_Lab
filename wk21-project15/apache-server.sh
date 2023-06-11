#!/bin/bash
sudo yum update -y
sudo yum install -y httpd 
sudo chown -R $USER:$USER /var/www
sudo systemctl start httpd  
sudo systemctl enable httpd  
sudo chmod -R 755 /var/www
cd /var/www/html/
# I created this short versoin of the original shell script
# as user_data can accommodate up to 16KB in chracter size.
# any script larger than the size limit should be executed through provisioner 