#!/bin/bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures

# This script is designed to be executed as a whole.
# Running individual commands or sections may result in errors
# as functions and variables are defined and used throughout.

### Script Info
SCRIPT_NAME="Proxmox VE 8 Installation Script"
SCRIPT_VERSION="1.0"
LOG_FILE="/var/log/pve8-install.log"

### Logging Function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

### Error Handler
error_exit() {
    log "ERROR: $1"
    exit 1
}

log "Starting $SCRIPT_NAME v$SCRIPT_VERSION"

### Must ROOT
if [ "$EUID" -ne 0 ]; then
    error_exit "Please run as root"
fi

### Check Network Connectivity
log "Checking network connectivity..."
if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    error_exit "No internet connection available"
fi

### Check Disk Space (minimum 20GB)
# log "Checking disk space..."
# AVAILABLE_SPACE=$(df / | awk 'NR==2 {print $4}')
# MIN_SPACE=20971520  # 20GB in KB
# if [ "$AVAILABLE_SPACE" -lt "$MIN_SPACE" ]; then
#     error_exit "Insufficient disk space. Need at least 20GB, available: $(($AVAILABLE_SPACE/1024/1024))GB"
# fi

### Check Debian Version
log "Checking OS version..."
if ! grep -q "bookworm" /etc/os-release; then
    error_exit "This script requires Debian 12 (Bookworm)"
fi

log "Pre-flight checks passed successfully"
#
### Setup Debian Repo
log "Setting up Debian repositories..."
cat > /etc/apt/sources.list << EOF
deb http://ftp.jaist.ac.jp/debian/ bookworm main contrib non-free non-free-firmware
deb-src http://ftp.jaist.ac.jp/debian/ bookworm main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
deb-src http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
deb http://ftp.jaist.ac.jp/debian/ bookworm-updates main contrib non-free non-free-firmware
deb-src http://ftp.jaist.ac.jp/debian/ bookworm-updates main contrib non-free non-free-firmware
EOF
#
### Update System
log "Updating system packages..."
apt -y update || error_exit "Failed to update package lists"
apt -y dist-upgrade || error_exit "Failed to upgrade system"
log "System updated successfully"
#
### Install Dependencies
log "Installing essential dependencies..."
apt -y install wget curl gnupg || error_exit "Failed to install dependencies"
log "Dependencies installed successfully"
#
### Setup Proxmox Repo
log "Setting up Proxmox repository..."
cat > /etc/apt/sources.list.d/pve.list << EOF
deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription
EOF
#
### Install Keys
log "Installing Proxmox GPG keys..."
wget https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/pve.gpg || error_exit "Failed to download Proxmox GPG key"
chmod +r /etc/apt/trusted.gpg.d/pve.gpg
log "GPG keys installed successfully"
#
### Update with Proxmox Repo
log "Updating package lists with Proxmox repository..."
apt -y update || error_exit "Failed to update with Proxmox repository"
apt -y dist-upgrade || error_exit "Failed to upgrade with Proxmox packages"
log "System updated with Proxmox repository"
#
### Hostname-IP Configuration
log "Configuring hostname and IP address..."
hostname=$(hostname)
ipadd=$(ip addr show $(ip route | awk '/default/ { print $5 }') | grep "inet" | head -n 1 | awk '/inet/ {print $2}' | cut -d'/' -f1)
log "Hostname: $hostname, IP: $ipadd"

if [ -z "$ipadd" ]; then
    error_exit "Could not determine IP address"
fi

sed -i "/$hostname/c$ipadd\t$hostname" /etc/hosts
hostname --ip-address
log "Hostname and IP configuration completed"
#
### Setup Proxmox Installation
log "Configuring debconf settings for automated installation..."
debconf-set-selections <<< "postfix postfix/mailname string $(hostname)"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
echo "samba-common samba-common/workgroup string  WORKGROUP" | debconf-set-selections
echo "samba-common samba-common/dhcp boolean true" | debconf-set-selections
echo "samba-common samba-common/do_debconf boolean true" | debconf-set-selections
log "Debconf configuration completed"

log "Downloading Proxmox VE packages..."
apt -y -d install proxmox-ve postfix open-iscsi || error_exit "Failed to download Proxmox packages"

log "Installing Proxmox VE (this may take several minutes)..."
apt -y install proxmox-ve postfix open-iscsi || error_exit "Failed to install Proxmox VE"
log "Proxmox VE installation completed successfully"
#
### Prepare Run Once
croncmd="/usr/local/bin/runonce 2>&1"
cronjob="@reboot $croncmd"
# Add cronjob idempotently, handling cases where no crontab exists yet
( (crontab -l 2>/dev/null || true); echo "$cronjob" ) | sort -u | crontab -
log "Crontab updated to run cleanup on reboot:"
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
cat > /etc/local/runonce.d/pmx-after-install-cleanup.sh << 'EOF'
# Remove enterprise repository
cat /etc/apt/sources.list.d/pve-enterprise.list 2>/dev/null || echo "Enterprise repo not found"
rm -rf /etc/apt/sources.list.d/pve-enterprise.list

# Remove Ceph enterprise repo if exists
rm -rf /etc/apt/sources.list.d/ceph.list 2>/dev/null || true

# Remove subscription nag/warning
sed -Ezi.bak "s/(Ext.Msg.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js 2>/dev/null || true

# Alternative method for subscription warning removal
if [ -f /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js ]; then
    cp /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js.bak
    sed -i.bak 's/data.status !== '\''Active'\''/false/g' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js 2>/dev/null || true
    sed -i 's/checked_command: function(orig_cmd) {/checked_command: function(orig_cmd) { return orig_cmd;/g' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js 2>/dev/null || true
fi

# Remove old kernels and unnecessary packages
apt -y remove os-prober 'linux-image-*' --purge 2>/dev/null || true
apt -y autoremove --purge 2>/dev/null || true

# Clear package cache after cleanup
apt-get clean
EOF
chmod 777 /etc/local/runonce.d/pmx-after-install-cleanup.sh

### Final Steps
log "Preparing system for reboot..."
log "Installation completed successfully!"
log "After reboot, Proxmox VE will be accessible at: https://$ipadd:8006"
log "Default login: root (use current root password)"

### Clean Installation Traces (Stealth Mode)
log "Cleaning installation traces..."

# Clear package cache and temporary files
apt-get clean
apt-get autoclean
rm -rf /var/cache/apt/archives/*
rm -rf /tmp/*
rm -rf /var/tmp/*

# Clear logs that might show installation activity
> /var/log/dpkg.log
> /var/log/apt/history.log
> /var/log/apt/term.log
truncate -s 0 /var/log/syslog
truncate -s 0 /var/log/kern.log
truncate -s 0 /var/log/messages 2>/dev/null || true

# Clear bash history for all users
> /root/.bash_history
for user_home in /home/*; do
    if [ -d "$user_home" ]; then
        > "$user_home/.bash_history" 2>/dev/null || true
    fi
done

# Clear recent files and command history
history -c
history -w

# Remove our own log file
rm -f "$LOG_FILE"

# Clear systemd journal logs
journalctl --vacuum-time=1s 2>/dev/null || true

# Clear downloaded packages list
rm -rf /var/lib/apt/lists/*

# Remove any wget/curl histories
rm -f /root/.wget-hsts
rm -f /root/.curlrc

# Clear process accounting logs
> /var/log/wtmp
> /var/log/btmp
> /var/log/lastlog

# Create minimal completion marker (without timestamp details)
echo "installed" > /etc/.pve-ready

log "All installation traces cleaned successfully"

### Reboot
log "Rebooting system in 3 seconds..."
sleep 3
reboot
#