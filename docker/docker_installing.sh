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
	echo "This script will help you install and configure Docker on your server!"
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

# Add Docker's official GPG key:
apt install ca-certificates curl -y
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to apt sources:
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update system and install Docker:
apt update && apt full-upgrade -y
apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Restart Docker service:
systemctl restart docker

# Enable Docker service and completion message:
if [ $? -eq 0 ]; then
	echo
	systemctl enable docker
	echo
	echo "DONE! Docker is installed and configured!"
	echo
else
	echo
	echo "ERROR! Docker is not installed or configured!"
	echo
fi

# Status of the Docker service:
systemctl --no-pager status docker
echo
