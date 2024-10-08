#!/bin/bash
# update system
apt-get update -y
# install apache2
apt-get install -y apache2
# start service
systemctl start apache2.service
# enable service so it starts after reboot
systemctl enable apache2.service
# drop default index.html in path served by apache
echo "It Works!" > /var/www/html/index.html