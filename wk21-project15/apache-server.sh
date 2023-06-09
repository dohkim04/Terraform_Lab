# Date: 6/8/2023  
# Written by Do Hyung Kim
# Title: Terraform project - Autoscaling group on EC2 instances

# Bootstrapping HTTP Apache webserver 
#!/bin/bash
# Step 1: update Linux server and install apache webserver application
yum update -y
yum install -y httpd
# Step 2: configure website in this EC2 instance
#[2-1] Give permission to the Linux user to create and edit the HTML webpage file on the web server directory
chown -R $USER:$USER /var/www
systemctl start httpd
systemctl enable httpd
#sudo systemctl status httpd
#[2-2] Give permission to external user who can access to the website content
chmod -R 755 /var/www
cd /var/www/html/

# create a token valid up to 6 hours to retrieve the instance metadata from this instance
TOKEN=`curl --request PUT "http://169.254.169.254/latest/api/token" --header "X-aws-ec2-metadata-token-ttl-seconds: 21600"` 

# obtain and store the retrieved data below using the above token
INTERFACE=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/ --header "X-aws-ec2-metadata-token: $TOKEN")

InstanceIDInfo=$(curl -s http://169.254.169.254/latest/meta-data/instance-id --header "X-aws-ec2-metadata-token: $TOKEN")

SubnetIDInfo=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/${INTERFACE}/subnet-id --header "X-aws-ec2-metadata-token: $TOKEN")

PublicIPv4Info=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 --header "X-aws-ec2-metadata-token: $TOKEN") #obtain the public IPv4 of this instance


echo "<!DOCTYPE html>" >> index.html
echo "  <html>" >> index.html 
echo "    <head>" >> index.html
echo "      <title>Apache webserver by Terraform</title>" >> index.html
echo '      <meta charset="UTF-8">' >> index.html
echo "    </head>" >> index.html
echo "    <body>" >> index.html
echo "      <h2>Welcome to Terraform EC2Autoscaling project 14 in Level Up in Tech</h2>" >> index.html
echo "      <h3>Instance ID: $InstanceIDInfo</h3> " >> index.html
echo "      <h3>  Subnet ID: $SubnetIDInfo</h3>" >> index.html
echo "      <h3>Public IPv4: $PublicIPv4Info</h3> " >> index.html 
echo "      <h4>Cheer Up, Gold Team!!</h4>" >> index.html
echo "    </body>" >> index.html
echo "  </html>" >> index.html



 