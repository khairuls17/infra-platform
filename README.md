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

# Architecture

```text
                ┌─────────────────────┐
                │ Nginx Proxy Manager │
                └──────────┬──────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
┌───────▼────────┐ ┌───────▼────────┐ ┌──────▼────────┐
│   Grafana      │ │  Uptime Kuma   │ │   Portainer   │
└────────────────┘ └────────────────┘ └───────────────┘
                           │
                   ┌───────▼────────┐
                   │   Prometheus   │
                   └────────────────┘
```

---

# Services

| Service             | Function                    |
| ------------------- | --------------------------- |
| Nginx Proxy Manager | Reverse proxy & gateway     |
| Portainer           | Docker container management |
| Grafana             | Monitoring dashboard        |
| Prometheus          | Metrics collection          |
| Uptime Kuma         | Uptime monitoring           |

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

# Notes

This project is built for learning and experimentation purposes.

Infrastructure and services may evolve over time as the project grows.

---

# License

MIT License
