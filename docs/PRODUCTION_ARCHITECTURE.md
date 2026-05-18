# Production Deployment Architecture Guide

Dokumentasi lengkap untuk memahami architecture production deployment infra-platform.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Cloudflare (CDN + DNS)                   │
│  - Global DNS resolution                                    │
│  - DDoS protection                                          │
│  - TLS/SSL offloading (Full/Strict mode)                   │
│  - Always HTTPS redirect                                   │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ HTTPS Port 443
                     │
┌────────────────────▼────────────────────────────────────────┐
│                   Nginx (Reverse Proxy)                      │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Port 80 (HTTP)  → Redirect to HTTPS                │   │
│  │ Port 443 (HTTPS) → SSL/TLS Termination             │   │
│  │                  → Host-based routing              │   │
│  │                  → Load balancing                  │   │
│  │                  → Security headers                │   │
│  │                  → Compression                     │   │
│  └─────────────────────────────────────────────────────┘   │
│  Certificates: /certs/fullchain.pem + privkey.pem         │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────┼────────────┬──────────────┐
        │            │            │              │
        │ Subdomain  │ Subdomain  │ Subdomain   │
        │ Routing    │ Routing    │ Routing     │
        │            │            │             │
┌───────▼──────┐ ┌──▼────────┐ ┌─▼─────────┐  │ Backends
│   Grafana    │ │ Portainer │ │   Status  │  │ (Backend Network)
│ :3000        │ │ :9000     │ │ Kuma:3001 │  │
└──────────────┘ └───────────┘ └───────────┘  │
                     │
        ┌────────────┴────────────┬──────────────┐
        │                         │              │
┌───────▼──────┐      ┌──────────▼───┐  ┌──────▼────────┐
│  Prometheus  │      │ Node Exporter │  │   cAdvisor    │
│   :9090      │      │    :9100      │  │    :8080      │
└──────────────┘      └───────────────┘  └───────────────┘

Monitoring Stack (Internal)
- Prometheus: Time-series database untuk metrics
- Node Exporter: Host/system metrics
- cAdvisor: Container metrics
```

## Network Topology

### Frontend Network
- **Purpose:** Public-facing, accessible dari internet
- **Services:** Nginx reverse proxy
- **Exposure:** Port 80 (HTTP redirect), Port 443 (HTTPS)

### Backend Network
- **Purpose:** Internal communication antar services
- **Services:** Grafana, Prometheus, Portainer, Uptime Kuma, Node Exporter, cAdvisor
- **Isolation:** Internal network, tidak accessible langsung dari internet
- **DNS:** Internal Docker DNS untuk service discovery

## DNS Flow

### With Cloudflare

```
1. Client → Cloudflare (DNS query: grafana.domain.com)
2. Cloudflare → VPS IP (A record resolution)
3. Client → VPS IP Port 443 (TLS handshake)
4. VPS Nginx → Grafana container (internal routing)
```

### DNS Records Setup

```
┌─────────────────────────────────────────────────┐
│ Domain: your-domain.com                         │
├─────────────────────────────────────────────────┤
│ A       @           → VPS IP          [Proxied] │
│ CNAME   grafana     → @                [Proxied] │
│ CNAME   portainer   → @                [Proxied] │
│ CNAME   status      → @                [Proxied] │
│ CNAME   prometheus  → @                [Proxied] │
└─────────────────────────────────────────────────┘
```

## SSL/TLS Certificate Flow

```
Let's Encrypt Certificate Generation
│
├─ Option 1: DNS Challenge (Cloudflare)
│  ├─ Certbot requests DNS token
│  ├─ Certbot adds CNAME record via Cloudflare API
│  ├─ Let's Encrypt validates DNS
│  └─ Certificate issued
│
├─ Option 2: HTTP Challenge
│  ├─ Certbot answers challenge via .well-known/acme-challenge
│  ├─ Let's Encrypt validates HTTP
│  └─ Certificate issued
│
└─ Certificate stored in /etc/letsencrypt/live/domain/
   ├─ fullchain.pem (used in Nginx SSL)
   └─ privkey.pem (used in Nginx SSL)
```

### Certificate Auto-Renewal

```
Systemd Timer (certbot.timer)
│
├─ Checks certificate expiry daily
├─ Runs certbot renew 30 days before expiry
├─ Automatically calls renewal hooks
└─ Nginx reloads updated certificates
```

## Service Routing Logic

### Nginx Host-Based Routing

```nginx
# Request: https://grafana.domain.com/path
server_name grafana.${DOMAIN_NAME};
│
├─ Match domain: grafana.domain.com
├─ TLS termination: /certs/fullchain.pem + privkey.pem
├─ Reverse proxy: proxy_pass http://grafana:3000/path
├─ Set headers: X-Forwarded-*, Host, etc
└─ Response: Grafana container output

# Request: https://domain.com/
server_name ~^(?!grafana\.|...).*$;
│
├─ Default catch-all server block
├─ Returns HTML info page
└─ Lists available services
```

### Cloudflare Flow

```
1. Cloudflare Proxied DNS
   ├─ Intercepts SSL traffic
   ├─ Acts as reverse proxy
   └─ Adds Cloudflare security headers

2. Full (Strict) SSL Mode
   ├─ Client → Cloudflare: HTTPS only
   ├─ Cloudflare → Origin (VPS): HTTPS only
   ├─ Requires valid SSL cert on origin
   └─ Prevents downgrade attacks

3. Always Use HTTPS
   ├─ Automatic 301 redirect
   └─ http:// → https://
```

## Production Best Practices Implemented

### 1. SSL/TLS Security
- [x] TLSv1.2 + TLSv1.3 only
- [x] Strong ciphers configuration
- [x] Session caching for performance
- [x] HSTS header (max-age: 1 year)
- [x] Automatic certificate renewal

### 2. Security Headers
```
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Frame-Options: SAMEORIGIN (prevent clickjacking)
X-Content-Type-Options: nosniff (prevent MIME sniffing)
X-XSS-Protection: 1; mode=block (XSS protection)
```

### 3. Container Security
```docker
# Health checks untuk semua services
healthcheck:
  test: ["CMD", "wget", "--tries=1", "--spider", "http://..."]
  interval: 30s
  timeout: 10s
  retries: 3

# Resource limits
limits:
  cpus: "1"
  memory: 512M

# Restart policy
restart: unless-stopped
```

### 4. Data Persistence
```yaml
volumes:
  grafana_data:       # Grafana dashboards, datasources
  prometheus_data:    # Time-series metrics (30-day retention)
  portainer_data:     # Container management state
  uptime_data:        # Uptime monitoring history
```

### 5. Network Isolation
```yaml
networks:
  frontend:           # Nginx only
    driver: bridge
  backend:            # Internal services
    driver: bridge
    internal: false   # (set to true untuk fully isolated)
```

## Scaling Strategies

### Horizontal Scaling

**Multiple VPS Setup:**
```
                    ┌──────────────┐
                    │  Cloudflare  │
                    │ Load Balance │
                    └─────┬────────┘
                          │
              ┌───────────┼───────────┐
              │           │           │
        ┌─────▼──┐  ┌─────▼──┐  ┌────▼────┐
        │ VPS 1  │  │ VPS 2  │  │ VPS 3   │
        └────────┘  └────────┘  └─────────┘
        (Nginx)     (Nginx)     (Nginx)
              │           │           │
              └───────────┬───────────┘
                    ┌─────▼──────┐
                    │  Shared DB  │ (PostgreSQL)
                    │  Shared Cache│(Redis)
                    └─────────────┘
```

### Vertical Scaling

- Increase VPS resources (CPU, RAM)
- Increase Docker container resource limits
- Increase Prometheus retention period
- Setup Prometheus remote storage

## Monitoring & Observability

### Prometheus Metrics Collection

```
Node Exporter (:9100)
│
├─ CPU usage
├─ Memory usage
├─ Disk usage
├─ Network I/O
└─ System load

cAdvisor (:8080)
│
├─ Container CPU
├─ Container memory
├─ Container network
├─ Container filesystem
└─ Container performance

Grafana Dashboard (:3000)
│
├─ Visualizes metrics
├─ Real-time monitoring
├─ Alerts configuration
└─ Historical analysis
```

### Alert Rules Example

```yaml
groups:
  - name: production
    rules:
      - alert: HighCPUUsage
        expr: node_cpu_seconds > 80
        for: 5m
        annotations:
          summary: "High CPU on {{ $labels.instance }}"

      - alert: DiskSpaceLow
        expr: node_filesystem_avail_bytes < 10GB
        annotations:
          summary: "Low disk space on {{ $labels.device }}"

      - alert: ServiceDown
        expr: up{job="prometheus"} == 0
        for: 1m
        annotations:
          summary: "{{ $labels.job }} is down"
```

## Disaster Recovery

### Backup Strategy

```bash
# Daily automated backups
0 2 * * * /path/to/backup.sh

# Backup locations
- Local: /backup/infra-platform/
- Cloud: S3/GCS (for redundancy)
- Retention: 30 days rolling
```

### Restore Procedure

```bash
# 1. Stop services
docker-compose down

# 2. Restore volumes
docker run --rm -v grafana_data:/data -v /backup:/backup \
  alpine tar xzf /backup/grafana_latest.tar.gz -C /data

# 3. Start services
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## Performance Optimization

### Nginx
- [x] Gzip compression
- [x] Client max body size: 100M (Portainer)
- [x] Proxy timeouts: 60s
- [x] Keep-alive connections
- [x] Session caching

### Prometheus
- [x] Retention: 30 days (configurable)
- [x] Scrape interval: 15s (default)
- [x] Evaluation interval: 15s (default)

### Grafana
- [x] Direct datasource queries
- [x] Query caching
- [x] Panel refresh intervals

## Troubleshooting Guide

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| 502 Bad Gateway | Backend service down | Check `docker-compose ps` |
| Certificate error | Cert not found | Run certbot, copy to /certs/ |
| DNS not resolving | Nameservers not updated | Check registrar, wait propagation |
| High memory | Prometheus retention too high | Reduce `storage.tsdb.retention.time` |
| Slow Grafana | Too many dashboard panels | Optimize panel queries |

### Debug Commands

```bash
# Check services
docker-compose ps
docker-compose logs nginx

# Check ports
netstat -tulpn | grep LISTEN

# Check DNS
nslookup domain.com
dig grafana.domain.com

# Check SSL
echo | openssl s_client -connect domain.com:443

# Check Nginx config
docker exec nginx nginx -t
```

## References

- [Nginx Reverse Proxy](https://nginx.org/en/docs/http/ngx_http_proxy_module.html)
- [Let's Encrypt ACME](https://letsencrypt.org/docs/client-options/)
- [Cloudflare SSL/TLS](https://developers.cloudflare.com/ssl/)
- [Docker Networking](https://docs.docker.com/engine/network/)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/naming/)
