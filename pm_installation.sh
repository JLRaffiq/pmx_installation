# make sure root

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

apt update

### Hostname-IP
hostname=`hostname`
ipadd=`ip addr show $(ip route | awk '/default/ { print $5 }') | grep "inet" | head -n 1 | awk '/inet/ {print $2}' | cut -d'/' -f1`
echo $hostname
echo $ipadd
sed -i "/$hostname/c$ipadd\t$hostname" /etc/hosts
hostname --ip-address

# Add the Proxmox VE Repository
apt install curl software-properties-common apt-transport-https ca-certificates gnupg2 

echo "deb [arch=amd64] http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-install-repo.list

wget https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg  

apt update && apt full-upgrade

apt apt install proxmox-default-kernel -y

apt install proxmox-ve postfix open-iscsi chrony

ss -tunpl | grep 8006

apt remove linux-image-amd64 'linux-image-6.1*'

update-grub

apt remove os-prober

reboot
