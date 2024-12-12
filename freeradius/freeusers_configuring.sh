#!/bin/bash

# Check for root rights:
if [ "$(id -u)" -ne 0 ]; then
	echo "ERROR! Run this script with root privileges!"
	exit 1
fi

# Welcome message:
while true; do
	clear
	echo "***************************************************************************"
	echo "This script will help you create and configure additional FreeRADIUS users!"
	echo "***************************************************************************"
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

# Create additional FreeRADIUS users:
while true; do
	clear
	read -p "Would you like to create additional FreeRADIUS user? [Y/n]: " RES
	if [[ "$RES" == "Y" || "$RES" == "y" || "$RES" == "" ]]; then
		clear
		echo "Enter the credential of additional FreeRADIUS user:"
		echo
		read -p "Enter the name of additional FreeRADIUS user (e.g. user): " RADIUS_USER
		read -s -p "Enter the password for the FreeRADIUS user $RADIUS_USER: " RADIUS_PASSWORD

		# Add additional FreeRADIUS users in configuration file:
		cat <<EOF >> /etc/freeradius/3.0/mods-config/files/authorize

$RADIUS_USER Cleartext-Password := "$RADIUS_PASSWORD"
EOF
		clear
		echo "DONE! Additional FeeRADIUS user $RADIUS_USER created!"
		echo
		read -n1 -r -p "Press any key to continue..."
	elif [[ "$RES" == "N" || "$RES" == "n" ]]; then
		clear
		break
	else
		:
	fi
done

# Restart FreeRADIUS service:
systemctl restart freeradius

# Completion message:
if [ $? -eq 0 ]; then
	echo
	echo "DONE! FreeRADIUS is configured!"
	echo
else
	echo
	echo "ERROR! FreeRADIUS is not configured!"
	echo
fi

# Status of the FreeRADIUS service:
systemctl --no-pager status freeradius
echo
