#!/bin/bash

# Check for root rights:
if [ "$(id -u)" -ne 0 ]; then
	echo "ERROR! Run this script with root privileges!"
	exit 1
fi

# Welcome message:
while true; do
	clear
	echo "***********************************************************************"
	echo "This script will help you install and configure Jenkins on your server!"
	echo "***********************************************************************"
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

# Install additional software:
apt install fontconfig openjdk-17-jre -y

# Add a Jenkins repository:
wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" https://pkg.jenkins.io/debian-stable binary/ | tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update system and install Jenkins:
apt update && apt full-upgrade -y
apt install jenkins -y

# Restart Jenkins service:
systemctl restart jenkins

# Enable Jenkins service and completion message:
if [ $? -eq 0 ]; then
	echo
	systemctl enable jenkins
	echo
	echo "DONE! Jenkins is installed and configured!"
	echo
else
	echo
	echo "ERROR! Jenkins is not installed or configured!"
	echo
fi

# Status of the Jenkins service:
systemctl --no-pager status jenkins
echo
