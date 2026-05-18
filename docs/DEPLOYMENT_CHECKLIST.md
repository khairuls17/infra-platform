# Deployment Checklist

Checklist lengkap untuk memastikan VPS deployment infra-platform berjalan dengan baik.

## Pre-Deployment (Local Testing)

- [ ] Docker Compose bekerja di local (Codespaces)
- [ ] Semua services running dan healthy
- [ ] Nginx routing bekerja dengan baik
- [ ] Repository siap untuk deployment (.gitignore updated)
- [ ] Documentation sudah dibaca
- [ ] .env.example sudah dibuat

## Domain & DNS Setup

- [ ] Domain name sudah dibeli
- [ ] Nameservers sudah diupdate ke Cloudflare
- [ ] Menunggu DNS propagation (24-48 jam)
  - [ ] Verify A record: `nslookup your-domain.com @1.1.1.1`
  - [ ] Verify CNAME records: `nslookup grafana.your-domain.com @1.1.1.1`
- [ ] Cloudflare SSL/TLS settings configured:
  - [ ] SSL/TLS: Full (strict)
  - [ ] Always Use HTTPS: Enabled
  - [ ] Automatic HTTPS Rewrites: Enabled
- [ ] Cloudflare API Token generated (untuk Certbot)

## VPS Infrastructure

- [ ] VPS provider pilih (DigitalOcean, Linode, Vultr, AWS, etc)
- [ ] VPS setup dengan OS Linux (Ubuntu 22.04/24.04 atau Debian 12)
- [ ] SSH key generated dan configured
- [ ] SSH login tested
- [ ] Firewall (UFW) configured:
  - [ ] Port 22 (SSH) allowed
  - [ ] Port 80 (HTTP) allowed
  - [ ] Port 443 (HTTPS) allowed
  - [ ] Firewall enabled
- [ ] System update completed: `sudo apt update && sudo apt upgrade -y`
- [ ] Security hardening applied:
  - [ ] SSH key authentication enabled
  - [ ] Password authentication disabled
  - [ ] Root login disabled

## Docker Installation

- [ ] Docker installed: `docker --version`
- [ ] Docker Compose installed: `docker-compose --version`
- [ ] Current user added to docker group: `groups $USER`
- [ ] Test Docker: `docker run hello-world`

## Repository Setup

- [ ] Repository cloned ke /opt/infra-platform
- [ ] Ownership corrected: `sudo chown -R $USER:$USER /opt/infra-platform`
- [ ] .env file created dari .env.example
- [ ] .env values configured:
  - [ ] DOMAIN_NAME
  - [ ] GF_ADMIN_PASSWORD (strong password)
  - [ ] LETSENCRYPT_EMAIL
- [ ] .env file permissions restricted: `chmod 600 .env`

## SSL Certificate Setup

- [ ] Certbot installed: `certbot --version`
- [ ] Cloudflare credentials file created: `~/.secrets/certbot/cloudflare.ini`
- [ ] Cloudflare credentials file permissions: `chmod 600`
- [ ] Certificate created:
  - [ ] Command run successfully
  - [ ] Certificate files exist: `/etc/letsencrypt/live/your-domain.com/`
- [ ] Certificate copied to project:
  - [ ] fullchain.pem copied to /opt/infra-platform/certs/
  - [ ] privkey.pem copied to /opt/infra-platform/certs/
  - [ ] Ownership corrected: `sudo chown $USER:$USER certs/*`

## Docker Compose Deployment

- [ ] Production docker-compose file ready: `docker-compose.prod.yml`
- [ ] Nginx production config ready: `proxy/nginx/default.prod.conf`
- [ ] All volume directories exist:
  - [ ] monitoring/prometheus/
  - [ ] proxy/nginx/
  - [ ] uptime/
  - [ ] certs/
- [ ] Deploy command executed:
  ```bash
  docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
  ```
- [ ] Services running: `docker-compose ps`
  - [ ] All containers UP
  - [ ] No restart loops

## Post-Deployment Verification

### Service Health

- [ ] All containers healthy:
  ```bash
  docker-compose ps
  docker-compose exec <service> healthcheck-command
  ```

### HTTPS/SSL Access

- [ ] Main domain accessible: `https://your-domain.com`
  - [ ] Responds with 200 or 301 (redirect)
  - [ ] SSL certificate valid
- [ ] Grafana accessible: `https://grafana.your-domain.com`
  - [ ] Login page loads
  - [ ] SSL cert valid
- [ ] Portainer accessible: `https://portainer.your-domain.com`
  - [ ] UI loads
  - [ ] SSL cert valid
- [ ] Status page accessible: `https://status.your-domain.com`
  - [ ] Page loads
  - [ ] SSL cert valid
- [ ] SSL certificate check:
  ```bash
  echo | openssl s_client -connect your-domain.com:443 | openssl x509 -noout -dates
  ```

### DNS Verification

- [ ] DNS A record resolves: `nslookup your-domain.com @1.1.1.1`
- [ ] CNAME records resolve:
  - [ ] `nslookup grafana.your-domain.com @1.1.1.1`
  - [ ] `nslookup portainer.your-domain.com @1.1.1.1`
  - [ ] `nslookup status.your-domain.com @1.1.1.1`

### Application Configuration

#### Grafana
- [ ] Access: https://grafana.your-domain.com
- [ ] Login: admin / GF_ADMIN_PASSWORD
- [ ] Password changed
- [ ] Prometheus datasource added: http://prometheus:9090
- [ ] Datasource test successful
- [ ] Dashboard imported (Node Exporter 1860)
- [ ] Dashboard displaying metrics

#### Portainer
- [ ] Access: https://portainer.your-domain.com
- [ ] Admin account created
- [ ] Docker socket connected
- [ ] Containers visible

#### Uptime Kuma
- [ ] Access: https://status.your-domain.com
- [ ] Admin account created
- [ ] Basic monitors configured

#### Prometheus
- [ ] Access: https://prometheus.your-domain.com (or internal)
- [ ] Status → Targets: All targets UP
  - [ ] prometheus (UP)
  - [ ] node-exporter (UP)
  - [ ] cadvisor (UP)
- [ ] Query works: `up` query returns results

### Log Verification

- [ ] No error logs:
  ```bash
  docker-compose logs | grep ERROR
  docker-compose logs | grep WARN  # Check critical warns
  ```
- [ ] Nginx logs clean:
  ```bash
  docker-compose logs nginx | head -50
  ```
- [ ] No certificate errors:
  ```bash
  certbot certificates
  sudo tail -f /var/log/letsencrypt/letsencrypt.log
  ```

## Monitoring Setup

- [ ] Prometheus scraping correctly
- [ ] Grafana connected to Prometheus
- [ ] Basic dashboards showing data:
  - [ ] CPU usage
  - [ ] Memory usage
  - [ ] Disk usage
  - [ ] Network metrics
- [ ] Alert rules configured (optional)
- [ ] Notification channels configured (optional)

## Security Review

- [ ] Firewall rules verified: `sudo ufw status`
- [ ] SSH hardening applied
- [ ] .env file not committed: `git status`
- [ ] Sensitive files in .gitignore:
  - [ ] .env
  - [ ] certs/
  - [ ] .secrets/
- [ ] Cloudflare security headers enabled
- [ ] HTTPS redirect working (HTTP → HTTPS)
- [ ] SSL ciphers strong: TLSv1.2 + TLSv1.3 only

## Backup & Recovery

- [ ] Backup location setup: `/backup/` atau cloud storage
- [ ] Backup script created: `scripts/backup.sh`
- [ ] Backup script tested:
  ```bash
  bash scripts/backup.sh
  ```
- [ ] Backup files created:
  - [ ] grafana_*.tar.gz
  - [ ] prometheus_*.tar.gz
  - [ ] portainer_*.tar.gz
- [ ] Restore procedure documented
- [ ] Cron job setup untuk daily backup:
  ```bash
  0 2 * * * /path/to/backup.sh
  ```

## Certificate Renewal

- [ ] Certbot renewal test: `sudo certbot renew --dry-run`
- [ ] Systemd timer active: `sudo systemctl status certbot.timer`
- [ ] Renewal email notifications working
- [ ] Calendar reminder set untuk 1 month sebelum expiry

## Monitoring & Alerting

- [ ] Uptime monitoring service active (Uptime Kuma)
- [ ] Grafana alerts configured (optional)
- [ ] Slack/Email notifications working (optional)
- [ ] Regular backup verification schedule

## Documentation

- [ ] Deployment notes documented
- [ ] VPS IP dan credentials stored securely
- [ ] Emergency access procedure documented
- [ ] Service restart procedures documented
- [ ] Troubleshooting guide created

## Go-Live Final Steps

- [ ] Stakeholders notified
- [ ] Access credentials distributed securely
- [ ] Training completed (if needed)
- [ ] Handoff documentation completed
- [ ] On-call rotation established
- [ ] Post-deployment review scheduled

## Post-Deployment (1 Week)

- [ ] Monitor resource usage
- [ ] Check certificate expiry countdown
- [ ] Review logs untuk any errors
- [ ] Verify backups completed successfully
- [ ] Performance baseline recorded
- [ ] Security audit completed

## Post-Deployment (1 Month)

- [ ] Certificate renewal successful
- [ ] Capacity planning reviewed
- [ ] Disaster recovery procedure tested
- [ ] Performance trends analyzed
- [ ] Security updates applied

---

## Troubleshooting During Deployment

### If containers keep restarting:
```bash
docker-compose logs
docker-compose down -v
# Fix issue, then redeploy
```

### If DNS not resolving:
```bash
# Check Cloudflare DNS records
# Wait 24-48 hours
# Test resolution
nslookup your-domain.com @1.1.1.1
```

### If certificate fails:
```bash
sudo certbot certificates
sudo tail -f /var/log/letsencrypt/letsencrypt.log
# Fix issue, rerun certbot
```

### If services not accessible:
```bash
# Check firewall
sudo ufw status

# Check ports
sudo netstat -tulpn | grep LISTEN

# Check Nginx config
docker exec nginx nginx -t
```

---

## Success Criteria

✅ **Deployment successful when:**

1. All services accessible via HTTPS with valid certificates
2. Dashboards showing real-time metrics
3. No error logs in containers
4. Backup procedure working
5. Performance baseline established
6. Security review passed
7. Team trained on operations

---

**Happy deployment! 🚀**
