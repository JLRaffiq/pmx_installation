# ### MOTD
# cat > /etc/profile.d/motd.sh << EOF
# #!/bin/sh
# echo ""
# echo " ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░"
# echo "     ██ ████ ███ ██ ████     ██    ████ ████ ████ ████ ██ ██ ████"
# echo "     ██ ██ █ ███ ██ ██       ██    ██ █ ██ █ ██ █ ██ █ ██ ██ ██  "
# echo "  ██ ██ ████ ██████ ████     ██    ████ ████ ██ █ ██ █ ██ ██ ████"
# echo "   ████ ██ █ ██ ███ ████     ████  ██ █ ██   ████ ████  ███  ████"
# echo ""
# echo " ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░"
# echo ""
# echo "              🚀 Proxmox VE Installation Script 🚀"
# echo "                Powered by JangLapoque Solutions"
# echo ""
# EOF
# chmod +x /etc/profile.d/motd.sh


Step 1: Create Container
1. Login Proxmox Web UI
2. Click "Create CT"
3. General:
  - CT ID: 200 (atau apa-apa)
  - Hostname: script-server
  - Template: Ubuntu 22.04 (download dulu kalau takde)
  - Disks: 8GB (cukup)
  - CPU: 1 core
  - Memory: 512MB
  - Network: Bridge vmbr0, DHCP
  - DNS: Auto
4. Click "Create" → "Start"

Step 2: Setup Web Server
# Enter container
pct enter 200

# Install nginx
apt update && apt install nginx -y
# Copy your script (guna editor atau scp)
nano /var/www/html/pve8.sh
nano /var/www/html/pve8-jedimaster.sh
nano /var/www/html/pve8-janglapoque.sh
# Paste kandungan pve8.sh
# Set permissions
chmod 644 /var/www/html/pve8.sh
chmod 644 /var/www/html/pve8-jedimaster.sh
chmod 644 /var/www/html/pve8-janglapoque.sh
# Configure nginx untuk serve .sh as text
echo 'server {
    listen 80;
    root /var/www/html;
    location ~ \.sh$ {
        add_header Content-Type text/plain;
    }
}' > /etc/nginx/sites-enabled/default
# Restart nginx
systemctl restart nginx

Step 3: Get IP & Test
# Check container IP
ip addr show eth0
# Test dari luar
curl CONTAINER_IP/pve8-jedimaster.sh | bash
curl CONTAINER_IP/pve8-janglapoque.sh | bash
curl CONTAINER_IP/pve8.sh | bash

Done! 3 steps sahaja! 🎉
Container awak siap serve script via HTTP. Simple kan? 😄

Step 4: (Optional) Setup SSH Access into Container
# This allows you to SSH directly into the container.
# All commands below are run inside the container (after 'pct enter 200').

# 1. Install OpenSSH Server
apt install openssh-server -y

# 2. Allow Root Login
# Edit the SSH config file
# nano /etc/ssh/sshd_config
# Find the line '#PermitRootLogin prohibit-password'
# and change it to 'PermitRootLogin yes'
# Then save and exit (Ctrl+O, Enter, Ctrl+X)
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# 3. Restart SSH Service
systemctl restart ssh

# 4. Find the container's IP address (if you forgot it from Step 3)
ip addr show eth0

# Now you can connect from your own computer using:
# ssh root@CONTAINER_IP
