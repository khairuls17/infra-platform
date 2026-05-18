# Grafana Production Setup Guide

Panduan lengkap untuk setup Grafana di production environment.

## Access Grafana

1. **URL:** https://grafana.your-domain.com
2. **Default Login:** admin / (password dari .env)
3. **First Steps:**
   - [ ] Change admin password
   - [ ] Setup data sources
   - [ ] Import dashboards
   - [ ] Configure alerts
   - [ ] Create user accounts

---

## Initial Configuration

### 1. Login & Change Password

```
1. Access https://grafana.your-domain.com
2. Login dengan admin / GF_ADMIN_PASSWORD
3. Click profile → Change password
4. Setup strong password
```

### 2. Add Prometheus Data Source

1. Go to **Configuration** → **Data Sources**
2. Click **Add data source**
3. Select **Prometheus**
4. Configure:
   - **Name:** Prometheus (or any name)
   - **URL:** http://prometheus:9090
   - **Access:** Server (default)
   - **HTTP Method:** GET
   - Click **Save & test**

Expected result: `✓ Prometheus is ready to use`

### 3. Create API Token (untuk automation)

1. Go to **Configuration** → **API tokens**
2. Click **New API token**
3. Configure:
   - **Token name:** grafana-api (or any name)
   - **Role:** Admin (atau sesuai kebutuhan)
   - **Time to live:** Tidak ada expiry (atau set sesuai kebutuhan)
4. Copy token dan simpan di tempat aman

---

## Dashboard Setup

### Import Pre-built Dashboards

#### 1. Node Exporter Dashboard

```
1. Go to **Dashboards** → **Import**
2. Masukkan ID: 1860
3. Pilih data source: Prometheus
4. Import
```

**Menampilkan:**
- CPU usage
- Memory usage
- Disk usage
- Network I/O
- System load

#### 2. cAdvisor Dashboard

```
1. Go to **Dashboards** → **Import**
2. Masukkan ID: 14282 (atau cari "cAdvisor" di Grafana marketplace)
3. Pilih data source: Prometheus
4. Import
```

**Menampilkan:**
- Container CPU usage
- Container memory usage
- Container network metrics
- Container restart count

#### 3. Docker & System Stats Dashboard

```
1. Go to **Dashboards** → **Import**
2. Masukkan ID: 11074
3. Pilih data source: Prometheus
4. Import
```

### Create Custom Dashboard

#### Example: System Overview Dashboard

1. Go to **Dashboards** → **New Dashboard**
2. Click **Add panel**
3. Configure queries:

**Panel 1: CPU Usage**
```
PromQL Query: rate(node_cpu_seconds_total[5m]) * 100
Visualization: Graph
```

**Panel 2: Memory Usage**
```
PromQL Query: 100 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes * 100)
Visualization: Gauge
```

**Panel 3: Disk Usage**
```
PromQL Query: 100 - (node_filesystem_avail_bytes / node_filesystem_size_bytes * 100)
Visualization: Pie Chart
```

**Panel 4: Network Traffic**
```
Received: rate(node_network_receive_bytes_total[5m])
Sent: rate(node_network_transmit_bytes_total[5m])
Visualization: Graph
```

4. Click **Save dashboard**

---

## Alerting Setup

### Alert Rules Configuration

Edit Prometheus configuration di `monitoring/prometheus/prometheus.yml`:

```yaml
groups:
  - name: system_alerts
    interval: 30s
    rules:
      - alert: HighCPUUsage
        expr: rate(node_cpu_seconds_total[5m]) > 0.8
        for: 5m
        annotations:
          summary: "High CPU usage detected"
          description: "CPU usage is {{ $value | humanizePercentage }} on {{ $labels.instance }}"

      - alert: HighMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) > 0.9
        for: 5m
        annotations:
          summary: "High memory usage detected"
          description: "Memory usage is {{ $value | humanizePercentage }} on {{ $labels.instance }}"

      - alert: DiskSpaceLow
        expr: (node_filesystem_avail_bytes / node_filesystem_size_bytes) < 0.1
        for: 5m
        annotations:
          summary: "Low disk space detected"
          description: "{{ $value | humanizePercentage }} disk space available on {{ $labels.device }}"

      - alert: ServiceDown
        expr: up{job="prometheus"} == 0
        for: 1m
        annotations:
          summary: "{{ $labels.job }} is down"
          description: "Service {{ $labels.job }} on {{ $labels.instance }} is not responding"
```

### Configure Alert Notification

1. Go to **Alerting** → **Notification channels**
2. Click **New channel**
3. Select type: Email, Slack, PagerDuty, etc
4. Configure:
   - **Name:** Alert Channel Name
   - **Type:** Email / Slack / etc
   - **Settings:** (sesuai tipe)
5. Click **Send test notification**
6. Save

**Example Email Setup:**
```
- Name: Email Alerts
- Type: Email
- Email addresses: admin@example.com
```

**Example Slack Setup:**
```
- Name: Slack Alerts
- Type: Slack
- Webhook URL: https://hooks.slack.com/services/...
```

### Create Alert Rule in Grafana

1. Go ke dashboard dengan panel
2. Click panel title → **Edit**
3. Scroll down ke **Alert** tab
4. Klik **Create Alert**
5. Configure:
   - **Condition:** Select metric
   - **Evaluate every:** 1m
   - **For:** 5m
   - **Send to:** Pilih notification channel
6. Save

---

## User & Organization Management

### Create Users

1. Go to **Administration** → **Users**
2. Click **New user**
3. Configure:
   - **Name:** User full name
   - **Email:** user@example.com
   - **Username:** username
   - **Password:** Strong password
   - **Role:** Admin / Editor / Viewer
4. Create

### Create Organization

1. Go to **Administration** → **Organizations**
2. Click **New organization**
3. Configure:
   - **Name:** Organization name
   - **Admin:** Select admin user
4. Create

### Manage Permissions

1. Go to **Administration** → **Teams**
2. Create team atau manage existing
3. Assign users dan set permissions
4. Manage dashboard access

---

## Performance Optimization

### Query Optimization

```yaml
# Good PromQL queries (efficient)
- rate(node_cpu_seconds_total[5m])  # Uses rate() untuk time-series
- increase(http_requests_total[5m])  # Uses increase() untuk counters

# Avoid (inefficient)
- node_cpu_seconds_total / 60      # Raw division
- sum without (mode) (node_cpu_seconds_total)  # Avoid large cardinality
```

### Dashboard Best Practices

1. **Limit panels per dashboard:**
   - Target: 8-10 panels
   - Maximum: 20 panels
   - Reason: Reduces load time dan resource usage

2. **Set refresh intervals:**
   - Slow: 1 minute
   - Normal: 30 seconds
   - Fast: 10 seconds
   - Reason: Balance between freshness dan performance

3. **Use dashboard variables:**
   ```
   - Job: prometheus, node, cadvisor
   - Instance: {{instance}}
   ```

4. **Cache queries:**
   - Configure data source caching
   - Use `$__interval` untuk dynamic intervals

### Resource Limits

Configure di docker-compose.prod.yml:

```yaml
grafana:
  deploy:
    resources:
      limits:
        cpus: '1'
        memory: 1G
      reservations:
        cpus: '0.5'
        memory: 512M
```

---

## Backup & Restore

### Backup Grafana Configuration

```bash
# Backup Grafana data volume
docker run --rm -v grafana_data:/data -v $(pwd):/backup \
  alpine tar czf /backup/grafana_backup.tar.gz -C /data .

# Backup PostgreSQL database (jika menggunakan DB eksternal)
docker exec grafana-db pg_dump -U postgres grafana > grafana_db_backup.sql
```

### Restore Grafana

```bash
# Stop services
docker-compose down

# Restore volume
docker run --rm -v grafana_data:/data -v $(pwd):/backup \
  alpine tar xzf /backup/grafana_backup.tar.gz -C /data

# Start services
docker-compose up -d
```

---

## Provisioning (Infrastructure as Code)

### Auto-provision Datasources

Create file: `monitoring/grafana/datasources.yml`

```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
```

Mount di docker-compose.yml:

```yaml
grafana:
  volumes:
    - ./monitoring/grafana/datasources.yml:/etc/grafana/provisioning/datasources/datasources.yml
```

### Auto-provision Dashboards

Create folder: `monitoring/grafana/dashboards/`

Download dashboard JSON, masukkan ke folder.

Create file: `monitoring/grafana/dashboards.yml`

```yaml
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    editable: true
    options:
      path: /etc/grafana/provisioning/dashboards
```

---

## Troubleshooting

### Grafana tidak accessible

```bash
# Check container
docker-compose ps grafana
docker-compose logs grafana

# Check network
docker network inspect infra-platform_backend

# Test connection
docker-compose exec grafana curl -I http://localhost:3000
```

### Prometheus datasource tidak bisa connect

```bash
# Verify Prometheus running
docker-compose ps prometheus

# Test connection dari Grafana
docker-compose exec grafana curl http://prometheus:9090
```

### Memory usage tinggi

```bash
# Check Grafana memory
docker stats grafana

# Reduce retention period
# Edit monitoring/prometheus/prometheus.yml
# Ubah --storage.tsdb.retention.time=7d (dari 30d)

# Restart Prometheus
docker-compose restart prometheus
```

### Dashboard loading slow

```
1. Reduce number of panels
2. Increase query intervals
3. Optimize PromQL queries
4. Check Prometheus storage capacity
5. Archive old dashboards
```

---

## Monitoring Best Practices

1. **Start Simple:**
   - Begin dengan pre-built dashboards
   - Learn PromQL gradually

2. **Understand Your Data:**
   - Know what metrics you're collecting
   - Understand metric cardinality
   - Monitor cardinality itself

3. **Alert Smartly:**
   - Alert on symptoms, not causes
   - Set meaningful thresholds
   - Route alerts appropriately

4. **Regular Maintenance:**
   - Review and archive old dashboards
   - Clean up unused datasources
   - Audit user permissions

5. **Documentation:**
   - Document dashboard purposes
   - Document alert thresholds
   - Document runbooks

---

## Useful Resources

- [Grafana Documentation](https://grafana.com/docs/grafana/)
- [PromQL Tutorial](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Grafana Dashboard Repository](https://grafana.com/grafana/dashboards)
- [Alert Rules Examples](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/)
- [Grafana API Documentation](https://grafana.com/docs/grafana/latest/http_api/)
