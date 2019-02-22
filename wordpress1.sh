#!/bin/bash
#Simple bash script, that installs LAMP package and WordPress.
#Testen in GCP and AWS on CentOS7

#First line installs -wget and -vim commands; also LAMP pakckage
	yum install wget vim httpd php-gd php php-mysql mysql -y
#This 2 line below download 'mysql-server' repository and ads it to the repo list 
	wget http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
	rpm -ivh mysql-community-release-el7-5.noarch.rpm
	yum install mysql-server -y
#Below lines starts and make boot-persistant APache and MySQL
	systemctl start httpd
	systemctl enable httpd	
	systemctl start mysqld 
	systemctl enable mysqld
	
	
#This lines below download a compressed archive file that contains all of
#the wordpress files that we need; unpack package and securily transfer them to the 'html' folder

	wget -qP /tmp http://wordpress.org/latest.tar.gz
	tar xzf /tmp/latest.tar.gz -C /tmp
	rsync -aqP /tmp/wordpress/ /var/www/html/
#A sample configuration file that mostly matches the settings we need is included by default, so we need copy it 
#to the new wp-config.php and change the ownership of the 'html' folder
	cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
	chown -R apache:apache /var/www/html/*

#The rest of the script will interact with the user and ask if it has DataBase installed or not. If yes, you will be asked DataBase name
#user name and password to change configuration file. If you didn't install database yet, then will work scenario 'b', where it does secure
#installation, creates database, user with password and changes wp-config.php file

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
#Below two lines allow httpd to make network connection to mysql using port 3306
	setsebool -P httpd_can_network_connect 1
	setsebool -P httpd_can_network_connect_db 1
