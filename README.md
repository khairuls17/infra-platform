# Infra Platform

Mini infrastructure & DevOps lab project built using Docker, Linux, monitoring stack, automation, and CI/CD workflow.

---

# Overview

Infra Platform adalah project pembelajaran infrastructure engineering dan DevOps yang dijalankan menggunakan Docker Compose di GitHub Codespaces atau VPS Linux.

Project ini dibuat untuk mempelajari:

* Linux Administration
* Docker & Containerization
* Reverse Proxy
* Monitoring & Observability
* Bash Automation
* CI/CD
* Infrastructure as Code
* Networking 

---

# 🎓 Want to Learn How It All Works?

Jangan hanya "copy-paste dan run"! Saya telah siapkan comprehensive guides untuk memahami **bagaimana sebenarnya** semuanya bekerja:

| Resource | Description |
|----------|-------------|
| 📖 [LEARNING_GUIDE.md](docs/LEARNING_GUIDE.md) | Memahami konsep: Docker, Nginx, SSL, DNS, Production Setup |
| 💻 [DIY_EXERCISES.md](docs/DIY_EXERCISES.md) | 5 hands-on exercises - build dari nol & experiment |
| 📚 [INDEX.md](docs/INDEX.md) | Navigation guide untuk semua dokumentasi |

**Recommended Path untuk Learners:**
1. Read [LEARNING_GUIDE.md](docs/LEARNING_GUIDE.md) (2 hours) - Pahami fundamentals
2. Do [DIY_EXERCISES.md](docs/DIY_EXERCISES.md) (2-3 hours) - Practice & build
3. Setup [LOCAL_SETUP.md](docs/LOCAL_SETUP.md) - Experiment locally
4. Deploy [QUICK_START.md](docs/QUICK_START.md) - Go production

---

# 🚀 Deployment Options


## Local Development (Codespaces/Desktop)

Gunakan subpath routing dengan Nginx:
- http://localhost:8080/grafana
- http://localhost:8080/prometheus
- http://localhost:8080/status
- http://localhost:8080/portainer

```bash
docker-compose up -d
```

**Docs:** [Local Setup](docs/LOCAL_SETUP.md)

## Production (VPS + Cloudflare)

Gunakan subdomain routing dengan Let's Encrypt SSL:
- https://grafana.your-domain.com
- https://portainer.your-domain.com
- https://status.your-domain.com
- https://your-domain.com

**Quick Start:** [Deployment Guide](docs/QUICK_START.md)

**Full Setup:** [VPS Deployment](docs/VPS_DEPLOYMENT.md)

**Architecture:** [Production Architecture](docs/PRODUCTION_ARCHITECTURE.md)

**One-line Deploy:**
```bash
bash scripts/deploy.sh your-domain.com admin-password admin@email.com
```

---

# Architecture

```text
                ┌─────────────────────┐
                │   Cloudflare DNS    │
                │ (DNS management)    │
                └──────────┬──────────┘
                           │
                ┌──────────▼──────────┐
                │ Nginx Proxy Manager │
                │  (reverse proxy)    │
                └──────────┬──────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
┌───────▼────────┐ ┌───────▼────────┐ ┌──────▼────────┐
│   Grafana      │ │  Uptime Kuma   │ │   Portainer   │
│ (dashboard)    │ │ (uptime probe) │ │ (container UI)│
└───────┬────────┘ └────────────────┘ └───────────────┘
        │
        │
 ┌──────▼────────┐
 │   Prometheus  │
 │ (metrics DB)  │
 └─────┬───┬────┘
       │   │
  ┌────┴───┴───────┐
  │                │
┌─▼──────────┐ ┌───▼───────┐
│node-       │ │cAdvisor   │
│exporter    │ │(container │
│(host)      │ │ metrics)  │
└────────────┘ └───────────┘
```

---

# Services

| Service             | Function                                |
| ------------------- | --------------------------------------- |
| Cloudflare DNS      | DNS management & edge hostname routing  |
| Nginx Proxy Manager | Reverse proxy & gateway                 |
| Portainer           | Docker container management             |
| Grafana             | Monitoring dashboard                    |
| Prometheus          | Metrics collection                      |
| node-exporter       | Node / host metrics exporter            |
| cAdvisor            | Container metrics exporter              |
| Uptime Kuma         | Uptime monitoring                       |

---

# Project Structure

```text
infra-platform/
├── docker-compose.yml
├── proxy/
│   └── nginx/
├── monitoring/
│   ├── grafana/
│   └── prometheus/
├── uptime/
├── backup/
├── scripts/
├── docs/
├── terraform/
├── .github/
│   └── workflows/
└── README.md
```

---

# Requirements

## Local / Codespaces

* Docker
* Docker Compose
* Git
* Linux environment
  

---

# Getting Started

## 1. Clone Repository

```bash
git clone https://github.com/khairuls17/infra-platform.git
cd infra-platform
```

---

## 2. Start Services

```bash
docker compose up -d
```

---

## 3. Check Running Containers

```bash
docker ps
```

---

# Default Ports

| Service             | Port    |
| ------------------- | ------- |
| Nginx Proxy Manager | 80 / 81 |
| Grafana             | 3000    |
| Prometheus          | 9090    |
| Portainer           | 9000    |
| Uptime Kuma         | 3001    |
| node-exporter       | 9100    |
| cadAdvisor          | 8081    |
---

# Monitoring Stack

## Grafana

Used for:

* CPU monitoring
* RAM monitoring
* Docker metrics
* Infrastructure dashboard

---

## Prometheus

Used for:

* Metrics collection
* Service monitoring
* Infrastructure metrics

---

## Uptime Kuma

Used for:

* Service uptime monitoring
* HTTP monitoring
* Status checks

---

# Automation

## Backup Script

Location:

```text
scripts/backup.sh
```

Features:

* automatic backup
* compression
* log generation
* cleanup old backup

---

# CI/CD

GitHub Actions workflow location:

```text
.github/workflows/
```

Pipeline tasks:

* linting
* docker validation
* build checking
* automation testing

---

# Infrastructure as Code

Terraform configuration location:

```text
terraform/
```

Goals:

* infrastructure provisioning
* Docker automation
* reproducible environment

---

# Learning Goals

This project is intended to improve understanding of:

* Linux server administration
* Docker ecosystem
* Networking basics
* Reverse proxy architecture
* Monitoring & observability
* Automation scripting
* DevOps workflow
* Infrastructure management

---

# Development Workflow

## Daily Workflow

```bash
git pull
docker compose up -d
```

Work on configuration or scripts.

Then:

```bash
git add .
git commit -m "feat: add monitoring"
git push
```

---

# Future Improvements

Planned features:

* centralized logging
* SSL automation
* alerting system
* container auto update
* cloud deployment
* security hardening
* Terraform provisioning

---

# 📚 Documentation

## Deployment Guides

| Guide | Description |
|-------|-------------|
| [Quick Start](docs/QUICK_START.md) | Fast deployment to VPS (start here!) |
| [VPS Deployment](docs/VPS_DEPLOYMENT.md) | Comprehensive step-by-step guide |
| [Production Architecture](docs/PRODUCTION_ARCHITECTURE.md) | Architecture deep-dive & best practices |
| [Grafana Setup](docs/GRAFANA_SETUP.md) | Monitoring dashboard configuration |

## Key Configurations

| File | Purpose |
|------|---------|
| [docker-compose.yml](docker-compose.yml) | Local development setup |
| [docker-compose.prod.yml](docker-compose.prod.yml) | Production setup (with healthchecks, resources) |
| [docker-compose.override.yml](docker-compose.override.yml) | Local overrides for Codespaces |
| [.env.example](.env.example) | Environment variables template |
| [proxy/nginx/default.prod.conf](proxy/nginx/default.prod.conf) | Production Nginx config (subdomains + SSL) |
| [proxy/nginx/default.prod.conf.template](proxy/nginx/default.prod.conf.template) | Nginx template with env support |
| [scripts/deploy.sh](scripts/deploy.sh) | Automated VPS deployment script |

## Deployment Scripts

| Script | Purpose |
|--------|---------|
| [scripts/deploy.sh](scripts/deploy.sh) | One-line VPS deployment automation |
| [scripts/backup.sh](scripts/backup.sh) | Docker volume backup automation |

## GitHub Actions

| Workflow | Purpose |
|----------|---------|
| [.github/workflows/deploy.yml](.github/workflows/deploy.yml) | Auto-deploy on push to main |

---

# 🔧 Technology Stack

| Component | Purpose | Version |
|-----------|---------|---------|
| **Nginx** | Reverse proxy / SSL termination | latest |
| **Grafana** | Monitoring dashboard | latest |
| **Prometheus** | Time-series metrics DB | latest |
| **Node Exporter** | System metrics | latest |
| **cAdvisor** | Container metrics | latest |
| **Uptime Kuma** | Uptime monitoring | latest |
| **Portainer** | Container management | 2.19.4 |
| **Docker Compose** | Orchestration | v2+ |
| **Let's Encrypt** | SSL certificates | via Certbot |
| **Cloudflare** | DNS + CDN | Free plan+ |

---

# 🌐 Services & Access URLs

## Production (with domain)

```
https://domain.com               → Info page
https://grafana.domain.com       → Grafana dashboard
https://portainer.domain.com     → Container management
https://status.domain.com        → Uptime monitoring
https://prometheus.domain.com    → Metrics database
```

## Development (Codespaces)

```
http://localhost:8080/           → Nginx
http://localhost:8080/grafana/   → Grafana
http://localhost:8080/prometheus/→ Prometheus
http://localhost:8080/status/    → Uptime Kuma
http://localhost:8080/portainer/ → Portainer
```

---

# 📋 Quick Commands

### Local Development

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Check status
docker-compose ps

# Stop services
docker-compose down

# Remove everything
docker-compose down -v
```

### Production Deployment

```bash
# Deploy via script (recommended)
bash scripts/deploy.sh domain.com password email@example.com

# Or manual deployment
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# View service status
docker-compose ps

# Check Nginx logs
docker-compose logs nginx

# Verify SSL certificate
echo | openssl s_client -connect domain.com:443

# Check certificate expiry
certbot certificates
```

### Monitoring

```bash
# View Prometheus targets
curl http://localhost:9090/api/v1/targets

# View Node Exporter metrics
curl http://localhost:9100/metrics

# Check container health
docker-compose ps

# Resource usage
docker stats
```

---

# 🐛 Troubleshooting

## Common Issues

| Issue | Solution |
|-------|----------|
| Services not responding | Check `docker-compose ps`, view `docker-compose logs` |
| DNS not resolving | Wait 24-48 hours, verify Cloudflare records |
| SSL certificate error | Verify cert path in docker-compose, run `sudo certbot certificates` |
| High memory usage | Reduce Prometheus retention: `--storage.tsdb.retention.time=7d` |
| Nginx 502 error | Backend service down, check `docker-compose logs nginx` |
| Slow dashboard | Reduce panel count, optimize PromQL queries |

See [VPS_DEPLOYMENT.md](docs/VPS_DEPLOYMENT.md#troubleshooting) untuk detailed troubleshooting guide.

---

# 🔗 Useful Resources

### Deployment & DevOps

- [Cloudflare Docs](https://developers.cloudflare.com/) - DNS & SSL setup
- [Let's Encrypt](https://letsencrypt.org/docs/) - Free SSL certificates
- [Certbot Documentation](https://certbot.eff.org/docs/) - Certificate automation
- [Nginx Documentation](https://nginx.org/en/docs/) - Reverse proxy configuration

### Monitoring & Observability

- [Grafana Docs](https://grafana.com/docs/grafana/) - Dashboard & alerting
- [Prometheus Docs](https://prometheus.io/docs/) - Metrics collection
- [PromQL Tutorial](https://prometheus.io/docs/prometheus/latest/querying/basics/) - Query language
- [Grafana Dashboard Gallery](https://grafana.com/grafana/dashboards) - Pre-built dashboards

### Docker & Infrastructure

- [Docker Docs](https://docs.docker.com/) - Containerization
- [Docker Compose Docs](https://docs.docker.com/compose/) - Multi-container orchestration
- [Docker Networking](https://docs.docker.com/engine/network/) - Network concepts

### Learning

- [DevOps Roadmap](https://roadmap.sh/devops) - Career path & learning resources
- [System Design Primer](https://github.com/donnemartin/system-design-primer) - Architecture patterns
- [Linux Journey](https://linuxjourney.com/) - Linux administration fundamentals

---

# 💡 Learning Path

**Recommended learning sequence:**

1. **Start local** → Run locally with Codespaces (docker-compose.yml)
2. **Understand basics** → Docker networking, reverse proxy concepts
3. **Learn monitoring** → Prometheus, Grafana, metrics collection
4. **Deploy to VPS** → Follow [QUICK_START.md](docs/QUICK_START.md)
5. **Understand production** → Read [PRODUCTION_ARCHITECTURE.md](docs/PRODUCTION_ARCHITECTURE.md)
6. **Configure monitoring** → Follow [GRAFANA_SETUP.md](docs/GRAFANA_SETUP.md)
7. **Advanced topics** → Auto-scaling, CI/CD, backup strategy, security hardening

---

# 🤝 Contributing

Contributions welcome! Areas for improvement:

- [ ] Terraform automation
- [ ] Kubernetes deployment
- [ ] Advanced monitoring dashboards
- [ ] Security hardening guides
- [ ] Multi-region setup
- [ ] Cost optimization

---

# 📝 License

MIT License - feel free to use for learning

---

# ✨ Acknowledgments

Built with inspiration from:

- DevOps community best practices
- Docker documentation
- Prometheus monitoring patterns
- Infrastructure as Code principles

**Happy learning! 🚀**

---



# Notes

This project is built for learning and experimentation purposes.

Infrastructure and services may evolve over time as the project grows.

---

# License

MIT License
