#!/bin/bash

# Check for root rights:
if [ "$(id -u)" -ne 0 ]; then
	echo "ERROR! Run this script with root privileges!"
	exit 1
fi

# Welcome message:
while true; do
	clear
	echo "****************************************************************************"
	echo "This script will help you install and configure DHCP/Dnsmasq on your server!"
	echo "****************************************************************************"
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

# Install the DHCP/Dnsmasq software:
apt install dnsmasq -y

# Backup DHCP/Dnsmasq default configuration file:
cp -p /etc/dnsmasq.conf /etc/dnsmasq.conf.bak
clear

# Configure DHCP/Dnsmasq interface:
echo "Enter the current DHCP/Dnsmasq configuration:"
echo
read -p "Enter the IP address of the listening interface (e.g. 192.168.0.1): " INTERFACE_IP
read -p "Enter the IP address range for DHCP (e.g. 192.168.0.201,192.168.0.250): " DHCP_RANGE
read -p "Enter the subnet mask for DHCP (e.g. 255.255.255.0): " SUBNET_MASK
read -p "Enter the validity period of the IP address lease for DHCP (e.g. 12h): " DHCP_LEASE_TIME
read -p "Enter the IP address of the default gateway for DHCP (e.g. 192.168.0.254): " GATEWAY
read -p "Enter the remote DNS servers 1 (e.g. 8.8.8.8): " DNS_SERVER1
read -p "Enter the remote DNS servers 2 (e.g. 8.8.4.4): " DNS_SERVER2

# Create new DHCP/Dnsmasq configuration file:
cat <<EOF > /etc/dnsmasq.conf
# Settings up the listening interface:
interface=lo
listen-address=$INTERFACE_IP
bind-interfaces

# Defining the basic settings of the DHCP server:
dhcp-range=$DHCP_RANGE,$SUBNET_MASK,$DHCP_LEASE_TIME

# Settings the default gateway for the DHCP server:
dhcp-option=option:router,$GATEWAY

# DNS server settings for DHCP:
dhcp-option=option:dns-server,$INTERFACE_IP

# Settings of remote DNS servers:
server=$DNS_SERVER1
server=$DNS_SERVER2

# Domain name requirement for all requests:
domain-needed
domain=local

# Blocking of private IP addresses in requests:
bogus-priv
EOF
clear

# Restart DHCP/Dnsmasq service:
systemctl restart dnsmasq

# Enable DHCP/Dnsmasq service and completion message:
if [ $? -eq 0 ]; then
	echo
	systemctl enable dnsmasq
	echo
	echo "DONE! DHCP/Dnsmasq is installed and configured!"
	echo
else
	echo
	echo "ERROR! DHCP/Dnsmasq is not installed or configured!"
	echo
fi

# Status of the DHCP/Dnsmasq service:
systemctl --no-pager status dnsmasq
echo
