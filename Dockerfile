# Dockerfile for Proxmox Installation Script Server
FROM nginx:alpine

# Install bash and other utilities for script compatibility
RUN apk add --no-cache bash curl wget

# Create web directory
RUN mkdir -p /var/www/html

# Copy scripts to web directory
COPY *.sh /var/www/html/
COPY banner.txt /var/www/html/
COPY *.jpg /var/www/html/

# Set proper permissions for scripts
RUN chmod 644 /var/www/html/*.sh

# Create custom nginx configuration
RUN cat > /etc/nginx/nginx.conf << 'EOF'
worker_processes auto;
error_log /var/log/nginx/error.log notice;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                   '$status $body_bytes_sent "$http_referer" '
                   '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    keepalive_timeout 65;
    gzip on;

    server {
        listen 80;
        server_name localhost;
        root /var/www/html;
        index index.html index.htm;

        # Serve .sh files as plain text
        location ~ \.sh$ {
            add_header Content-Type text/plain;
            add_header Content-Disposition 'inline; filename="$1"';
            add_header Access-Control-Allow-Origin *;
        }

        # Serve banner.txt as plain text
        location ~ \.txt$ {
            add_header Content-Type text/plain;
            add_header Access-Control-Allow-Origin *;
        }

        # Serve images
        location ~ \.(jpg|jpeg|png|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }

        # Default location
        location / {
            try_files $uri $uri/ =404;
            autoindex on;
            autoindex_exact_size off;
            autoindex_localtime on;
        }

        # Health check endpoint
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
}
EOF

# Create a simple index.html for listing scripts
RUN cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Proxmox VE Installation Scripts</title>
    <style>
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            margin: 0; 
            padding: 20px; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
        }
        .container { 
            max-width: 800px; 
            margin: 0 auto; 
            background: rgba(255,255,255,0.1);
            padding: 30px;
            border-radius: 15px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
        }
        h1 { 
            text-align: center; 
            color: #fff;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
            margin-bottom: 30px;
        }
        .script-list { 
            list-style: none; 
            padding: 0; 
        }
        .script-item { 
            margin: 15px 0; 
            padding: 20px;
            background: rgba(255,255,255,0.1);
            border-radius: 10px;
            border: 1px solid rgba(255,255,255,0.2);
            transition: all 0.3s ease;
        }
        .script-item:hover {
            background: rgba(255,255,255,0.2);
            transform: translateY(-2px);
        }
        .script-name { 
            font-weight: bold; 
            font-size: 1.2em; 
            margin-bottom: 10px;
            color: #fff;
        }
        .script-description { 
            color: rgba(255,255,255,0.8); 
            margin-bottom: 15px;
            line-height: 1.5;
        }
        .buttons { 
            display: flex; 
            gap: 10px; 
            flex-wrap: wrap;
        }
        .btn { 
            padding: 8px 16px; 
            text-decoration: none; 
            border-radius: 5px; 
            font-weight: bold;
            transition: all 0.3s ease;
            border: none;
            cursor: pointer;
        }
        .btn-view { 
            background: #4CAF50; 
            color: white; 
        }
        .btn-download { 
            background: #2196F3; 
            color: white; 
        }
        .btn-curl { 
            background: #FF9800; 
            color: white; 
        }
        .btn:hover { 
            transform: translateY(-1px);
            box-shadow: 0 4px 8px rgba(0,0,0,0.2);
        }
        .usage { 
            margin-top: 30px; 
            padding: 20px;
            background: rgba(255,255,255,0.1);
            border-radius: 10px;
            border-left: 4px solid #4CAF50;
        }
        .code { 
            background: rgba(0,0,0,0.3); 
            padding: 10px; 
            border-radius: 5px; 
            font-family: 'Courier New', monospace; 
            margin: 10px 0;
            color: #fff;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            color: rgba(255,255,255,0.7);
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Proxmox VE Installation Scripts</h1>
        
        <ul class="script-list">
            <li class="script-item">
                <div class="script-name">pve8-jedimaster.sh</div>
                <div class="script-description">
                    Proxmox VE 8 Installation Script with Jedi Master theme. Includes stealth mode installation 
                    with trace cleaning, custom MOTD banner, and automated post-installation cleanup.
                </div>
                <div class="buttons">
                    <a href="pve8-jedimaster.sh" class="btn btn-view" target="_blank">📖 View</a>
                    <a href="pve8-jedimaster.sh" class="btn btn-download" download>⬇️ Download</a>
                    <button class="btn btn-curl" onclick="copyToClipboard('curl -fsSL http://'+window.location.host+'/pve8-jedimaster.sh | bash')">📋 Copy cURL</button>
                </div>
            </li>
            
            <li class="script-item">
                <div class="script-name">pve8.sh</div>
                <div class="script-description">
                    Standard Proxmox VE 8 Installation Script. Clean installation with automated 
                    repository setup and system configuration.
                </div>
                <div class="buttons">
                    <a href="pve8.sh" class="btn btn-view" target="_blank">📖 View</a>
                    <a href="pve8.sh" class="btn btn-download" download>⬇️ Download</a>
                    <button class="btn btn-curl" onclick="copyToClipboard('curl -fsSL http://'+window.location.host+'/pve8.sh | bash')">📋 Copy cURL</button>
                </div>
            </li>
            
            <li class="script-item">
                <div class="script-name">pve8-janglapoque.sh</div>
                <div class="script-description">
                    JangLapoque edition of Proxmox VE 8 installation script with custom branding and optimizations.
                </div>
                <div class="buttons">
                    <a href="pve8-janglapoque.sh" class="btn btn-view" target="_blank">📖 View</a>
                    <a href="pve8-janglapoque.sh" class="btn btn-download" download>⬇️ Download</a>
                    <button class="btn btn-curl" onclick="copyToClipboard('curl -fsSL http://'+window.location.host+'/pve8-janglapoque.sh | bash')">📋 Copy cURL</button>
                </div>
            </li>
        </ul>

        <div class="usage">
            <h3>📝 Usage Instructions</h3>
            <p><strong>Method 1: Direct execution via cURL</strong></p>
            <div class="code">curl -fsSL http://YOUR_SERVER_IP/script_name.sh | bash</div>
            
            <p><strong>Method 2: Download and execute</strong></p>
            <div class="code">
                wget http://YOUR_SERVER_IP/script_name.sh<br>
                chmod +x script_name.sh<br>
                ./script_name.sh
            </div>
            
            <p><strong>⚠️ Important Notes:</strong></p>
            <ul>
                <li>All scripts must be run as root on Debian 12 (Bookworm)</li>
                <li>Ensure internet connectivity before running</li>
                <li>The system will reboot automatically after installation</li>
                <li>Proxmox will be accessible at https://YOUR_IP:8006 after reboot</li>
            </ul>
        </div>

        <div class="footer">
            <p>🐳 Served via Docker | 🛡️ Powered by Nginx</p>
        </div>
    </div>

    <script>
        function copyToClipboard(text) {
            navigator.clipboard.writeText(text).then(function() {
                alert('Command copied to clipboard!');
            }, function(err) {
                console.error('Could not copy text: ', err);
            });
        }
    </script>
</body>
</html>
EOF

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
