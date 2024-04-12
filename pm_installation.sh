#!/bin/bash

# make sure root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Update system and install necessary packages
apt -y update

### Hostname-IP
hostname=`hostname`
ipadd=`ip addr show $(ip route | awk '/default/ { print $5 }') | grep "inet" | head -n 1 | awk '/inet/ {print $2}' | cut -d'/' -f1`
echo $hostname
echo $ipadd
sed -i "/$hostname/c$ipadd\t$hostname" /etc/hosts
hostname --ip-address

# Add the Proxmox VE Repository
apt -y install curl software-properties-common apt-transport-https ca-certificates gnupg2 
echo "deb [arch=amd64] http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-install-repo.list
wget -qO- https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg | apt-key add -

apt -y update && apt full-upgrade

apt install -y proxmox-default-kernel
apt -y install proxmox-ve postfix open-iscsi chrony

ss -tunpl | grep 8006

apt -y remove linux-image-amd64 'linux-image-6.1*'
update-grub

apt -y remove os-prober

reboot
