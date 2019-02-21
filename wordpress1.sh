#!/bin/bash
#This code safes 'latest.tar.gz' file under '/root' folder in AWS
	yum install wget httpd vim php-gd php php-mysql mysql -y

	wget http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm

    rpm -ivh mysql-community-release-el7-5.noarch.rpm

    yum install mysql-server -y

	systemctl start httpd
	systemctl enable httpd
	
	systemctl start mysqld 
	systemctl enable mysqld
	
	
	
	cd ~/ && wget https://wordpress.org/latest.tar.gz
	
	tar xzvf ~/latest.tar.gz && rsync -avP ~/wordpress/ /var/www/html/

	cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
	
	chown -R apache:apache /var/www/html/
	
	sed -i 's/enforcing/disabled/g' /etc/selinux/config /etc/selinux/config

	read -p "Do you have database and user ready? :" database 

if [ $database == yes ]; 
	then echo "Thats great"

read -p "Enter your database name :" dbname
	  sed -i "/DB_NAME/s/'[^']*'/'$dbname'/2" /var/www/html/wp-config.php

	read -p "Enter your database user :" dbuser
	  sed -i "/DB_USER/s/'[^']*'/'$dbuser'/2" /var/www/html/wp-config.php

	read -p "Enter your database password :" passwd 
	  sed -i "/DB_PASSWORD/s/'[^']*'/'$passwd'/2" /var/www/html/wp-config.php

	read -p "Please enter your database host :" host 
	  sed -i "/DB_HOST/s/'[^']*'/'$host'/2" /var/www/html/wp-config.php 


elif [ $database == no ]; 
	then echo "Please create your database :" 


# PASS="password"
read -p "Please enter password for your msyql-admin :" adminpasswd
	mysqladmin password $adminpasswd

	mysql -u root -p"$adminpasswd" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
	mysql -u root -p"$adminpasswd" -e "DELETE FROM mysql.user WHERE User=''"
	mysql -u root -p"$adminpasswd" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"
	mysql -u root -p"$adminpasswd" -e "FLUSH PRIVILEGES"
	
	#Create database, user, adminpasswdword
	read -p "Enter a database name " newdbname
 	mysql -u root -p"$adminpasswd" -e "CREATE DATABASE $newdbname "
 	read -p "Enter database user name :" wpuser
 	read -p "Enter password for the user $wpuser " wpuserpasswd
	mysql -u root -p"$adminpasswd" -e "GRANT ALL on $newdbname.* to $wpuser identified by '$wpuserpasswd' "
	
	sed -i "/DB_NAME/s/'[^']*'/'$newdbname'/2" /var/www/html/wp-config.php

	sed -i "/DB_USER/s/'[^']*'/'$wpuser'/2" /var/www/html/wp-config.php

	sed -i "/DB_PASSWORD/s/'[^']*'/'$wpuserpasswd'/2" /var/www/html/wp-config.php

systemctl restart httpd 
	
fi 


