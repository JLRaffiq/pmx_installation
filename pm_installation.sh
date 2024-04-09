#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Function to log messages
log() {
  logger -t setup-script -p local0.info "$1"
}

# Set up Proxmox repository
cat <<EOF > /etc/apt/sources.list.d/pve.list
deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription
EOF

# Install Proxmox keys
wget -qO- https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg | apt-key add -

# Update after adding Proxmox repository
apt -y update

# Install Proxmox Virtual Environment
apt -y install proxmox-ve

# Set hostname and IP
hostname=$(hostname)
ipadd=$(ip addr show $(ip route | awk '/default/ { print $5 }') | grep "inet" | head -n 1 | awk '/inet/ {print $2}' | cut -d'/' -f1)
log "Hostname: $hostname"
log "IP Address: $ipadd"
sed -i "/$hostname/c$ipadd\t$hostname" /etc/hosts
hostname --ip-address

# Set up postfix
debconf-set-selections <<< "postfix postfix/mailname string $hostname"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
apt -y install postfix

# Set up open-iscsi
apt -y install open-iscsi

# Reboot
log "Rebooting the system"
reboot
