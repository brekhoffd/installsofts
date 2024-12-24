#!/bin/bash

# Check for root rights:
if [ "$(id -u)" -ne 0 ]; then
	echo "ERROR! Run this script with root privileges!"
	exit 1
fi

# Welcome message:
while true; do
	clear
	echo "**********************************************************************"
	echo "This script will help you install and configure ZABBIX on your server!"
	echo "**********************************************************************"
	echo
	read -n1 -r -p "Press ENTER to continue or ESC to cancel..." KEY
	if [[ $KEY == "" ]]; then
		clear
		break
	elif [[ $KEY == $'\e' ]]; then
		clear
		exit 0
	else
		:
	fi
done

# Install and update locales:
apt install locales
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8

# Update repository and system:
apt update && apt full-upgrade -y

# Install PostgreSQL database:
apt install postgresql postgresql-contrib -y

# Add a ZABBIX repository:
wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_7.0-2+ubuntu24.04_all.deb
dpkg -i zabbix-release_7.0-2+ubuntu24.04_all.deb

# Update system and install ZABBIX:
apt update && apt full-upgrade -y
apt install zabbix-server-pgsql zabbix-frontend-php php8.3-pgsql zabbix-apache-conf zabbix-sql-scripts zabbix-agent -y

# Create new PostgreSQL database for ZABBIX:
sudo -u postgres createuser --pwprompt zabbix
sudo -u postgres createdb -O zabbix zabbix
zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u zabbix psql zabbix

# Backup ZABBIX default configuration file:
cp -p /etc/zabbix/zabbix_server.conf /etc/zabbix/zabbix_server.conf.bak

# Create new ZABBIX configuration file:
cat <<EOF > /etc/zabbix/zabbix_server.conf
# Logging settings
LogFile=/var/log/zabbix/zabbix_server.log
LogFileSize=0
LogSlowQueries=3000

# Process settings
PidFile=/run/zabbix/zabbix_server.pid
SocketDir=/run/zabbix

# Database settings
DBName=zabbix
DBUser=zabbix
DBPassword=zabbix

# SNMP settings
SNMPTrapperFile=/var/log/snmptrap/snmptrap.log
Timeout=10

# Network tools settings
FpingLocation=/usr/bin/fping
Fping6Location=/usr/bin/fping6

# Security and global settings
StatsAllowedIP=127.0.0.1
EnableGlobalScripts=0
EOF

# Restart ZABBIX service:
systemctl restart zabbix-server zabbix-agent apache2

# Enable ZABBIX service and completion message:
if [ $? -eq 0 ]; then
	echo
	systemctl enable zabbix-server zabbix-agent apache2
	echo
	echo "DONE! ZABBIX is installed and configured!"
	echo
else
	echo
	echo "ERROR! ZABBIX is not installed or configured!"
	echo
fi

# Status of the ZABBIX service:
systemctl --no-pager status zabbix-server
echo
