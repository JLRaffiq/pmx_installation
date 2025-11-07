# 🐳 Docker Setup untuk Proxmox Installation Scripts

Docker setup ini membolehkan anda serve Proxmox installation scripts melalui HTTP server yang mudah diakses.

## 🚀 Quick Start

### Method 1: Menggunakan Docker Compose (Recommended)

```bash
# Build dan start container
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

Container akan accessible di: `http://localhost:8080`

### Method 2: Menggunakan Docker secara manual

```bash
# Build image
docker build -t pmx-scripts .

# Run container
docker run -d \
  --name pmx-script-server \
  -p 8080:80 \
  --restart unless-stopped \
  pmx-scripts

# Check status
docker ps
```

## 📋 Menggunakan Scripts

Setelah container running, anda boleh access scripts dengan cara:

### Web Interface
Buka browser dan pergi ke: `http://localhost:8080` atau `http://YOUR_SERVER_IP:8080`

### Direct cURL Commands
```bash
# Jedimaster edition
curl -fsSL http://localhost:8080/pve8-jedimaster.sh | bash

# Standard edition  
curl -fsSL http://localhost:8080/pve8.sh | bash

# JangLapoque edition
curl -fsSL http://localhost:8080/pve8-janglapoque.sh | bash
```

### Download Script
```bash
# Download script first
wget http://localhost:8080/pve8-jedimaster.sh

# Make executable
chmod +x pve8-jedimaster.sh

# Run
./pve8-jedimaster.sh
```

## 🔧 Management Commands

```bash
# Start container
docker-compose start

# Stop container
docker-compose stop

# Restart container
docker-compose restart

# View logs
docker-compose logs -f

# Update scripts (rebuild container)
docker-compose down
docker-compose up -d --build

# Remove everything
docker-compose down -v
docker rmi pmx_installation_proxmox-scripts
```

## 🌐 Accessing from Remote Machines

Jika anda nak access dari komputer lain dalam network:

1. **Find your server IP:**
```bash
ip addr show | grep inet
```

2. **Access dari komputer lain:**
```bash
curl -fsSL http://YOUR_SERVER_IP:8080/pve8-jedimaster.sh | bash
```

3. **Atau buka web browser:**
```
http://YOUR_SERVER_IP:8080
```

## 🛡️ Security Notes

- Container running sebagai non-root user
- Scripts served sebagai read-only
- Container isolated dalam custom network
- Health checks enabled untuk monitoring

## 🔄 Updating Scripts

Untuk update scripts tanpa rebuild container:

```bash
# Edit your scripts
nano pve8-jedimaster.sh

# Restart container to reload
docker-compose restart
```

## 📊 Monitoring

Container include health check yang boleh anda monitor:

```bash
# Check health status
docker inspect pmx-script-server | grep -A 5 "Health"

# atau menggunakan docker-compose
docker-compose ps
```

## 🐛 Troubleshooting

### Container tidak start
```bash
# Check logs
docker-compose logs

# Check port availability
netstat -tulpn | grep :8080
```

### Cannot access dari luar
```bash
# Check firewall
sudo ufw status
sudo ufw allow 8080

# Check if container listening
docker port pmx-script-server
```

### Scripts tidak update
```bash
# Rebuild container
docker-compose down
docker-compose up -d --build
```

## 🎯 Advanced Configuration

### Custom Port
Edit `docker-compose.yml`:
```yaml
ports:
  - "3000:80"  # Change 8080 to 3000
```

### Custom Domain with Traefik
Container already configured dengan Traefik labels. Uncomment dan configure Traefik jika diperlukan.

### SSL/HTTPS
Untuk production, tambah reverse proxy seperti Nginx atau Traefik dengan SSL certificates.

---

**Happy scripting! 🚀**
