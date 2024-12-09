#!/bin/bash

# Check for root rights:
if [ "$(id -u)" -ne 0 ]; then
	echo "ERROR! Run this script with root privileges!"
	exit 1
fi

# Welcome message:
while true; do
	clear
	echo "**************************************************************************"
	echo "This script will help you install and configure Proxmox VE on your server!"
	echo "**************************************************************************"
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

# Install and configure Proxmox:
while true; do
	echo "If you are running this script for the first time,"
	echo "select Step 1! If this is complete, select Step 2!"
	echo
	read -p "Enter the number of Step [1 or 2]: " STEP
	if [[ "$STEP" == "1" ]]; then
		clear
		read -n1 -r -p "Step 1! Press any key to continue..."
		clear

		# Change the IP address of the node:
		echo "In the next window change the internal IP address of your node"
		echo "127.0.1.1 to the static IP address this server on the network!"
		echo
		read -n1 -r -p "Press any key to change IP address..."
		nano /etc/hosts
		clear
		read -n1 -r -p "DONE! Press any key to continue..."
		clear

		# Adapt sources.list:
		echo "deb [arch=amd64] http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-install-repo.list

		# Add the Proxmox VE repository key:
		wget https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg

		# Update repository and system:
		apt update && apt full-upgrade -y

		# Install the Proxmox VE kernel:
		apt install proxmox-default-kernel -y
		clear

		# Completion message for Step 1:
		echo "DONE! Step 1 is complete!"
		echo
		echo "Run this script again and do Step 2 after reboot!"
		echo
		read -n1 -r -p "Press any key to reboot..."
		systemctl reboot
	elif [[ "$STEP" == "2" ]]; then
		clear
		read -n1 -r -p "Step 2! Press any key to continue..."
		clear

		# Install the Proxmox VE packages:
		apt install proxmox-ve postfix open-iscsi chrony -y

		# Remove the Debian kernel:
		apt remove linux-image-amd64 'linux-image-6.1*' -y

		# Update and check GRUB2 config:
		update-grub

		# Remove the OS-Prober package:
		apt remove os-prober -y
		clear

		# Completion message for Step 2:
		echo "DONE! Step 2 is complete!"
		echo
		echo "You can start using Proxmox VE after reboot!"
		echo
		read -n1 -r -p "Press any key to reboot..."
		systemctl reboot
	else
		clear
		echo "ERROR! 1 or 2 only!"
		echo
	fi
done
