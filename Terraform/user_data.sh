#!/bin/bash
yum update -y
yum install httpd -y
mkdir /var/www/html/demo/img
curl -o /var/www/html/index.html https://raw.githubusercontent.com/Asif-Patel/AWS-WebApp-Hosting-Module/main/demo/index.html
#echo "Hello Asif! from terraform" >> /var/www/html/index.html
chkconfig httpd on
service httpd start
iptables -A INPUT -p tcp --dport 80 -j ACCEPT