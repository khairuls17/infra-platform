# 🎓 Learning Guide: Setup Dari Nol

Panduan untuk memahami **bagaimana sebenarnya** setup production deployment bekerja. Kami akan build semuanya dari nol dan memahami setiap bagian.

---

## 📚 Apa yang Akan Kita Pelajari

1. **Docker Compose** - Bagaimana orchestration services bekerja
2. **Nginx Reverse Proxy** - Bagaimana routing dan SSL termination
3. **DNS & Cloudflare** - Bagaimana domain name resolution
4. **SSL/TLS Certificates** - Bagaimana HTTPS security bekerja
5. **Networking** - Bagaimana Docker networks dan service discovery
6. **Production Best Practices** - Bagaimana setup production-ready

---

## 🏗️ Fondasi: Memahami Arsitektur

### Pertanyaan Fundamental

Sebelum mulai, mari jawab pertanyaan-pertanyaan ini:

**Q1: Apa itu reverse proxy?**
```
Client → Internet → Router Port 80/443 → Reverse Proxy (Nginx)
                                              ↓
                                    Service A (Grafana :3000)
                                    Service B (Portainer :9000)
                                    Service C (Prometheus :9090)
```

Reverse proxy adalah **gatekeeper** yang:
- Menerima request dari client
- Route ke service yang tepat (berdasarkan domain/path)
- Return response ke client
- Client tidak tahu di mana service sebenarnya

**Q2: Mengapa perlu SSL/TLS?**
```
Tanpa SSL/TLS (HTTP):
Client → [PLAIN TEXT] → Server

Dengan SSL/TLS (HTTPS):
Client → [ENCRYPTED] → Server
(hanya client & server yang tahu isi data)
```

SSL/TLS mengenkripsi data saat transit untuk security.

**Q3: Bagaimana DNS bekerja?**
```
User ketik: https://grafana.domain.com
     ↓
Browser query DNS: "Apa IP dari grafana.domain.com?"
     ↓
DNS Server respond: "IP-nya adalah 1.2.3.4"
     ↓
Browser connect ke 1.2.3.4:443 (HTTPS)
```

DNS adalah "phonebook" internet yang translate nama → IP address.

---

## 🐳 Part 1: Docker Compose Basics

### 1.1 Memahami docker-compose.yml

Buka `docker-compose.yml` lokal:

```yaml
services:
  nginx:
    image: nginx:latest           # Gunakan image nginx dari Docker Hub
    container_name: nginx          # Nama container (unik)
    ports:
      - "8080:80"                 # Map port host:container
                                  # Client connect ke :8080 → nginx port 80
    volumes:
      - ./proxy/nginx/default.conf:/etc/nginx/conf.d/default.conf
                                  # Mount config file lokal ke container
    networks:
      - frontend                  # Container di network "frontend"
    restart: unless-stopped       # Auto-restart jika crash
```

**Penjelasan setiap bagian:**

```yaml
# Container bisa di-view sebagai "mini-VM" terisolasi
ports: "8080:80"
  ↓
Host Machine :8080 ←→ Docker Container :80
       ↑
Ini yang client access dari browser

volumes:
  ./proxy/nginx/default.conf:
    ↓
   File lokal di machine Anda
   /etc/nginx/conf.d/default.conf
    ↓
   Path di dalam container
   (Container baca config dari sini)

networks:
  frontend:
    ↓
   Docker internal network
   Services di network yang sama bisa communicate via name
   contoh: http://grafana:3000 (dari nginx container)
```

### 1.2 Memahami Networks

```yaml
networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge

services:
  nginx:
    networks:
      - frontend          # Nginx hanya di frontend

  grafana:
    networks:
      - backend           # Grafana hanya di backend
```

**Mengapa separation?**

```
Frontend Network (exposed):
  - Nginx :80, :443
  ✓ Accessible dari internet

Backend Network (internal):
  - Grafana, Prometheus, Portainer
  ✗ NOT accessible dari internet langsung
  ✓ Only accessible via Nginx

Benefit:
- Security: Services tidak terekspose langsung
- Control: Semua traffic melalui Nginx
- Routing: Nginx decide service mana yang diakses
```

### 1.3 DIY: Create Simple docker-compose.yml

Mari kita buat minimal docker-compose.yml dari nol:

**Step 1: Create file** `test-compose.yml`:

```yaml
version: '3.8'

services:
  web:
    image: nginx:latest
    ports:
      - "8888:80"
    volumes:
      - ./test-html:/usr/share/nginx/html
    restart: unless-stopped

volumes: {}

networks: {}
```

**Step 2: Create test HTML**:

```bash
mkdir -p test-html
echo "<h1>Hello from Docker!</h1>" > test-html/index.html
```

**Step 3: Run**:

```bash
docker-compose -f test-compose.yml up -d
```

**Step 4: Access**:

```bash
curl http://localhost:8888
# Output: <h1>Hello from Docker!</h1>

# Or open browser: http://localhost:8888
```

**What you learned:**
- ✅ docker-compose.yml structure
- ✅ Image & container concept
- ✅ Port mapping
- ✅ Volume mounting
- ✅ Running services

**Cleanup:**
```bash
docker-compose -f test-compose.yml down
rm -rf test-html test-compose.yml
```

---

## 🌐 Part 2: Nginx Reverse Proxy

### 2.1 Memahami Nginx Config

Nginx config files biasanya di `/etc/nginx/nginx.conf` atau `/etc/nginx/conf.d/`.

**Basic structure:**

```nginx
# Serve static content
server {
    listen 80;                           # Listen di port 80
    server_name example.com;             # Match domain name
    
    location / {                         # URL path matching
        root /usr/share/nginx/html;      # Serve files dari folder ini
    }
}

# Reverse proxy
server {
    listen 80;
    server_name api.example.com;
    
    location / {
        proxy_pass http://backend:3000;  # Forward ke backend service
        proxy_set_header Host $host;     # Pass original host header
    }
}
```

**Key concepts:**

```nginx
server {
    listen 80;
    ↓
    Listen di port 80 HTTP
    
    server_name example.com;
    ↓
    Respond untuk domain "example.com"
    (Nginx bisa handle multiple server blocks)
    
    location /api/ {
        ↓
        Handle requests ke /api/...
        
        proxy_pass http://backend:3000/;
        ↓
        Forward ke http://backend:3000/
        (backend = service name di docker network)
    }
}
```

### 2.2 Memahami Routing

Mari kita trace request path:

**Scenario: User akses https://grafana.domain.com**

```
1. Browser: GET https://grafana.domain.com/
2. DNS resolve: grafana.domain.com → 1.2.3.4 (VPS IP)
3. Browser: CONNECT 1.2.3.4:443
4. TLS Handshake
5. HTTP Request:
   GET / HTTP/1.1
   Host: grafana.domain.com
   
6. Nginx receive request
   - Check: server_name grafana.domain.com
   - Match: server { server_name grafana.domain.com; }
   - Execute: location / { proxy_pass http://grafana:3000/; }
   
7. Nginx forward ke Grafana internal container:
   GET http://grafana:3000/
   
8. Grafana respond:
   HTTP/1.1 200 OK
   Content: Grafana dashboard HTML
   
9. Nginx forward response ke browser

10. Browser render HTML
```

### 2.3 DIY: Build Simple Reverse Proxy

**Step 1: Create nginx config** - `test-nginx.conf`:

```nginx
# Upstream services
upstream app1 {
    server app1:5000;
}

upstream app2 {
    server app2:5001;
}

# Default server
server {
    listen 80 default_server;
    
    location / {
        return 200 "Hello from Nginx\n";
        add_header Content-Type text/plain;
    }
}

# Route app1.localhost → app1:5000
server {
    listen 80;
    server_name app1.localhost;
    
    location / {
        proxy_pass http://app1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

# Route app2.localhost → app2:5001
server {
    listen 80;
    server_name app2.localhost;
    
    location / {
        proxy_pass http://app2;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

**Step 2: Create docker-compose** - `test-proxy.yml`:

```yaml
version: '3.8'

services:
  nginx:
    image: nginx:latest
    ports:
      - "8889:80"
    volumes:
      - ./test-nginx.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      - test-net
    depends_on:
      - app1
      - app2

  app1:
    image: kennethreitz/httpbin
    networks:
      - test-net

  app2:
    image: kennethreitz/httpbin
    networks:
      - test-net

networks:
  test-net:
    driver: bridge
```

**Step 3: Run & Test**:

```bash
# Start
docker-compose -f test-proxy.yml up -d

# Wait for startup
sleep 5

# Test default route
curl http://localhost:8889/
# Output: Hello from Nginx

# Test app1 route
curl -H "Host: app1.localhost" http://localhost:8889/
# Output: httpbin response

# Check inside nginx container
docker-compose -f test-proxy.yml exec nginx ping app1
# ✓ Can resolve app1 DNS

# Stop
docker-compose -f test-proxy.yml down
```

**What you learned:**
- ✅ Nginx server blocks
- ✅ Upstream configuration
- ✅ Host-based routing
- ✅ Proxy headers
- ✅ Docker DNS resolution

---

## 🔐 Part 3: SSL/TLS & Certificates

### 3.1 Memahami SSL/TLS Flow

**HTTP (Unencrypted):**
```
Client                          Server
  │                              │
  ├─→ GET /data ─────────────→   │
  │   (PLAIN TEXT)               │
  │                              │
  │←──── {sensitive_data} ←──────┤
  │   (PLAIN TEXT, anyone can read)
```

**HTTPS (Encrypted with TLS):**
```
Client                          Server
  │                              │
  ├─→ TLS Handshake ────────→    │
  │   (Exchange encryption keys) │
  │←─── Cert + Keys ───────────  │
  │                              │
  ├─→ [ENCRYPTED] GET /data ──→  │
  │                              │
  │←──── [ENCRYPTED] response ──  │
       (Only client can decrypt)
```

### 3.2 Memahami Certificates

Certificate adalah file yang:
1. **Membuktikan** bahwa server adalah yang dia klaim
2. **Menyimpan public key** untuk encryption
3. **Ditanda-tangan** oleh Certificate Authority (CA) yang terpercaya

```
Certificate contains:
┌─────────────────────────────┐
│ Domain: grafana.domain.com  │
│ Public Key: 0x123abc...     │
│ Issued By: Let's Encrypt    │
│ Valid Until: 2025-05-18     │
│ Signature: 0xdef456...      │
└─────────────────────────────┘

Browser checks:
1. Is cert valid? (not expired)
2. Does domain match? (grafana.domain.com)
3. Is it signed by trusted CA? (Let's Encrypt is in trusted list)

If all ✓, show lock icon 🔒
```

### 3.3 Let's Encrypt Flow

```
Your Server                Let's Encrypt              Your Domain
    │                            │                        │
    ├─→ Request cert ────────→   │                        │
    │                            │                        │
    │←─── Challenge type ────────┤                        │
    │   (prove domain ownership) │                        │
    │                            │                        │
    ├─→ DNS / HTTP challenge ────────────────────────→   │
    │   (prove you control domain)                        │
    │                            │←─ Verify challenge ←───┤
    │                            │                        │
    │←───── Certificate ─────────┤                        │
    │                            │                        │
    ✓ Install cert & use
```

**Two challenge methods:**

```
DNS Challenge:
  Certbot adds DNS record
  → Let's Encrypt checks DNS record
  → Simpler, works with firewall

HTTP Challenge:
  Certbot serves file at .well-known/acme-challenge/
  → Let's Encrypt HTTP GET file
  → Requires port 80 open
```

### 3.4 DIY: Get Self-Signed Certificate

**Step 1: Generate self-signed cert** (untuk testing):

```bash
# Generate private key + self-signed cert
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes

# Fill in prompts (hostname: localhost)
# Output: key.pem, cert.pem
```

**Step 2: Create HTTPS Nginx config**:

```nginx
server {
    listen 443 ssl;
    server_name localhost;
    
    ssl_certificate /etc/nginx/certs/cert.pem;
    ssl_certificate_key /etc/nginx/certs/key.pem;
    
    location / {
        return 200 "HTTPS works!";
        add_header Content-Type text/plain;
    }
}

# Redirect HTTP → HTTPS
server {
    listen 80;
    server_name _;
    return 301 https://$host$request_uri;
}
```

**Step 3: Create docker-compose** - `test-https.yml`:

```yaml
version: '3.8'

services:
  nginx:
    image: nginx:latest
    ports:
      - "8080:80"
      - "8443:443"
    volumes:
      - ./test-https.conf:/etc/nginx/conf.d/default.conf:ro
      - ./certs:/etc/nginx/certs:ro
    restart: unless-stopped
```

**Step 4: Run & Test**:

```bash
# Create certs dir
mkdir -p certs

# Generate certificate (as above)
openssl req -x509 -newkey rsa:2048 -keyout certs/key.pem -out certs/cert.pem -days 365 -nodes -subj "/CN=localhost"

# Start
docker-compose -f test-https.yml up -d

# Test (ignore certificate warning)
curl -k https://localhost:8443/
# Output: HTTPS works!

# Test redirect
curl -L http://localhost:8080/
# Should redirect & show HTTPS response

# Stop
docker-compose -f test-https.yml down
```

**What you learned:**
- ✅ SSL/TLS encryption concepts
- ✅ Certificate structure
- ✅ HTTPS in Nginx
- ✅ Certificate generation
- ✅ HTTP → HTTPS redirect

---

## 🌍 Part 4: DNS & Cloudflare

### 4.1 Memahami DNS

**DNS adalah "phonebook" internet:**

```
User: "What is the IP for grafana.domain.com?"
     ↓
Browser DNS client
     ↓
Query DNS resolver (8.8.8.8, 1.1.1.1, ISP DNS)
     ↓
Resolver query: "domain.com?"
     ↓
Cloudflare DNS Server
     ↓
Response: "grafana.domain.com = 1.2.3.4"
     ↓
Browser: "OK, I'll connect to 1.2.3.4"
```

### 4.2 DNS Records

**Common record types:**

```
A Record:
  domain.com → 1.2.3.4
  (IPv4 address)

CNAME Record:
  subdomain.domain.com → domain.com
  (Alias to another domain)

MX Record:
  domain.com → mail.domain.com
  (Mail server)

TXT Record:
  Arbitrary text (used for verification, DKIM, etc)
```

**Scenario: Setup subdomains**

```
DNS Records kita buat:
┌─────────────────────────────────────┐
│ Type │ Name      │ Target           │
├─────────────────────────────────────┤
│ A    │ @         │ 1.2.3.4          │ ← Main VPS IP
│ CNAME│ grafana   │ @ (domain.com)   │ ← Points to main
│ CNAME│ portainer │ @ (domain.com)   │
│ CNAME│ status    │ @ (domain.com)   │
└─────────────────────────────────────┘

Resolution:
┌─────────────────────────────────────┐
│ grafana.domain.com → 1.2.3.4        │
│ portainer.domain.com → 1.2.3.4      │
│ status.domain.com → 1.2.3.4         │
└─────────────────────────────────────┘

All point to same IP!
(Nginx decide based on server_name)
```

### 4.3 DIY: Test DNS Locally

**Step 1: Edit /etc/hosts** (local DNS override):

```bash
sudo nano /etc/hosts

# Add lines:
127.0.0.1  grafana.local
127.0.0.1  portainer.local
127.0.0.1  status.local
```

**Step 2: Create Nginx config** - `test-dns.conf`:

```nginx
upstream grafana_backend {
    server grafana:3000;
}

upstream portainer_backend {
    server portainer:9000;
}

# Grafana subdomain
server {
    listen 80;
    server_name grafana.local;
    
    location / {
        proxy_pass http://grafana_backend;
        proxy_set_header Host $host;
    }
}

# Portainer subdomain
server {
    listen 80;
    server_name portainer.local;
    
    location / {
        proxy_pass http://portainer_backend;
        proxy_set_header Host $host;
    }
}
```

**Step 3: Test**:

```bash
# Check DNS resolution locally
nslookup grafana.local
# Output: 127.0.0.1

# Access via domain
curl http://grafana.local:8080/
# Works because:
# 1. grafana.local → 127.0.0.1 (from /etc/hosts)
# 2. Nginx server_name grafana.local matches
# 3. Nginx forward ke grafana:3000
```

**What you learned:**
- ✅ DNS record types
- ✅ Subdomain setup
- ✅ Host-based routing with DNS
- ✅ Local DNS testing

---

## 🏢 Part 5: Production Setup

### 5.1 Building Real Production docker-compose.yml

Sekarang mari kita build dari nol dengan understanding yang sudah kita pelajari.

**Step 1: Start with basics**:

```yaml
version: '3.8'

services:
  # Reverse proxy - di frontend network (exposed)
  nginx:
    image: nginx:latest
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - ./certs:/etc/nginx/certs:ro
    networks:
      - frontend
    restart: unless-stopped

  # Grafana - di backend network (internal only)
  grafana:
    image: grafana/grafana:latest
    expose:
      - "3000"  # No ports: exposed to docker, not to host
    volumes:
      - grafana_data:/var/lib/grafana
    networks:
      - backend
    restart: unless-stopped

  # Prometheus - di backend network
  prometheus:
    image: prom/prometheus:latest
    expose:
      - "9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    networks:
      - backend
    restart: unless-stopped

volumes:
  grafana_data:
  prometheus_data:

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
```

**Why expose vs ports?**

```yaml
ports:
  - "80:80"
  ↓
Host:80 ← Docker:80 ← Internet accessible ✓
(Nginx needs this - it's public-facing)

expose:
  - "3000"
  ↓
Only available to other containers ✓
(Grafana doesn't need public access)
```

### 5.2 Production Nginx Configuration

Mari kita build nginx config dari nol:

```nginx
# ============================================
# HTTP → HTTPS Redirect
# ============================================
server {
    listen 80;
    server_name _;
    
    # Allow Let's Encrypt validation
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    # Redirect everything else to HTTPS
    location / {
        return 301 https://$host$request_uri;
    }
}

# ============================================
# HTTPS - Grafana Subdomain
# ============================================
server {
    listen 443 ssl http2;
    server_name grafana.domain.com;
    
    # SSL Configuration
    ssl_certificate /etc/nginx/certs/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    # Reverse Proxy
    location / {
        proxy_pass http://grafana:3000/;
        
        # Forward headers
        proxy_set_header Host grafana:3000;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Websocket support
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}

# ============================================
# HTTPS - Prometheus Subdomain
# ============================================
server {
    listen 443 ssl http2;
    server_name prometheus.domain.com;
    
    # ... SSL config (same as above)
    
    location / {
        proxy_pass http://prometheus:9090/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# ============================================
# Main Domain - Info Page
# ============================================
server {
    listen 443 ssl http2;
    server_name domain.com;
    
    # ... SSL config
    
    location / {
        return 200 "Infrastructure Dashboard";
        add_header Content-Type text/plain;
    }
}
```

### 5.3 Complete Production Setup - DIY

**Exercise: Build production setup dari nol**

1. **Create directories:**
   ```bash
   mkdir -p prod-setup/{nginx,prometheus,grafana,certs}
   cd prod-setup
   ```

2. **Create docker-compose.yml:**
   ```yaml
   # (copy dari section 5.1 above)
   ```

3. **Create nginx.conf:**
   ```nginx
   # (copy dari section 5.2 above)
   ```

4. **Create prometheus.yml:**
   ```yaml
   global:
     scrape_interval: 15s
   
   scrape_configs:
     - job_name: 'prometheus'
       static_configs:
         - targets: ['prometheus:9090']
     
     - job_name: 'grafana'
       static_configs:
         - targets: ['grafana:3000']
   ```

5. **Generate self-signed cert (testing):**
   ```bash
   openssl req -x509 -newkey rsa:2048 \
     -keyout certs/privkey.pem \
     -out certs/fullchain.pem \
     -days 365 -nodes \
     -subj "/CN=domain.com"
   ```

6. **Run:**
   ```bash
   docker-compose up -d
   docker-compose ps
   ```

7. **Test:**
   ```bash
   # Edit /etc/hosts
   127.0.0.1  grafana.local
   127.0.0.1  prometheus.local
   
   # Access (ignore cert warning)
   curl -k https://grafana.local:443/
   ```

**What you learned:**
- ✅ Building production docker-compose from scratch
- ✅ Configuring Nginx for multiple services
- ✅ Network isolation (frontend/backend)
- ✅ SSL configuration in production
- ✅ Complete system integration

---

## 🎯 Kesimpulan Learning Path

### Apa yang telah Anda pahami:

1. **Docker Compose** ✅
   - Services, networks, volumes
   - Port mapping & networking
   - Container orchestration

2. **Reverse Proxy** ✅
   - Routing based on domain/path
   - Header forwarding
   - Load balancing concept

3. **SSL/TLS** ✅
   - How encryption works
   - Certificate structure
   - HTTPS flow

4. **DNS** ✅
   - Domain resolution
   - Subdomain setup
   - DNS records

5. **Production Setup** ✅
   - Building from components
   - Best practices
   - Security hardening

### Next Level Learning:

1. **Infrastructure as Code:**
   - Terraform untuk provision VPS
   - Automated deployment
   - Reproducible setup

2. **Monitoring & Observability:**
   - Prometheus metrics
   - Grafana dashboards
   - Alert rules

3. **CI/CD:**
   - GitHub Actions
   - Automated testing
   - Continuous deployment

4. **Security:**
   - Network policies
   - RBAC
   - Secret management

5. **Scaling:**
   - Load balancing
   - Multi-region deployment
   - Auto-scaling

---

## 🔗 Recommended Learning Resources

### Official Documentation
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)
- [Nginx](https://nginx.org/en/docs/)
- [Let's Encrypt](https://letsencrypt.org/docs/)

### Interactive Learning
- [Docker Labs](https://labs.play-with-docker.com/)
- [Nginx Playground](https://www.nginx.com/resources/glossary/reverse-proxy/)
- [TLS Explained](https://tls.ulfheim.net/)

### Hands-On Practice
- Set up local docker-compose ✓ (you did this)
- Build custom Nginx config ✓ (DIY exercise)
- Create certificates ✓ (DIY exercise)
- Deploy to real VPS ← Next!

---

## ✨ Sekarang Apa?

Sekarang yang Anda sudah memahami **how things work**, Anda siap untuk:

1. **Deploy ke VPS** → [docs/QUICK_START.md](../QUICK_START.md)
2. **Customize setup** → Edit config sesuai kebutuhan
3. **Troubleshoot issues** → Understand root cause
4. **Optimize performance** → Know what to tune
5. **Build advanced setups** → Add more services dengan confidence

---

**Semoga pembelajaran ini membantu Anda memahami infrastruktur dengan lebih dalam! 🚀**

Lebih baik memahami fundamental daripada hanya "copy-paste dan pray it works" 😊
