#!/bin/bash

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Add the Proxmox VE Repository
add_proxmox_repo() {
  echo "Adding Proxmox VE Repository..."
  echo "deb [arch=amd64] http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-install-repo.list
  wget -qO- https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg | apt-key add -
}

# Update system and install necessary packages
update_system() {
  echo "Updating system and installing necessary packages..."
  apt update
  apt install -y curl software-properties-common apt-transport-https ca-certificates gnupg2
}

# Install Proxmox VE
install_proxmox() {
  echo "Installing Proxmox VE..."
  apt update
  apt full-upgrade -y
  apt install -y proxmox-default-kernel proxmox-ve postfix open-iscsi chrony
}

# Remove unnecessary packages
cleanup() {
  echo "Cleaning up unnecessary packages..."
  apt remove -y linux-image-amd64 'linux-image-6.1*' os-prober
  update-grub
}

# Reboot the system
reboot_system() {
  echo "Rebooting the system..."
  reboot
}

# Main function
main() {
  add_proxmox_repo
  update_system
  install_proxmox
  cleanup
  reboot_system
}

# Execute main function
main
