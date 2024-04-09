#!/bin/bash

# Step 1: Update APT Cache
apt update
apt -y install wget

# Step 4: Add the Proxmox VE Repository
apt install curl software-properties-common apt-transport-https ca-certificates gnupg2 -y
echo "deb [arch=amd64] http://download.proxmox.com/debian/pve bookworm pve-no-subscription" | sudo tee /etc/apt/sources.list.d/pve-install-repo.list >/dev/null
wget https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg
apt update && sudo apt full-upgrade -y

# Step 5: Install the Proxmox Kernel
apt install proxmox-default-kernel -y

# Step 6: Install the Proxmox Packages
apt install proxmox-ve postfix open-iscsi chrony -y

# Step 7: Remove the Linux Kernel
apt remove linux-image-amd64 'linux-image-6.1*' -y
update-grub
apt remove os-prober -y

# Step 8: Reboot
reboot
