# Makefile for Proxmox Installation Scripts Docker Setup
# Author: Assistant
# Description: Easy management commands for Docker container

# Variables
CONTAINER_NAME = pmx-script-server
IMAGE_NAME = pmx-scripts
DOCKER_COMPOSE_FILE = docker-compose.yml
PORT = 8080

# Default target
.PHONY: help
help: ## Show this help message
	@echo "🐳 Proxmox Scripts Docker Management"
	@echo "==================================="
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Build and run
.PHONY: up
up: ## Build and start the container in detached mode
	@echo "🚀 Starting Proxmox Scripts container..."
	docker-compose up -d --build
	@echo "✅ Container started! Access at: http://localhost:$(PORT)"

.PHONY: build
build: ## Build the Docker image
	@echo "🔨 Building Docker image..."
	docker-compose build

.PHONY: start
start: ## Start existing container
	@echo "▶️  Starting container..."
	docker-compose start

.PHONY: stop
stop: ## Stop the container
	@echo "⏹️  Stopping container..."
	docker-compose stop

.PHONY: restart
restart: ## Restart the container
	@echo "🔄 Restarting container..."
	docker-compose restart

.PHONY: down
down: ## Stop and remove container
	@echo "🛑 Stopping and removing container..."
	docker-compose down

.PHONY: clean
clean: ## Remove container and image
	@echo "🧹 Cleaning up containers and images..."
	docker-compose down -v
	docker rmi $(IMAGE_NAME) 2>/dev/null || true
	@echo "✅ Cleanup completed!"

# Monitoring and logs
.PHONY: logs
logs: ## Show container logs (follow mode)
	@echo "📋 Showing container logs..."
	docker-compose logs -f

.PHONY: status
status: ## Show container status
	@echo "📊 Container status:"
	docker-compose ps

.PHONY: health
health: ## Check container health
	@echo "🏥 Health check:"
	@docker inspect $(CONTAINER_NAME) --format='{{.State.Health.Status}}' 2>/dev/null || echo "Container not running"

# Development
.PHONY: shell
shell: ## Access container shell
	@echo "🐚 Accessing container shell..."
	docker-compose exec proxmox-scripts /bin/bash

.PHONY: nginx-reload
nginx-reload: ## Reload nginx configuration
	@echo "🔄 Reloading nginx..."
	docker-compose exec proxmox-scripts nginx -s reload

.PHONY: test
test: ## Test if scripts are accessible
	@echo "🧪 Testing script accessibility..."
	@curl -s -o /dev/null -w "Health endpoint: %{http_code}\n" http://localhost:$(PORT)/health
	@curl -s -o /dev/null -w "Main page: %{http_code}\n" http://localhost:$(PORT)/
	@curl -s -o /dev/null -w "Jedimaster script: %{http_code}\n" http://localhost:$(PORT)/pve8-jedimaster.sh
	@echo "✅ Test completed!"

# Deployment helpers
.PHONY: deploy
deploy: clean build up test ## Full deployment (clean, build, start, test)
	@echo "🎉 Deployment completed successfully!"

.PHONY: update
update: ## Update scripts and restart container
	@echo "🔄 Updating scripts..."
	docker-compose restart
	@echo "✅ Scripts updated!"

.PHONY: backup-scripts
backup-scripts: ## Backup all script files
	@echo "💾 Backing up scripts..."
	@mkdir -p backups
	@tar -czf backups/scripts-backup-$(shell date +%Y%m%d-%H%M%S).tar.gz *.sh banner.txt *.jpg
	@echo "✅ Scripts backed up to backups/ directory"

# Quick access commands
.PHONY: open
open: ## Open web interface in default browser
	@echo "🌐 Opening web interface..."
	@command -v xdg-open >/dev/null 2>&1 && xdg-open http://localhost:$(PORT) || \
	 command -v open >/dev/null 2>&1 && open http://localhost:$(PORT) || \
	 echo "Please open http://localhost:$(PORT) in your browser"

.PHONY: curl-jedi
curl-jedi: ## Show curl command for jedimaster script
	@echo "📋 Copy this command to run jedimaster script:"
	@echo "curl -fsSL http://localhost:$(PORT)/pve8-jedimaster.sh | bash"

.PHONY: curl-standard  
curl-standard: ## Show curl command for standard script
	@echo "📋 Copy this command to run standard script:"
	@echo "curl -fsSL http://localhost:$(PORT)/pve8.sh | bash"

# Maintenance
.PHONY: prune
prune: ## Remove unused Docker resources
	@echo "🧽 Pruning unused Docker resources..."
	docker system prune -f
	@echo "✅ Pruning completed!"

.PHONY: info
info: ## Show container and image information
	@echo "ℹ️  Container Information:"
	@echo "========================"
	@echo "Container Name: $(CONTAINER_NAME)"
	@echo "Image Name: $(IMAGE_NAME)"
	@echo "Port: $(PORT)"
	@echo "Access URL: http://localhost:$(PORT)"
	@echo ""
	@echo "📦 Image Details:"
	@docker images $(IMAGE_NAME) 2>/dev/null || echo "Image not built yet"
	@echo ""
	@echo "🏃 Running Containers:"
	@docker ps --filter "name=$(CONTAINER_NAME)" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
