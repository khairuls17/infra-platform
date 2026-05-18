# Quick Start Deployment Guide

Panduan cepat untuk deploy infra-platform ke VPS.

## Prerequisites

- VPS dengan Ubuntu 22.04/24.04 atau Debian 12
- SSH access
- Domain name
- Git access

## One-Line Deploy (Recommended)

```bash
# SSH ke VPS
ssh user@your-vps-ip

# Clone dan jalankan deployment script
git clone https://github.com/khairuls17/infra-platform.git
cd infra-platform

# Run deployment script
bash scripts/deploy.sh your-domain.com your-admin-password your-email@example.com
```

Script akan melakukan:
1. System update
2. Install Docker & Docker Compose
3. Setup Firewall (UFW)
4. Clone repository
5. Create .env configuration
6. Setup SSL certificates (Certbot)
7. Deploy with Docker Compose
8. Verification

## Manual Deployment Steps

### 1. SSH ke VPS

```bash
ssh user@your-vps-ip
```

### 2. Clone Repository

```bash
cd /opt
git clone https://github.com/khairuls17/infra-platform.git
cd infra-platform
```

### 3. Configure Environment

```bash
cp .env.example .env
nano .env

# Fill in:
# DOMAIN_NAME=your-domain.com
# GF_ADMIN_PASSWORD=your-secure-password
# LETSENCRYPT_EMAIL=your-email@example.com
```

### 4. Setup Cloudflare DNS

1. Add domain ke Cloudflare
2. Add DNS records (lihat panduan di bawah)
3. Update nameservers di domain registrar

### 5. Setup SSL Certificate

```bash
# Install certbot
sudo apt install certbot python3-certbot-dns-cloudflare -y

# Setup dengan Cloudflare API
# (lihat panduan Cloudflare di bawah)
```

### 6. Deploy Services

```bash
# Using production docker-compose
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Verify
docker-compose ps
```

### 7. Access Services

```
https://your-domain.com             → Main page
https://grafana.your-domain.com     → Grafana dashboard
https://portainer.your-domain.com   → Portainer UI
https://status.your-domain.com      → Uptime Kuma status
```

---

## Cloudflare DNS Setup

### 1. Add Domain to Cloudflare

1. Go to cloudflare.com
2. Click "Add a site"
3. Enter your domain name
4. Select Free plan (atau plan sesuai kebutuhan)
5. Review DNS records
6. Copy Cloudflare nameservers
7. Update nameservers di domain registrar
8. Wait 24-48 hours untuk propagation

### 2. Add DNS Records

Di Cloudflare Dashboard:

**A Records:**
```
Type  | Name     | Value        | TTL  | Proxy
------|----------|--------------|------|------
A     | @        | your-vps-ip  | Auto | Proxied
```

**CNAME Records:**
```
Type  | Name       | Target       | TTL  | Proxy
------|------------|--------------|------|------
CNAME | grafana    | your-domain  | Auto | Proxied
CNAME | portainer  | your-domain  | Auto | Proxied
CNAME | status     | your-domain  | Auto | Proxied
CNAME | prometheus | your-domain  | Auto | Proxied
```

### 3. SSL/TLS Settings

Di Cloudflare → SSL/TLS → Overview:
- **Encryption mode:** Select "Full (strict)"

Di Cloudflare → SSL/TLS → Edge Certificates:
- Enable "Always Use HTTPS"
- Enable "Automatic HTTPS Rewrites"
- Enable "Opportunistic Encryption"

### 4. Get Cloudflare API Token (untuk Certbot)

1. Login Cloudflare
2. Go to Profile → API Tokens → Create Token
3. Use template: "Edit zone DNS"
4. Permissions:
   - Zone › DNS › Edit
   - Zone › Zone › Read
5. Zone Resources: Include → Specific zone → Select your domain
6. TTL: 1 hour
7. Copy token (Anda akan gunakan ini untuk Certbot)

---

## SSL Certificate Setup (Certbot)

### Using Cloudflare DNS Challenge

```bash
# 1. Install certbot
sudo apt install certbot python3-certbot-dns-cloudflare -y

# 2. Create Cloudflare credentials file
mkdir -p ~/.secrets/certbot
cat > ~/.secrets/certbot/cloudflare.ini << EOF
dns_cloudflare_api_token = YOUR_CLOUDFLARE_API_TOKEN
EOF

chmod 600 ~/.secrets/certbot/cloudflare.ini

# 3. Create certificates
sudo certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials ~/.secrets/certbot/cloudflare.ini \
  -d your-domain.com \
  -d '*.your-domain.com' \
  --email your-email@example.com \
  --agree-tos \
  --non-interactive

# 4. Copy certificates ke project
mkdir -p /opt/infra-platform/certs
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem /opt/infra-platform/certs/
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem /opt/infra-platform/certs/
sudo chown $USER:$USER /opt/infra-platform/certs/*

# 5. Verify
certbot certificates
```

### Auto-Renewal

```bash
# Certbot akan auto-renew sebelum expiry
# Test renewal:
sudo certbot renew --dry-run

# Check status:
sudo systemctl status certbot.timer
```

---

## Docker Compose Commands

```bash
# Start services
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Alias untuk kemudahan
alias dcprod="docker-compose -f docker-compose.yml -f docker-compose.prod.yml"
dcprod up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f nginx
docker-compose logs -f grafana

# Stop services
docker-compose down

# Restart services
docker-compose restart

# Remove and recreate
docker-compose down
docker-compose up -d
```

---

## Post-Deployment Configuration

### Grafana

1. Access: https://grafana.your-domain.com
2. Login: admin / password dari .env
3. Change password
4. Add Prometheus data source:
   - URL: http://prometheus:9090
   - Save & test
5. Import dashboards from Grafana marketplace

### Portainer

1. Access: https://portainer.your-domain.com
2. Create admin account
3. Connect to local Docker socket
4. Manage containers, images, volumes

### Uptime Kuma

1. Access: https://status.your-domain.com
2. Setup admin account
3. Add monitors untuk services
4. Configure notifications (email, Slack, etc)

### Prometheus

1. Access: https://prometheus.your-domain.com (atau internal)
2. Check targets: Status → Targets
3. View metrics: Graph tab
4. Configure retention di docker-compose (sudah ada default 30 days)

---

## Monitoring & Verification

### SSL Certificate Check

```bash
# Check expiry date
echo | openssl s_client -servername your-domain.com -connect your-domain.com:443 2>/dev/null | openssl x509 -noout -dates

# Or using certbot
certbot certificates
```

### DNS Propagation

```bash
# Check DNS records
nslookup your-domain.com
dig your-domain.com

# Check subdomains
nslookup grafana.your-domain.com
```

### Service Health

```bash
# Check container status
docker-compose ps

# Check specific service
docker-compose logs grafana

# Exec into container
docker-compose exec grafana bash

# Check port binding
sudo netstat -tulpn | grep LISTEN
```

### Firewall Status

```bash
sudo ufw status
sudo ufw show added
```

---

## Troubleshooting

### DNS Not Resolving
```bash
# Wait 24-48 hours
# Check Cloudflare Dashboard for DNS records
# Verify nameservers updated correctly
dig your-domain.com @1.1.1.1
```

### Certificate Renewal Failed
```bash
# Check certbot logs
sudo tail -f /var/log/letsencrypt/letsencrypt.log

# Manual renewal
sudo certbot renew --force-renewal

# Check Cloudflare API token
cat ~/.secrets/certbot/cloudflare.ini
```

### Services Not Responding
```bash
# Check if containers running
docker-compose ps

# Check logs
docker-compose logs nginx
docker-compose logs grafana

# Restart service
docker-compose restart nginx
```

### Nginx Config Error
```bash
# Test config
docker exec nginx nginx -t

# Reload nginx
docker exec nginx nginx -s reload

# Check logs
docker-compose logs nginx
```

---

## Useful Links

- [Cloudflare Documentation](https://developers.cloudflare.com/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Certbot Documentation](https://certbot.eff.org/docs/)

---

## Next Steps

Setelah deployment berhasil:

1. **Configure Monitoring**
   - Setup Grafana dashboards
   - Configure Prometheus scrape configs
   - Add alerts

2. **Security Hardening**
   - Configure Cloudflare WAF rules
   - Setup IP whitelisting untuk Portainer
   - Configure authentication untuk sensitive services

3. **Backup Strategy**
   - Setup automated backups untuk volumes
   - Test restore procedures
   - Consider cloud storage backup

4. **CI/CD Integration**
   - Setup GitHub Actions untuk auto-deploy
   - Create deployment notifications
   - Automate certificate renewal notifications

5. **Performance Optimization**
   - Monitor resource usage
   - Optimize container resource limits
   - Setup auto-scaling jika perlu

6. **Documentation**
   - Document your infrastructure
   - Create runbooks untuk common tasks
   - Document disaster recovery procedures
