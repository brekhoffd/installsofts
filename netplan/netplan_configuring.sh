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
	echo "This script will help you configure your network settings from Netplan!"
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

# The name of the network interface:
echo "ATTENTION! Remember or write down the name of your network interface!"
echo
ip addr
echo
read -n1 -r -p "Press any key to continue..."

# Backup Netplan default configuration file:
mv /etc/netplan/*.yaml /etc/netplan/00-default-config.yaml.bak
clear

# Configure Netplan interface:
echo "Enter the current Netplan configuration:"
echo
read -p "Enter the name of the network interface (e.g. eth0): " INTERFACE_NAME
read -p "Enter the static IP address (e.g. 192.168.0.1): " STATIC_IP
read -p "Enter the subnet mask (e.g. 24): " SUBNET_MASK
read -p "Enter the default gateway (e.g. 192.168.0.254): " GATEWAY
read -p "Enter the remote DNS servers 1 (e.g. 8.8.8.8): " DNS_SERVER1
read -p "Enter the remote DNS servers 2 (e.g. 8.8.4.4): " DNS_SERVER2

# Create new Netplan configuration file:
cat <<EOF > /etc/netplan/00-users-config.yaml
network:
  version: 2
  ethernets:
    $INTERFACE_NAME:
      dhcp4: false
      addresses:
        - $STATIC_IP/$SUBNET_MASK
      routes:
        - to: default
          via: $GATEWAY
      nameservers:
        search:
          - netplanlab.local
        addresses:
          - $DNS_SERVER1
          - $DNS_SERVER2
EOF

# Apply settings:
while true; do
	clear
	echo "WARNING! If you apply the network settings now, you may lose connection to the server!"
	echo
	read -p "Do you want to apply the network settings now? [Y/n]: " RES
	if [[ "$RES" == "Y" || "$RES" == "y" || "$RES" == "" ]]; then
		clear
		echo "The network settings apply..."
		netplan apply
		echo
		echo "DONE! The network settings have been applied!"
		echo
		ip addr
		echo
		exit 0
	elif [[ "$RES" == "N" || "$RES" == "n" ]]; then
		clear
		echo "ATTENTION! The network settings will be applied after reboot!"
		echo
		exit 0
	else
		:
	fi
done
