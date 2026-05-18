# VPS Deployment Guide - infra-platform

Panduan lengkap untuk deploy infra-platform ke VPS dengan production setup.

## Prasyarat

- VPS Linux (Ubuntu 22.04/24.04 atau Debian 12)
- SSH access ke VPS
- Domain name sudah dibeli
- Git installed
- Docker & Docker Compose installed di VPS

## Checklist Setup

- [ ] VPS Initial Setup (SSH keys, firewall)
- [ ] Docker Installation
- [ ] Clone Repository
- [ ] Domain DNS Configuration
- [ ] SSL Certificate Setup
- [ ] Deploy with Docker Compose
- [ ] Verification

---

## 1. VPS Initial Setup

### SSH Key Setup
```bash
# Login ke VPS dengan password terlebih dahulu
ssh root@your-vps-ip

# Generate SSH key pair (jika belum ada)
ssh-keygen -t ed25519 -C "your-email@example.com"

# Copy public key ke VPS authorized_keys
cat ~/.ssh/id_ed25519.pub | ssh root@your-vps-ip 'cat >> ~/.ssh/authorized_keys'
```

### Firewall Setup (UFW)
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install UFW
sudo apt install ufw -y

# Enable firewall
sudo ufw enable

# Allow SSH, HTTP, HTTPS
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Verify rules
sudo ufw status
```

### Security Hardening
```bash
# Disable root login and password auth
sudo nano /etc/ssh/sshd_config
# Ubah: PermitRootLogin no
# Ubah: PasswordAuthentication no
# Ubah: PubkeyAuthentication yes

# Restart SSH
sudo systemctl restart ssh
```

---

## 2. Docker Installation

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

# Verify installation
docker --version
docker-compose --version
```

---

## 3. Clone Repository

```bash
# SSH ke VPS
ssh user@your-vps-ip

# Clone repo
cd /opt
git clone https://github.com/khairuls17/infra-platform.git
cd infra-platform

# Create .env file dari template
cp .env.example .env

# Edit .env dengan nilai production
nano .env
# - Set DOMAIN_NAME
# - Set GF_ADMIN_PASSWORD
# - Set LETSENCRYPT_EMAIL
```

---

## 4. DNS Configuration (Cloudflare)

### A. Add Domain ke Cloudflare

1. Login ke Cloudflare
2. Click "Add a site"
3. Enter domain name
4. Copy Cloudflare nameservers
5. Update nameservers di registrar domain

### B. DNS Records Setup

Di Cloudflare dashboard, tambahkan DNS records:

```
Type    | Name          | Value           | Proxy
--------|---------------|-----------------|------
A       | @             | your-vps-ip     | Proxied
CNAME   | grafana       | @               | Proxied
CNAME   | portainer     | @               | Proxied
CNAME   | status        | @               | Proxied
CNAME   | prometheus    | @               | Proxied
```

### C. SSL/TLS Settings

1. Di Cloudflare → SSL/TLS → Overview
2. Pilih "Full (strict)"
3. Di SSL/TLS → Edge Certificates
4. Enable "Always Use HTTPS"
5. Enable "Automatic HTTPS Rewrites"

**Hasil:**
- `domain.com` → nginx port 443
- `grafana.domain.com` → nginx → grafana container
- `portainer.domain.com` → nginx → portainer container
- `status.domain.com` → nginx → uptime-kuma container

---

## 5. SSL Certificate Setup (Let's Encrypt)

### Option A: Using Certbot dengan Cloudflare DNS

```bash
# Install Certbot
sudo apt install certbot python3-certbot-dns-cloudflare -y

# Create Cloudflare credentials
mkdir -p ~/.secrets/certbot
nano ~/.secrets/certbot/cloudflare.ini

# Copy paste:
# dns_cloudflare_api_token = your-cloudflare-api-token
# dns_cloudflare_zone_name = your-domain.com

chmod 600 ~/.secrets/certbot/cloudflare.ini

# Create certificate
sudo certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials ~/.secrets/certbot/cloudflare.ini \
  -d your-domain.com \
  -d '*.your-domain.com' \
  --email your-email@example.com \
  --agree-tos \
  --non-interactive

# Copy certificate ke project directory
mkdir -p ~/infra-platform/certs
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem ~/infra-platform/certs/
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem ~/infra-platform/certs/
sudo chown $USER:$USER ~/infra-platform/certs/*
```

**Cloudflare API Token:**
1. Login Cloudflare
2. Go to Profile → API Tokens
3. Create Token dengan permissions: Zone.DNS.Edit + Zone.Zone.Read
4. Scope: All zones
5. Copy token ke credentials file

### Option B: Using Certbot dengan HTTP challenge

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# Gunakan nginx webroot untuk challenge
sudo certbot certonly --webroot -w /var/www/certbot \
  -d your-domain.com \
  -d grafana.your-domain.com \
  -d portainer.your-domain.com \
  -d status.your-domain.com \
  --email your-email@example.com \
  --agree-tos \
  --non-interactive

# Copy certificate
mkdir -p ~/infra-platform/certs
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem ~/infra-platform/certs/
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem ~/infra-platform/certs/
sudo chown $USER:$USER ~/infra-platform/certs/*
```

### Auto-renewal

```bash
# Test renewal
sudo certbot renew --dry-run

# Systemd timer akan handle renewal otomatis
# Check status:
sudo systemctl status certbot.timer
```

---

## 6. Deploy dengan Docker Compose

```bash
cd ~/infra-platform

# Using production compose file
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Or create alias
echo 'alias dcprod="docker-compose -f docker-compose.yml -f docker-compose.prod.yml"' >> ~/.bashrc
source ~/.bashrc

dcprod up -d
```

**Environment variables** dari `.env` akan otomatis di-load:
- DOMAIN_NAME digunakan untuk nginx config
- GF_ADMIN_PASSWORD untuk Grafana
- Etc.

### Update .env di Nginx Runtime

Nginx menggunakan static config (default.prod.conf). Jika ingin dynamic values, gunakan envsubst:

```bash
# Install envsubst jika belum ada
apt-get install gettext-base -y

# Generate nginx config dari template dengan env values
envsubst < proxy/nginx/default.prod.conf.template > proxy/nginx/default.prod.conf
```

Create `proxy/nginx/default.prod.conf.template` dengan variable seperti `${DOMAIN_NAME}`

---

## 7. Verification

### Services Health Check

```bash
# Check docker containers
docker-compose ps

# Check logs
docker-compose logs -f nginx
docker-compose logs -f grafana

# Test endpoints
curl -k https://your-domain.com
curl -k https://grafana.your-domain.com
curl -k https://portainer.your-domain.com
curl -k https://status.your-domain.com
```

### SSL Certificate Check

```bash
# Check SSL cert validity
openssl s_client -connect your-domain.com:443 -servername your-domain.com

# Check cert expiry
certbot certificates
```

### Monitoring Setup

1. Access Grafana: `https://grafana.your-domain.com`
   - Default: admin / password dari GF_ADMIN_PASSWORD
   - Add Prometheus datasource: `http://prometheus:9090`
   - Import dashboards

2. Access Portainer: `https://portainer.your-domain.com`
   - Setup admin account
   - Connect to local Docker socket

3. Access Status: `https://status.your-domain.com`
   - Configure uptime monitoring
   - Add services to monitor

---

## Common Issues

### Issue: DNS not resolving
```bash
# Check DNS propagation
nslookup your-domain.com
dig your-domain.com

# Wait 24-48 hours for full propagation
```

### Issue: Certificate renewal fails
```bash
# Check certbot logs
sudo tail -f /var/log/letsencrypt/letsencrypt.log

# Renew manually
sudo certbot renew --force-renewal
```

### Issue: Services not responding
```bash
# Check firewall
sudo ufw status

# Check if containers are running
docker-compose ps

# Check container logs
docker-compose logs nginx
docker-compose logs grafana
```

### Issue: Nginx config error
```bash
# Test nginx config
docker exec nginx nginx -t

# Reload nginx
docker exec nginx nginx -s reload
```

---

## Monitoring & Maintenance

### Logs Rotation

```bash
# Create logrotate config
sudo nano /etc/logrotate.d/infra-platform

# Content:
/var/lib/docker/containers/*/*.log {
  rotate 7
  compress
  delaycompress
  missingok
  json-format
}
```

### Backup Strategy

```bash
# Create backup script
nano ~/infra-platform/scripts/backup.sh

#!/bin/bash
BACKUP_DIR="/backup/infra-platform"
mkdir -p $BACKUP_DIR

# Backup docker volumes
docker run --rm -v grafana_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/grafana_$(date +%Y%m%d).tar.gz -C /data .
docker run --rm -v prometheus_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/prometheus_$(date +%Y%m%d).tar.gz -C /data .
docker run --rm -v portainer_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/portainer_$(date +%Y%m%d).tar.gz -C /data .

# Delete old backups (keep 7 days)
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

# Cron job (daily at 2 AM)
0 2 * * * /path/to/backup.sh
```

### Monitoring Resources

```bash
# Check system resources
free -h
df -h
docker stats

# Check container health
docker-compose ps
docker inspect <container-id>
```

---

## Next Steps

1. **Auto-scaling:** Setup load balancer jika perlu multiple VPS
2. **CI/CD:** Setup GitHub Actions untuk auto-deploy
3. **Backup Strategy:** Automated backup ke cloud storage
4. **Monitoring:** Add alerting (email, Slack) ke Grafana
5. **Security:** Implement WAF rules di Cloudflare
