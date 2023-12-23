#!/bin/bash

# Log all output to a file
exec > >(tee -a /var/log/proxmox_installation.log)
exec 2>&1

# Check if Proxmox is already installed
if dpkg -l | grep -q proxmox-ve; then
    echo "Proxmox VE is already installed. Exiting."
    exit 1
fi

# Set variables
PROXMOX_REPO="http://download.proxmox.com/debian/pve"
PROXMOX_GPG_URL="https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg"

# Phase 1: Prepare
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# Phase 2: Debian
read -p "Enter the hostname: " hostname
read -p "Enter the IP address: " ipadd

cat > /etc/resolv.conf << EOF
nameserver 1.1.1.1
EOF

cat > /etc/apt/sources.list << EOF
deb http://ftp.jaist.ac.jp/debian bookworm main contrib
deb http://ftp.jaist.ac.jp/debian bookworm-updates main contrib
deb http://security.debian.org bookworm-security main contrib
EOF

apt -y update && apt -y dist-upgrade
apt -y install ssh git wget curl gnupg

# Phase 3: Proxmox
cat > /etc/apt/sources.list.d/pve.list << EOF
deb $PROXMOX_REPO bookworm pve-no-subscription
EOF

wget $PROXMOX_GPG_URL -O /etc/apt/trusted.gpg.d/pve.gpg
chmod +r /etc/apt/trusted.gpg.d/pve.gpg

apt -y update && apt -y dist-upgrade

sed -i "/$hostname/c$ipadd\t$hostname" /etc/hosts
hostname --ip-address

echo "postfix postfix/mailname string $hostname" | debconf-set-selections
echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections
echo "samba-common samba-common/workgroup string  WORKGROUP" | debconf-set-selections
echo "samba-common samba-common/dhcp boolean true" | debconf-set-selections
echo "samba-common samba-common/do_debconf boolean true" | debconf-set-selections

apt -y -d install proxmox-ve postfix open-iscsi
apt -y install proxmox-ve postfix open-iscsi
rm -rf /etc/apt/sources.list.d/pve-enterprise.list

# Phase 5: Clean Up
croncmd="/usr/local/bin/runonce 2>&1"
cronjob="@reboot $croncmd"
( crontab -l | grep -v -F "$croncmd" ; echo "$cronjob" ) | crontab -
crontab -l

mkdir -p /etc/local/runonce.d/ran
cat > /usr/local/bin/runonce << EOF
#!/bin/sh
for file in /etc/local/runonce.d/*
do
    if [ ! -f "\$file" ] || [ ! -x "\$file" ]; then
        continue
    fi
    "\$file"
    mv "\$file" "/etc/local/runonce.d/ran/\$(basename \$file).\$(date +%Y%m%dT%H%M%S)"
    logger -t runonce -p local3.info "\$file"
done
EOF

chmod +x /usr/local/bin/runonce

cat > /etc/local/runonce.d/pmx-after-install-cleanup.sh << EOF
cat /etc/apt/sources.list.d/pve-enterprise.list
rm -rf /etc/apt/sources.list.d/pve-enterprise.list
rm -rf /etc/apt/sources.list.d/ceph.list
apt -y remove os-prober linux-image-amd64 'linux-image-*'
EOF

chmod 777 /etc/local/runonce.d/pmx-after-install-cleanup.sh

# Phase 6: Reboot
apt -y autoremove

# Verify changes
if [ $? -eq 0 ]; then
    echo "Proxmox VE installation completed successfully."
else
    echo "Proxmox VE installation encountered errors. Please check the logs."
fi

reboot
