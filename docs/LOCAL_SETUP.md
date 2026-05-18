# Local Development Setup Guide

Panduan untuk setup dan menjalankan infra-platform di local environment (Codespaces, Docker Desktop, Linux).

## Prerequisites

### System Requirements

- **CPU:** 2 cores minimum
- **RAM:** 4GB minimum (8GB recommended)
- **Storage:** 10GB free space
- **OS:** Linux, macOS, atau Windows (with WSL2)

### Required Software

- Docker 20.10+
- Docker Compose 2.0+
- Git
- Bash shell (or PowerShell for Windows)

### Installation

**Linux/macOS/WSL:**
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify
docker --version
docker-compose --version
```

**macOS (with Homebrew):**
```bash
brew install docker docker-compose docker-buildx
brew link docker-compose
```

**Windows (with WSL2):**
```bash
# Install Docker Desktop for Windows dengan WSL2 backend
# https://docs.docker.com/desktop/install/windows-install/

# Then di WSL2 terminal:
docker --version
docker-compose --version
```

---

## Quick Start

```bash
# 1. Clone repository
git clone https://github.com/khairuls17/infra-platform.git
cd infra-platform

# 2. Start services
docker-compose up -d

# 3. Check status
docker-compose ps

# 4. View logs
docker-compose logs -f
```

**Access services:**
- Nginx: http://localhost:8080
- Grafana: http://localhost:8080/grafana
- Prometheus: http://localhost:8080/prometheus
- Portainer: http://localhost:8080/portainer
- Uptime Kuma: http://localhost:8080/status

---

## Detailed Setup Steps

### Step 1: Clone Repository

```bash
git clone https://github.com/khairuls17/infra-platform.git
cd infra-platform
```

### Step 2: Verify Docker Installation

```bash
# Check Docker
docker ps

# Check Docker Compose
docker-compose version

# Test Docker
docker run hello-world
```

### Step 3: Start Services

```bash
# Start all services in background
docker-compose up -d

# Or with logs (use Ctrl+C to stop logs view)
docker-compose up

# Or with verbose logging
docker-compose up --verbose
```

### Step 4: Verify Services

```bash
# Check container status
docker-compose ps

# Expected output:
# NAME                COMMAND                  SERVICE             STATUS
# cadvisor            "/usr/bin/cadvisor"      cadvisor            Up 2 minutes
# grafana             "/run.sh"                grafana             Up 2 minutes
# nginx               "nginx -g daemon off"    nginx               Up 2 minutes
# node-exporter       "/bin/node_exporter"     node-exporter       Up 2 minutes
# portainer           "/portainer"             portainer           Up 2 minutes
# prometheus          "/bin/prometheus"        prometheus          Up 2 minutes
# uptime-kuma         "dumb-init node"         uptime-kuma         Up 2 minutes
```

### Step 5: Test Access

```bash
# Test Nginx (should return service info)
curl http://localhost:8080

# Test subpath routing
curl http://localhost:8080/grafana/
curl http://localhost:8080/prometheus/
curl http://localhost:8080/portainer/

# Check specific ports (if exposed)
curl http://localhost:3000  # Grafana direct
curl http://localhost:9090  # Prometheus direct
```

---

## Browser Access

### Local Codespaces

1. Go to GitHub Codespaces
2. VS Code opens with terminal
3. Click on "Ports" tab
4. Local Address shows forwarded port
5. Click link untuk access service

**Example:**
```
nginx:80 → 
  Local Address: https://khairuls17-intelligent-guide-pr4pw98qp6xw9xx-8080.app.github.dev
```

Access:
- https://...app.github.dev:8080/grafana
- https://...app.github.dev:8080/portainer
- dll

### Local Desktop

Simply open browser dan akses:
- http://localhost:8080/grafana
- http://localhost:8080/portainer
- etc

---

## Common Commands

### Container Management

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Stop dan remove volumes (clean slate)
docker-compose down -v

# Restart specific service
docker-compose restart grafana

# View running services
docker-compose ps

# View all services (including stopped)
docker-compose ps -a
```

### Logs & Debugging

```bash
# View all logs
docker-compose logs

# View logs for specific service
docker-compose logs grafana
docker-compose logs nginx
docker-compose logs prometheus

# Follow logs (live)
docker-compose logs -f nginx

# Last 50 lines
docker-compose logs --tail 50

# Since last 10 minutes
docker-compose logs --since 10m
```

### Execute Commands in Container

```bash
# Open shell di container
docker-compose exec grafana bash

# Run specific command
docker-compose exec prometheus promtool check config /etc/prometheus/prometheus.yml

# Run dengan root
docker-compose exec -u root grafana apt-get update
```

### Resource Monitoring

```bash
# Check resource usage
docker stats

# Check specific container
docker stats grafana

# Check disk usage
docker system df

# Free up space (remove unused images)
docker system prune -a

# Remove unused volumes
docker volume prune
```

---

## Configuration & Customization

### Change Nginx Port

Edit `docker-compose.yml`:

```yaml
nginx:
  ports:
    - "8080:80"  # Change 8080 to your port
```

Then:
```bash
docker-compose down
docker-compose up -d
```

### Change Grafana Admin Password

Edit `docker-compose.yml`:

```yaml
grafana:
  environment:
    - GF_SECURITY_ADMIN_PASSWORD=new-password
```

Or via docker-compose.override.yml (to not change tracked file)

### Add Custom Volume

```yaml
services:
  myservice:
    volumes:
      - ./my-data:/app/data
```

### Expose Additional Ports

```yaml
services:
  prometheus:
    ports:
      - "9090:9090"  # Direct access (not via Nginx)
```

---

## Monitoring Setup

### Add Grafana Datasource

1. Access Grafana: http://localhost:8080/grafana
2. Login: admin / password (dari docker-compose.yml)
3. **Configuration** → **Data Sources** → **Add**
4. Select **Prometheus**
5. URL: http://prometheus:9090
6. **Save & Test**

### Import Dashboard

1. **Dashboards** → **Import**
2. Dashboard ID: 1860 (Node Exporter)
3. Select Prometheus datasource
4. Import

### View Prometheus Targets

1. Access: http://localhost:8080/prometheus
2. Go to **Status** → **Targets**
3. Should see:
   - prometheus (UP)
   - node-exporter (UP)
   - cadvisor (UP)

---

## Troubleshooting

### Port Already in Use

```bash
# Find process using port 8080
lsof -i :8080  # macOS/Linux
netstat -ano | findstr :8080  # Windows

# Kill process
kill -9 <PID>  # macOS/Linux
taskkill /PID <PID> /F  # Windows

# Or change Nginx port in docker-compose.yml
```

### Containers Keep Restarting

```bash
# Check logs
docker-compose logs <service-name>

# Common causes:
# - Port conflict
# - Insufficient resources
# - Configuration error
# - Missing volumes/data

# Debug
docker-compose logs -f
```

### Out of Memory

```bash
# Check Docker memory limit
docker info | grep Memory

# Increase Docker memory (Desktop)
# Docker Desktop → Preferences → Resources → Memory

# Check container usage
docker stats

# Reduce Prometheus retention
# Edit docker-compose.yml and add to prometheus:
# command:
#   - '--storage.tsdb.retention.time=7d'  # Change from default
```

### Network Issues

```bash
# Check Docker network
docker network ls
docker network inspect infra-platform_backend

# Test connection between containers
docker-compose exec nginx ping prometheus

# Verify DNS resolution
docker-compose exec nginx nslookup grafana
```

### Services Not Accessible

```bash
# Check if containers running
docker-compose ps

# Verify port bindings
docker port nginx

# Check Nginx logs
docker-compose logs nginx

# Test Nginx config
docker exec nginx nginx -t

# Curl internal service
docker-compose exec nginx curl -I http://grafana:3000
```

---

## Development Workflow

### Making Changes

1. **Edit configuration:**
   ```bash
   nano monitoring/prometheus/prometheus.yml
   nano proxy/nginx/default.conf
   ```

2. **Reload without restart:**
   ```bash
   # Nginx
   docker exec nginx nginx -s reload

   # Prometheus (need restart)
   docker-compose restart prometheus
   ```

3. **Verify changes:**
   ```bash
   docker-compose logs
   curl http://localhost:8080
   ```

### Commit Changes

```bash
git add .
git commit -m "chore: update prometheus config"
git push origin main
```

### Clean Up

```bash
# Remove all containers, networks, volumes
docker-compose down -v

# Remove images too
docker-compose down -v --rmi all

# This is useful untuk test clean installation
```

---

## Performance Tips

### Optimize Docker Memory

```yaml
services:
  prometheus:
    deploy:
      resources:
        limits:
          memory: 500M
        reservations:
          memory: 256M
```

### Reduce Prometheus Retention

Default: 15 days. Untuk local, reduce to 7 days:

```yaml
prometheus:
  command:
    - '--storage.tsdb.retention.time=7d'
```

### Disable Unused Services

Edit `docker-compose.override.yml` untuk local development.

---

## Learning Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)

---

## Next Steps

1. **Explore each service:**
   - Nginx reverse proxy routing
   - Prometheus metrics collection
   - Grafana dashboards
   - Portainer container management

2. **Setup monitoring:**
   - Add Prometheus datasource
   - Import dashboards
   - Create custom dashboards

3. **Deploy to production:**
   - When ready, follow [QUICK_START.md](QUICK_START.md)
   - Or [VPS_DEPLOYMENT.md](VPS_DEPLOYMENT.md)

---

**Happy learning! 🚀**
