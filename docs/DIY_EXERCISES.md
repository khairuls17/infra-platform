# 🛠️ DIY Exercise: Build Everything From Scratch

Panduan praktis untuk membuat dan memahami setiap komponen setup dari nol. Anda akan:
- Membuat config files sendiri
- Memahami setiap line
- Troubleshoot ketika ada error
- Learn by doing!

---

## 🎯 Persyaratan

- Waktu: 2-3 jam
- Docker & Docker Compose installed
- Text editor (VS Code recommended)
- Terminal knowledge basic
- Semua sudah read: [LEARNING_GUIDE.md](LEARNING_GUIDE.md)

---

## Exercise 1: Simple Docker Service

### Goal
Membuat docker service paling simple dan understand bagaimana container bekerja.

### Step 1: Create docker-compose.yml

File: `exercises/ex1-simple/docker-compose.yml`

```yaml
version: '3.8'

services:
  hello:
    image: alpine:latest
    container_name: hello-container
    command: /bin/sh -c "echo 'Hello from Docker!'; sleep 3600"
    restart: unless-stopped
```

### Step 2: Run & Explore

```bash
cd exercises/ex1-simple

# Start service
docker-compose up -d

# List containers
docker-compose ps

# View logs
docker-compose logs

# Execute command in container
docker-compose exec hello sh
# Inside container:
# / # echo "I'm inside the container!"
# / # ls /
# / # exit

# Stop service
docker-compose down
```

### Step 3: Understanding Commands

**Buat yourself file** `NOTES.md` di folder exercise dan tulis:

```markdown
## Docker Compose Commands Explained

### docker-compose up -d
- up: Start services
- -d: Detached (background)
- Without -d: Show logs in foreground

### docker-compose ps
- List running containers
- Shows: Container name, image, status, ports

### docker-compose exec hello sh
- exec: Execute command in container
- hello: Container name
- sh: Command to execute (shell)

### docker-compose logs
- Show container output
- -f: Follow (like tail -f)

### docker-compose down
- Stop and remove containers
- Containers removed, but data in volumes persist
```

### 🎯 What You Learned
- ✅ Basic docker-compose file structure
- ✅ Container lifecycle (up/down)
- ✅ Container interaction
- ✅ Logging

### 🤔 Experiment Questions
1. Change `sleep 3600` to `sleep 1`. Apa yang terjadi?
2. Remove `restart: unless-stopped`. Apa beda-nya?
3. Add `ports: - "8000:80"`. Apa yang terjadi?

---

## Exercise 2: Simple Web Service

### Goal
Menjalankan web service (Nginx) dan akses via browser/curl.

### Step 1: Create HTML

File: `exercises/ex2-web/html/index.html`

```html
<!DOCTYPE html>
<html>
<head>
    <title>My First Docker Web App</title>
</head>
<body>
    <h1>Hello! I'm running in Docker 🐳</h1>
    <p>Container IP: <code>172.x.x.x</code></p>
</body>
</html>
```

### Step 2: Create docker-compose.yml

File: `exercises/ex2-web/docker-compose.yml`

```yaml
version: '3.8'

services:
  web:
    image: nginx:latest
    container_name: web-container
    ports:
      - "8000:80"  # Host:Container
    volumes:
      - ./html:/usr/share/nginx/html:ro  # ro = read-only
    restart: unless-stopped
```

### Step 3: Run & Access

```bash
cd exercises/ex2-web

# Start
docker-compose up -d

# Test curl
curl http://localhost:8000

# Or open browser
open http://localhost:8000  # macOS
# or
xdg-open http://localhost:8000  # Linux

# View Nginx logs
docker-compose logs web

# Stop
docker-compose down
```

### 🎯 What You Learned
- ✅ Port mapping (host:container)
- ✅ Volume mounting
- ✅ Web service (Nginx)
- ✅ Accessing from host machine

### 🤔 Experiment Questions
1. Ubah HTML content. Perlu restart container? (Hint: Check volume mounting)
2. Ubah port 8000 ke 9000. Apa harus ubah HTML?
3. Akses dari `localhost` vs `127.0.0.1`. Ada beda?

---

## Exercise 3: Multiple Services & Networking

### Goal
Memahami bagaimana 2+ services berkomunikasi di Docker network.

### Step 1: Create Backend Service

File: `exercises/ex3-network/app.py`

```python
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return 'Hello from Backend! 🚀'

@app.route('/data')
def data():
    return {'message': 'Data from backend', 'status': 'ok'}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

### Step 2: Create docker-compose.yml

File: `exercises/ex3-network/docker-compose.yml`

```yaml
version: '3.8'

services:
  # Frontend
  nginx:
    image: nginx:latest
    container_name: nginx-frontend
    ports:
      - "8001:80"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      - app-network
    depends_on:
      - backend
    restart: unless-stopped

  # Backend
  backend:
    image: python:3.9-slim
    container_name: python-backend
    command: pip install flask && python app.py
    volumes:
      - ./app.py:/app/app.py
    working_dir: /app
    networks:
      - app-network
    restart: unless-stopped
    expose:
      - "5000"  # Only to other containers, not to host

networks:
  app-network:
    driver: bridge
```

### Step 3: Create Nginx Config

File: `exercises/ex3-network/nginx.conf`

```nginx
upstream backend {
    server backend:5000;  # backend = container name in network
}

server {
    listen 80;
    
    location / {
        return 200 "Frontend: Nginx\n";
        add_header Content-Type text/plain;
    }
    
    location /api/ {
        proxy_pass http://backend/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Step 4: Run & Test

```bash
cd exercises/ex3-network

# Start
docker-compose up -d

# Test from host (via nginx)
curl http://localhost:8001/
# Output: Frontend: Nginx

curl http://localhost:8001/api/
# Output: Hello from Backend! 🚀

# Check network
docker network ls
docker network inspect ex3-network_app-network

# Inside Nginx, test backend resolution
docker-compose exec nginx ping backend
# ✓ Works! (Docker DNS resolution)

# Try direct access to backend from host (should fail)
curl http://localhost:5000/
# ✗ Connection refused (backend not exposed)

# Stop
docker-compose down
```

### 🎯 What You Learned
- ✅ Custom networks
- ✅ Service-to-service communication
- ✅ Docker DNS (container name resolution)
- ✅ Port exposure (expose vs ports)
- ✅ Reverse proxy routing

### 🤔 Experiment Questions
1. Remove `networks: - app-network` dari backend. Apa terjadi?
2. Ubah `expose: - "5000"` ke `ports: - "5000:5000"`. Apa bedanya?
3. Ganti `backend:5000` dengan IP address (inspect network untuk IP). Apa lebih baik?

---

## Exercise 4: Reverse Proxy with SSL

### Goal
Build production-like Nginx dengan SSL termination.

### Step 1: Generate Self-Signed Certificate

```bash
mkdir -p exercises/ex4-ssl/certs

cd exercises/ex4-ssl/certs

# Generate private key
openssl genrsa -out privkey.pem 2048

# Generate certificate (valid 365 days)
openssl req -new -x509 -key privkey.pem -out fullchain.pem -days 365 \
  -subj "/C=ID/ST=Jakarta/L=Jakarta/O=MyOrg/CN=localhost"

# Verify
openssl x509 -in fullchain.pem -text -noout | head -20
```

### Step 2: Create Nginx Config with SSL

File: `exercises/ex4-ssl/nginx.conf`

```nginx
# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name _;
    return 301 https://$host$request_uri;
}

# HTTPS Server
server {
    listen 443 ssl http2;
    server_name localhost;
    
    # SSL Certificates
    ssl_certificate /etc/nginx/certs/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/privkey.pem;
    
    # SSL Configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    
    location / {
        return 200 'HTTPS is working! 🔐\n';
        add_header Content-Type text/plain;
    }
}
```

### Step 3: Create docker-compose.yml

File: `exercises/ex4-ssl/docker-compose.yml`

```yaml
version: '3.8'

services:
  nginx:
    image: nginx:latest
    ports:
      - "8002:80"
      - "8443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - ./certs:/etc/nginx/certs:ro
    restart: unless-stopped
```

### Step 4: Run & Test

```bash
cd exercises/ex4-ssl

# Start
docker-compose up -d

# Test HTTP redirect
curl -L http://localhost:8002/
# Should redirect to HTTPS

# Test HTTPS (ignore cert warning - self-signed)
curl -k https://localhost:8443/
# Output: HTTPS is working! 🔐

# View certificate details
echo | openssl s_client -connect localhost:8443 2>/dev/null | \
  openssl x509 -text -noout | head -20

# Check response headers
curl -k -I https://localhost:8443/
# Should show: Strict-Transport-Security header
```

### 🎯 What You Learned
- ✅ SSL/TLS certificate generation
- ✅ HTTPS configuration in Nginx
- ✅ HTTP → HTTPS redirect
- ✅ Security headers
- ✅ Certificate validation

### 🤔 Experiment Questions
1. Ubah SSL certificate domain. Apa yang berubah di curl output?
2. Hapus security headers. Apa that akan change security posture?
3. Ubah `ssl_protocols` ke `TLSv1`. Apa yang terjadi?

---

## Exercise 5: Full Stack - Multiple Services + SSL + Routing

### Goal
Menggabungkan semua konsep: Multiple services + Nginx routing + SSL.

### Step 1: Project Structure

```
exercises/ex5-fullstack/
├── docker-compose.yml
├── nginx.conf
├── certs/
│   ├── fullchain.pem
│   └── privkey.pem
├── app1/
│   └── Dockerfile
│   └── app.py
├── app2/
│   └── Dockerfile
│   └── app.py
└── NOTES.md
```

### Step 2: Create Two Backend Apps

File: `exercises/ex5-fullstack/app1/app.py`

```python
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return {'app': 'app1', 'message': 'This is App 1'}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

File: `exercises/ex5-fullstack/app2/app.py`

```python
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return {'app': 'app2', 'message': 'This is App 2'}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
```

### Step 3: Create Dockerfile

File: `exercises/ex5-fullstack/app1/Dockerfile` (copy to app2 too)

```dockerfile
FROM python:3.9-slim
WORKDIR /app
RUN pip install flask
COPY app.py .
CMD ["python", "app.py"]
```

### Step 4: Create docker-compose.yml

```yaml
version: '3.8'

services:
  nginx:
    image: nginx:latest
    ports:
      - "8003:80"
      - "8444:443"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - ./certs:/etc/nginx/certs:ro
    depends_on:
      - app1
      - app2
    networks:
      - backend-net
    restart: unless-stopped

  app1:
    build: ./app1
    networks:
      - backend-net
    restart: unless-stopped
    expose:
      - "5000"

  app2:
    build: ./app2
    networks:
      - backend-net
    restart: unless-stopped
    expose:
      - "5001"

networks:
  backend-net:
    driver: bridge
```

### Step 5: Create Advanced Nginx Config

```nginx
upstream app1 {
    server app1:5000;
}

upstream app2 {
    server app2:5001;
}

# HTTP Redirect
server {
    listen 80;
    return 301 https://$host$request_uri;
}

# HTTPS - Main page
server {
    listen 443 ssl http2;
    server_name localhost;
    
    ssl_certificate /etc/nginx/certs/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    
    location / {
        return 200 'Welcome to Full Stack App\n\n- /app1 → App 1\n- /app2 → App 2\n';
        add_header Content-Type text/plain;
    }
    
    location /app1 {
        proxy_pass http://app1/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    location /app2 {
        proxy_pass http://app2/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Step 6: Run & Test

```bash
cd exercises/ex5-fullstack

# Start (will build images)
docker-compose up -d

# Test
curl -k https://localhost:8444/
# Show welcome page

curl -k https://localhost:8444/app1
# Output: {"app": "app1", ...}

curl -k https://localhost:8444/app2
# Output: {"app": "app2", ...}

# View logs
docker-compose logs -f

# Cleanup
docker-compose down
```

### 🎯 What You Learned
- ✅ Multi-service architecture
- ✅ Container building (Dockerfile)
- ✅ Path-based routing
- ✅ SSL termination di Nginx
- ✅ Production-ready setup

### 🤔 Experiment Questions
1. Add /healthcheck endpoint di setiap app. Ubah Nginx untuk health check routing.
2. Add load balancing: `upstream app1 { server app1a:5000; server app1b:5000; }`
3. Configure rate limiting di Nginx untuk /app1 dan /app2 dengan limit berbeda.

---

## 📊 Exercise Summary

| Exercise | Concepts | Time |
|----------|----------|------|
| 1 | Container basics | 15 min |
| 2 | Web service + port mapping | 20 min |
| 3 | Networking + service discovery | 30 min |
| 4 | SSL/TLS certificates | 25 min |
| 5 | Full stack integration | 45 min |
| **Total** | **Complete infrastructure** | **2-3 hours** |

---

## 💡 Learning Tips

### For Each Exercise:

1. **Read** the code completely before running
2. **Understand** why each line is there
3. **Run** the setup
4. **Experiment** with changes
5. **Break** it intentionally (then fix)
6. **Document** what you learned in NOTES.md

### When Something Breaks:

1. **Check logs:** `docker-compose logs`
2. **Think:** What did you change?
3. **Understand:** Why would that cause error?
4. **Fix:** Apply understanding
5. **Test:** Verify fix works

### Keep Notes:

```markdown
# My Learning Notes

## Exercise 1: Basics
- Learned that containers are isolated processes
- Images are like templates, containers are instances
- Volumes persist data even after container stops

## Exercise 2: Web Services
- Port mapping: host:container means "route host port to container port"
- Read-only volumes: important untuk config files

## Exercise 3: Networking
- Docker DNS automatically resolves container names
- Services in same network can communicate by container name
- `expose` doesn't expose to host, only to network
```

---

## 🎓 After Exercises

Once you complete all exercises, you'll:

- ✅ Understand Docker from first principles
- ✅ Know how reverse proxy works
- ✅ Understand SSL/TLS
- ✅ Know Docker networking
- ✅ Can build custom infrastructure

Then you can:

1. **Customize** the production setup for your needs
2. **Troubleshoot** issues with understanding
3. **Add** new services dengan confidence
4. **Scale** the architecture
5. **Teach** others what you learned

---

## 📚 Additional Resources

### Docker Official
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Tutorial](https://docs.docker.com/compose/gettingstarted/)

### Nginx
- [Nginx Beginner Guide](https://nginx.org/en/docs/beginners_guide.html)
- [Nginx Reverse Proxy](https://nginx.org/en/docs/http/ngx_http_proxy_module.html)

### SSL/TLS
- [How HTTPS Works (Visual Guide)](https://howhttps.works/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)

---

## ✨ Final Notes

> "The best way to learn is by doing."

Jangan hanya membaca dokumentasi - **code it yourself**. Ketika Anda menulis config files dan debug errors, itulah pembelajaran yang sebenarnya terjadi.

Selamat belajar! 🚀

---

**Next Step:** After exercises → Try [QUICK_START.md](QUICK_START.md) to deploy real setup ke VPS!
