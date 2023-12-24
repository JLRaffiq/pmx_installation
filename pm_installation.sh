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

# Set up Debian repository
cat <<EOF > /etc/apt/sources.list
deb http://ftp.jaist.ac.jp/debian/ bookworm main contrib non-free non-free-firmware
deb-src http://ftp.jaist.ac.jp/debian/ bookworm main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
deb-src http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
deb http://ftp.jaist.ac.jp/debian/ bookworm-updates main contrib non-free non-free-firmware
deb-src http://ftp.jaist.ac.jp/debian/ bookworm-updates main contrib non-free non-free-firmware
EOF

# Update and upgrade
apt -y update
apt -y dist-upgrade

# Install minimal dependencies
apt -y install wget curl gnupg

# Set up Proxmox repository
cat <<EOF > /etc/apt/sources.list.d/pve.list
deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription
EOF

# Install Proxmox keys
wget https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/pve.gpg
chmod +r /etc/apt/trusted.gpg.d/pve.gpg

# Update again after adding Proxmox repository
apt -y update
apt -y dist-upgrade

# Set hostname and IP
hostname=$(hostname)
ipadd=$(ip addr show $(ip route | awk '/default/ { print $5 }') | grep "inet" | head -n 1 | awk '/inet/ {print $2}' | cut -d'/' -f1)
log "Hostname: $hostname"
log "IP Address: $ipadd"
sed -i "/$hostname/c$ipadd\t$hostname" /etc/hosts
hostname --ip-address

# Set up Proxmox
debconf-set-selections <<< "postfix postfix/mailname string $hostname"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
debconf-show postfix
echo "samba-common samba-common/workgroup string WORKGROUP" | debconf-set-selections
echo "samba-common samba-common/dhcp boolean true" | debconf-set-selections
echo "samba-common samba-common/do_debconf boolean true" | debconf-set-selections
debconf-show samba-common
apt -y -d install proxmox-ve postfix open-iscsi
apt -y install proxmox-ve postfix open-iscsi

# Prepare Run Once
croncmd="/usr/local/bin/runonce 2>&1"
cronjob="@reboot $croncmd"
( crontab -l | grep -v -F "$croncmd" ; echo "$cronjob" ) | crontab -
crontab -l

# Create runonce script
cat <<EOF > /usr/local/bin/runonce
#!/bin/sh
for file in /etc/local/runonce.d/*
do
    if [ ! -f "\$file" ]; then
        continue
    fi
    "\$file"
    mv "\$file" "/etc/local/runonce.d/ran/\$(basename \$file).\$(date +%Y%m%dT%H%M%S)"
    log "\$file"
done
EOF
chmod +x /usr/local/bin/runonce

# Run Once to Clean Up Proxmox Installation
cat <<EOF > /etc/local/runonce.d/pmx-after-install-cleanup.sh
cat /etc/apt/sources.list.d/pve-enterprise.list
rm -rf /etc/apt/sources.list.d/pve-enterprise.list
apt -y remove os-prober 'linux-image-*'
EOF
chmod 755 /etc/local/runonce.d/pmx-after-install-cleanup.sh

# Reboot
log "Rebooting the system"
reboot
