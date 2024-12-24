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
	echo "This script will help you install and configure FreeRADIUS on your server!"
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

# Install and update locales:
apt install locales
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8

# Update repository and system:
apt update && apt full-upgrade -y

# Install the FreeRADIUS software:
apt install freeradius -y

# Backup FreeRADIUS users default configuration file:
cp -p /etc/freeradius/3.0/mods-config/files/authorize /etc/freeradius/3.0/mods-config/files/authorize.bak
clear

# Configure first FreeRADIUS user:
echo "Enter the credential of the first FreeRADIUS user:"
echo
read -p "Enter the name of the first FreeRADIUS user (e.g. user): " RADIUS_USER
read -s -p "Enter the password for the FreeRADIUS user $RADIUS_USER: " RADIUS_PASSWORD

# Add first FreeRADIUS users in configuration file:
cat <<EOF >> /etc/freeradius/3.0/mods-config/files/authorize

# Users
$RADIUS_USER Cleartext-Password := "$RADIUS_PASSWORD"
EOF
clear
echo "DONE! First FreeRADIUS user $RADIUS_USER created!"
echo
read -n1 -r -p "Press any key to continue..."

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

# Backup client default configuration file:
cp -p /etc/freeradius/3.0/clients.conf /etc/freeradius/3.0/clients.conf.bak
clear

# Configure client interface:
echo "Enter the client interface configuration:"
echo
read -p "Enter the name of your client interface (e.g. router): " CLIENT_NAME
read -p "Enter the IP address of your client $CLIENT_NAME (e.g. 192.168.0.254): " CLIENT_IP
read -s -p "Enter the secret password of your client $CLIENT_NAME: " CLIENT_SECRET

# Add new client in configuration file:
cat <<EOF >> /etc/freeradius/3.0/clients.conf

# Clients
client $CLIENT_NAME {
	ipaddr = $CLIENT_IP
	secret = $CLIENT_SECRET
}
EOF
clear
echo "DONE! Client $CLIENT_NAME created!"
echo
read -n1 -r -p "Press any key to continue..."

# Configure Telegram notification script:
while true; do
	clear
	read -p "Would you like to set up a Telegram notification? [Y/n]: " TEL
	if [[ "$TEL" == "Y" || "$TEL" == "y" || "$TEL" == "" ]]; then
		apt install curl -y
		mkdir /etc/freeradius/3.0/scripts/
		clear
		echo "Enter the credential of your Telegram Bot:"
		echo
		read -p "Enter your Telegram Bot TOKEN: " TELEGRAM_TOKEN
		read -p "Enter your Telegram Chat ID: " CHAT_ID

		# Create Telegram notification script:
		cat <<EOF > /etc/freeradius/3.0/scripts/telegram_notify.sh
#!/bin/bash

TELEGRAM_TOKEN="$TELEGRAM_TOKEN"
CHAT_ID="$CHAT_ID"

USER_NAME=\$1
PACKET_TYPE=\$2
CALLING_STATION_ID=\$3

# if [[ "\$PACKET_TYPE" == "Access-Accept" ]]; then
if [[ "\$PACKET_TYPE" == "Access-Reject" ]]; then
#	MESSAGE=\$(echo -e "✅ Authorization success!\n\nUser: \${USER_NAME}\nMAC: \${CALLING_STATION_ID}\n\nType: \${PACKET_TYPE}")
# else
	MESSAGE=\$(echo -e "⛔️ Authorization denied!\n\nUser: \${USER_NAME}\nMAC: \${CALLING_STATION_ID}\n\nType: \${PACKET_TYPE}")
else
	:
fi

curl -s -X POST "https://api.telegram.org/bot\$TELEGRAM_TOKEN/sendMessage" -d chat_id="\$CHAT_ID" -d text="\$MESSAGE"
EOF
		chmod +x /etc/freeradius/3.0/scripts/telegram_notify.sh
		chown --reference=/etc/freeradius/3.0/sites-available/ /etc/freeradius/3.0/scripts/
		chown --reference=/etc/freeradius/3.0/scripts/ /etc/freeradius/3.0/scripts/telegram_notify.sh
		cat <<EOF >> /etc/freeradius/3.0/mods-available/exec

exec send_notification {
	wait = no
	input_pairs = request
	program = "/etc/freeradius/3.0/scripts/telegram_notify.sh %{User-Name} %{reply:Packet-Type} %{Calling-Station-Id}"
	output = none
}
EOF
		cp -p /etc/freeradius/3.0/sites-available/default /etc/freeradius/3.0/sites-available/default.bak
		curl -o /etc/freeradius/3.0/sites-available/default https://raw.githubusercontent.com/brekhoffd/installsofts/refs/heads/main/freeradius/default
		chown --reference=/etc/freeradius/3.0/sites-available/default.bak /etc/freeradius/3.0/sites-available/default
		clear
		echo "DONE! Telegram notification is configured and activated!"
		echo
		read -n1 -r -p "Press any key to continue..."
		clear
		break
	elif [[ "$TEL" == "N" || "$TEL" == "n" ]]; then
		clear
		break
	else
		:
	fi
done

# Restart FreeRADIUS service:
systemctl restart freeradius

# Enable FreeRADIUS service and completion message:
if [ $? -eq 0 ]; then
	echo
	systemctl enable freeradius
	echo
	echo "DONE! FreeRADIUS is installed and configured!"
	echo
else
	echo
	echo "ERROR! FreeRADIUS is not installed or configured!"
	echo
fi

# Status of the FreeRADIUS service:
systemctl --no-pager status freeradius
echo
