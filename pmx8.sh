### Must ROOT
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi
#
### Setup Debian Repo
cat > /etc/apt/sources.list << EOF
deb http://ftp.jaist.ac.jp/debian/ bookworm main contrib non-free non-free-firmware
deb-src http://ftp.jaist.ac.jp/debian/ bookworm main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
deb-src http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
deb http://ftp.jaist.ac.jp/debian/ bookworm-updates main contrib non-free non-free-firmware
deb-src http://ftp.jaist.ac.jp/debian/ bookworm-updates main contrib non-free non-free-firmware
EOF
#
### Update 
apt -y update
apt -y dist-upgrade
#
### Minimal Dependency
apt -y install wget curl gnupg
#
### Setup Proxmox Repo
cat > /etc/apt/sources.list.d/pve.list << EOF
deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription
EOF
#
### Install Keys
wget https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/pve.gpg
chmod +r /etc/apt/trusted.gpg.d/pve.gpg
#
### Update 
apt -y update
apt -y dist-upgrade
#
### Hostname-IP
hostname=`hostname`
ipadd=`ip addr show $(ip route | awk '/default/ { print $5 }') | grep "inet" | head -n 1 | awk '/inet/ {print $2}' | cut -d'/' -f1`
echo $hostname
echo $ipadd
sed -i "/$hostname/c$ipadd\t$hostname" /etc/hosts
hostname --ip-address
#
### Setup Proxmox
debconf-set-selections <<< "postfix postfix/mailname string `hostname`"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
debconf-show postfix
echo "samba-common samba-common/workgroup string  WORKGROUP" | debconf-set-selections
echo "samba-common samba-common/dhcp boolean true" | debconf-set-selections
echo "samba-common samba-common/do_debconf boolean true" | debconf-set-selections
debconf-show samba-common
apt -y -d install proxmox-ve postfix open-iscsi
apt -y install proxmox-ve postfix open-iscsi
#
### Prepare Run Once
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
#
### Run Once to Clean Up Proxmox Installation
cat > /etc/local/runonce.d/pmx-after-install-cleanup.sh << EOF
cat /etc/apt/sources.list.d/pve-enterprise.list
rm -rf /etc/apt/sources.list.d/pve-enterprise.list
apt -y remove os-prober 'linux-image-*'
EOF
chmod 777 /etc/local/runonce.d/pmx-after-install-cleanup.sh
#
### Reboot
reboot
#
