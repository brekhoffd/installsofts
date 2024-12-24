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
	echo "This script will help you install and configure Ansible on your server!"
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
apt install software-properties-common -y

# Add a Ansible repository:
add-apt-repository --yes --update ppa:ansible/ansible

# Update system and install Ansible:
apt update && apt full-upgrade -y
apt install ansible -y

# Completion message:
echo
echo "DONE! Ansible is installed and configured!"
echo

# Version of the Ansible:
ansible --version
echo
