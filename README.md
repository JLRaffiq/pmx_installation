# 🐳 Docker Setup untuk Proxmox Installation Scripts

Documentation lengkap untuk setup Docker container yang serve Proxmox VE installation scripts melalui HTTP.

## 📋 Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [File Structure](#file-structure)
- [Setup Process](#setup-process)
- [Usage](#usage)
- [Management Commands](#management-commands)
- [Troubleshooting](#troubleshooting)
- [Advanced Configuration](#advanced-configuration)

## 🎯 Overview

Project ini membolehkan anda untuk:
- Serve Proxmox VE installation scripts via HTTP menggunakan Docker
- Access scripts dari mana-mana komputer dalam network
- Execute scripts secara remote menggunakan `curl | bash`
- Simple nginx container setup tanpa complexity yang tidak perlu

## 🔧 Prerequisites

- Windows 10/11 dengan Docker Desktop
- Docker Desktop running
- PowerShell atau Command Prompt
- Network access untuk download images

## 🚀 Quick Start

### 1. Start Docker Desktop
```powershell
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
```

### 2. Clone/Download Files
Pastikan anda ada files berikut dalam directory:
- `docker-compose-simple.yml`
- `pve8-jedimaster.sh`
- `pve8.sh` 
- `pve8-janglapoque.sh`
- Files lain (banner.txt, images, etc.)

### 3. Start Container
```powershell
docker-compose -f docker-compose-simple.yml up -d
```

### 4. Test Access
```powershell
curl http://localhost:8080/pve8-jedimaster.sh | Select-Object -First 5
```

## 📁 File Structure

```
pmx_installation/
├── docker-compose-simple.yml    # Simple nginx container config
├── docker-compose.yml           # Advanced container config (optional)
├── Dockerfile                   # Custom image build file (optional)
├── .dockerignore               # Files to ignore during build
├── Makefile                    # Easy management commands
├── README-DOCKER.md            # Advanced Docker documentation
├── README.md                   # This file
├── pve8-jedimaster.sh          # Jedi Master edition script
├── pve8.sh                     # Standard Proxmox installation script
├── pve8-janglapoque.sh         # JangLapoque edition script
├── banner.txt                  # Banner file
├── logo janglapoque.jpg        # Logo image
└── notes.sh                    # Installation notes
```

## 🔨 Setup Process

### Step 1: Docker Desktop Setup
1. Install Docker Desktop dari [docker.com](https://docker.com)
2. Start Docker Desktop application
3. Tunggu hingga Docker daemon running (indicator hijau)

### Step 2: Container Configuration
File `docker-compose-simple.yml` contains:
```yaml
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    container_name: pmx-nginx
    ports:
      - "8080:80"
    volumes:
      - ./:/usr/share/nginx/html:ro
    restart: unless-stopped
    command: >
      sh -c "
      echo 'server {
          listen 80;
          server_name localhost;
          root /usr/share/nginx/html;
          
          location ~ \.sh$ {
              add_header Content-Type text/plain;
              add_header Access-Control-Allow-Origin *;
          }
          
          location / {
              autoindex on;
              autoindex_exact_size off;
              autoindex_localtime on;
          }
      }' > /etc/nginx/conf.d/default.conf &&
      nginx -g 'daemon off;'
      "
```

### Step 3: Nginx Configuration
Container automatically configure nginx untuk:
- Serve `.sh` files sebagai `text/plain`
- Enable directory listing (`autoindex`)
- Add CORS headers untuk cross-origin access
- Mount current directory sebagai web root

## 📖 Usage

### Method 1: Direct Execution via cURL
```bash
# Jedi Master edition
curl -fsSL http://localhost:8080/pve8-jedimaster.sh | bash

# Standard edition
curl -fsSL http://localhost:8080/pve8.sh | bash

# JangLapoque edition
curl -fsSL http://localhost:8080/pve8-janglapoque.sh | bash
```

### Method 2: Download then Execute
```bash
# Download script
wget http://localhost:8080/pve8-jedimaster.sh

# Make executable
chmod +x pve8-jedimaster.sh

# Execute
./pve8-jedimaster.sh
```

### Method 3: Remote Access
Dari komputer lain dalam network:
```bash
curl -fsSL http://YOUR_WINDOWS_IP:8080/pve8-jedimaster.sh | bash
```

### Method 4: Web Browser
Browse ke `http://localhost:8080` untuk list semua available files.

## 🎛️ Management Commands

### Container Management
```powershell
# Start container
docker-compose -f docker-compose-simple.yml up -d

# Stop container
docker-compose -f docker-compose-simple.yml down

# Restart container
docker-compose -f docker-compose-simple.yml restart

# View logs
docker logs pmx-nginx

# Check status
docker ps
```

### Monitoring
```powershell
# Check container status
docker inspect pmx-nginx | findstr '"IPAddress"'

# View nginx logs
docker logs pmx-nginx -f

# Test connectivity
curl -I http://localhost:8080/health
```

### Updates
```powershell
# Restart after script updates
docker restart pmx-nginx

# Rebuild if needed
docker-compose -f docker-compose-simple.yml up -d --force-recreate
```

## 🐛 Troubleshooting

### Docker Desktop tidak running
**Problem:** `error during connect: Get "http://...": The system cannot find the file specified`

**Solution:**
```powershell
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
Start-Sleep 15
docker info
```

### Port 8080 sudah digunakan
**Problem:** `bind: address already in use`

**Solution:** 
1. Check apa yang guna port 8080:
```powershell
netstat -tulpn | findstr :8080
```
2. Kill process atau tukar port dalam `docker-compose-simple.yml`

### Scripts tidak accessible
**Problem:** 404 atau permission errors

**Solution:**
```powershell
# Check files ada dalam directory
ls *.sh

# Check container logs
docker logs pmx-nginx

# Restart container
docker restart pmx-nginx
```

### Content-Type tidak betul
**Problem:** Scripts download sebagai binary instead of text

**Solution:** Container sudah configured untuk serve `.sh` files sebagai `text/plain`. Jika masih ada masalah:
```powershell
docker exec pmx-nginx nginx -s reload
```

## ⚙️ Advanced Configuration

### Custom Port
Edit `docker-compose-simple.yml`:
```yaml
ports:
  - "3000:80"  # Change 8080 to 3000
```

### Add SSL/HTTPS
Untuk production, tambah reverse proxy dengan SSL:
```yaml
# Add to docker-compose-simple.yml
  nginx-proxy:
    image: nginxproxy/nginx-proxy
    ports:
      - "443:443"
    volumes:
      - /var/run/docker.sock:/tmp/docker.sock:ro
      - ./certs:/etc/nginx/certs
```

### Custom Domain
Add to `/etc/hosts` (atau Windows equivalent):
```
127.0.0.1 scripts.local
```

Then access via `http://scripts.local:8080`

### Network Isolation
```yaml
networks:
  scripts-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

## 📊 Container Details

- **Container Name:** `pmx-nginx`
- **Base Image:** `nginx:alpine`
- **Port Mapping:** `8080:80`
- **Volume Mount:** `./:/usr/share/nginx/html:ro`
- **Restart Policy:** `unless-stopped`
- **Network:** Bridge (default)

## 🔒 Security Notes

- Container running sebagai read-only volume mount
- Scripts served via HTTP (consider HTTPS untuk production)
- Container isolated dalam Docker network
- No persistent data storage dalam container
- Automatic restart configured

## 🚀 Next Steps

1. **Production Setup:** Add HTTPS dengan reverse proxy
2. **Monitoring:** Setup log aggregation dan monitoring
3. **Backup:** Automatic backup scripts to cloud storage
4. **CI/CD:** Automatic deployment dengan GitHub Actions
5. **Load Balancing:** Multiple containers dengan load balancer

---

## 📝 Quick Reference Commands

```powershell
# Essential commands untuk daily use
docker-compose -f docker-compose-simple.yml up -d    # Start
docker-compose -f docker-compose-simple.yml down     # Stop
docker ps                                             # Status
docker logs pmx-nginx                                # Logs
curl http://localhost:8080/                          # Test
```

**Happy scripting! 🎉**

---
*Documentation created: $(Get-Date)*  
*Docker Setup Version: 1.0*  
*Author: Assistant*
