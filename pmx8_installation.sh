# REFER : https://pve.proxmox.com/wiki/Install_Proxmox_VE_on_Debian_12_Bookworm

### Phase 1 : Prepare #########################################################
# Must run ad ROOT
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

### Phase 2 : Debian ##########################################################
# Setup DNS
cat > /etc/resolv.conf << EOF
nameserver 1.1.1.1
EOF
# Setup Debian Repo
cat > /etc/apt/sources.list << EOF
deb http://ftp.jaist.ac.jp/debian bookworm main contrib
deb http://ftp.jaist.ac.jp/debian bookworm-updates main contrib
deb http://security.debian.org bookworm-security main contrib
EOF
# Update Debian Repo
apt -y update && apt -y dist-upgrade
# Setup Minimal Dependency
apt -y install ssh git wget curl gnupg

### Phase 3 : Proxmox #########################################################
# Setup Proxmox Repo
cat > /etc/apt/sources.list.d/pve.list << EOF
deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription
EOF
# Install Keys
wget https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/pve.gpg
chmod +r /etc/apt/trusted.gpg.d/pve.gpg
# Update Proxmox Repo
apt -y update && apt -y dist-upgrade
# Config Hostname-IP
hostname=`hostname`
ipadd=`ip addr show $(ip route | awk '/default/ { print $5 }') | grep "inet" | head -n 1 | awk '/inet/ {print $2}' | cut -d'/' -f1`
sed -i "/$hostname/c$ipadd\t$hostname" /etc/hosts
hostname --ip-address
# Install Proxmox
echo "postfix postfix/mailname string `hostname`" | debconf-set-selections
echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections
debconf-show postfix
echo "samba-common samba-common/workgroup string  WORKGROUP" | debconf-set-selections
echo "samba-common samba-common/dhcp boolean true" | debconf-set-selections
echo "samba-common samba-common/do_debconf boolean true" | debconf-set-selections
debconf-show samba-common
apt -y -d install proxmox-ve postfix open-iscsi
apt -y install proxmox-ve postfix open-iscsi
rm -rf /etc/apt/sources.list.d/pve-enterprise.list

### Phase 5 : Clean Up ########################################################
# Run Once After Reboot
croncmd="/usr/local/bin/runonce 2>&1"
cronjob="@reboot $croncmd"
( crontab -l | grep -v -F "$croncmd" ; echo "$cronjob" ) | crontab -
crontab -l
mkdir -p /etc/local/runonce.d/ran
cat > /usr/local/bin/runonce << EOF
#!/bin/sh
for file in /etc/local/runonce.d/*
do
    if [ ! -f "\$file" ]
    then
        continue
    fi
    "\$file"
    mv "\$file" "/etc/local/runonce.d/ran/\$(basename \$file).\$(date +%Y%m%dT%H%M%S)"
    logger -t runonce -p local3.info "\$file"
done
EOF
chmod +x /usr/local/bin/runonce
# Run One Time Clean Up for Proxmox Installation
cat > /etc/local/runonce.d/pmx-after-install-cleanup.sh << EOF
cat /etc/apt/sources.list.d/pve-enterprise.list
rm -rf /etc/apt/sources.list.d/pve-enterprise.list
rm -rf /etc/apt/sources.list.d/ceph.list
apt -y remove os-prober linux-image-amd64 'linux-image-*'
EOF
chmod 777 /etc/local/runonce.d/pmx-after-install-cleanup.sh

### Phase 6 : Reboot ##########################################################
apt -y autoremove
reboot

### Note : Become a Script ####################################################
# \     \\
# `     \`
# $     \$
