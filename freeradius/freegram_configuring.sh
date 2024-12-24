#!/bin/bash

# Check for root rights:
if [ "$(id -u)" -ne 0 ]; then
	echo "ERROR! Run this script with root privileges!"
	exit 1
fi

# Welcome message:
while true; do
	clear
	echo "************************************************************************************"
	echo "This script will help you configure Telegram notification on your FreeRADIUS server!"
	echo "************************************************************************************"
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
