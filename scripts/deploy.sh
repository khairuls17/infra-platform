#!/bin/bash

# VPS Auto Deployment Script
# Usage: bash deploy.sh <domain-name> <admin-password> <email>
# Example: bash deploy.sh example.com admin123 admin@example.com

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${GREEN}=== $1 ===${NC}"
}

print_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

print_success() {
    echo -e "${GREEN}[✓] $1${NC}"
}

# Validate inputs
if [ $# -lt 3 ]; then
    print_error "Usage: bash deploy.sh <domain> <admin-password> <email>"
    echo "Example: bash deploy.sh example.com admin123 admin@example.com"
    exit 1
fi

DOMAIN_NAME=$1
GF_ADMIN_PASSWORD=$2
LETSENCRYPT_EMAIL=$3

print_header "Infra Platform VPS Deployment"
echo "Domain: $DOMAIN_NAME"
echo "Email: $LETSENCRYPT_EMAIL"
echo ""

# Step 1: System Update
print_header "Step 1: System Update"
sudo apt update && sudo apt upgrade -y
print_success "System updated"

# Step 2: Install Docker
print_header "Step 2: Install Docker & Docker Compose"
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    newgrp docker
    print_success "Docker installed"
else
    print_warning "Docker already installed"
fi

if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    print_success "Docker Compose installed"
else
    print_warning "Docker Compose already installed"
fi

# Step 3: Setup Firewall
print_header "Step 3: Setup Firewall"
sudo apt install ufw -y
sudo ufw --force enable
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw status
print_success "Firewall configured"

# Step 4: Clone/Update Repository
print_header "Step 4: Clone Repository"
if [ ! -d /opt/infra-platform ]; then
    sudo git clone https://github.com/khairuls17/infra-platform.git /opt/infra-platform
    sudo chown -R $USER:$USER /opt/infra-platform
else
    cd /opt/infra-platform
    git pull origin main
fi
print_success "Repository ready"

cd /opt/infra-platform

# Step 5: Create .env file
print_header "Step 5: Create .env Configuration"
if [ ! -f .env ]; then
    cp .env.example .env
    print_success ".env created"
else
    print_warning ".env already exists, skipping creation"
fi

# Update .env values
sed -i "s/your-domain.com/$DOMAIN_NAME/g" .env
sed -i "s/your-email@example.com/$LETSENCRYPT_EMAIL/g" .env
sed -i "s/changeme-admin-password/$GF_ADMIN_PASSWORD/g" .env

print_success ".env configured"
cat .env

# Step 6: Certbot Setup
print_header "Step 6: Setup SSL Certificate (Certbot)"
sudo apt install certbot python3-certbot-dns-cloudflare -y

# Create Cloudflare credentials prompt
read -p "Enter Cloudflare API Token (or press enter to skip): " CF_API_TOKEN

if [ -n "$CF_API_TOKEN" ]; then
    mkdir -p ~/.secrets/certbot
    cat > ~/.secrets/certbot/cloudflare.ini << EOF
dns_cloudflare_api_token = $CF_API_TOKEN
EOF
    chmod 600 ~/.secrets/certbot/cloudflare.ini
    
    # Create certificate
    sudo certbot certonly \
        --dns-cloudflare \
        --dns-cloudflare-credentials ~/.secrets/certbot/cloudflare.ini \
        -d $DOMAIN_NAME \
        -d "*.$DOMAIN_NAME" \
        --email $LETSENCRYPT_EMAIL \
        --agree-tos \
        --non-interactive 2>&1 || print_warning "Certificate creation failed, continuing..."
    
    # Copy certificates
    mkdir -p certs
    sudo cp /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem certs/
    sudo cp /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem certs/
    sudo chown $USER:$USER certs/*
    print_success "SSL certificates configured"
else
    print_warning "Skipping Certbot setup - manually run certbot later"
    mkdir -p certs
fi

# Step 7: Prepare directories
print_header "Step 7: Prepare Directories"
mkdir -p monitoring/prometheus
mkdir -p proxy/nginx
mkdir -p uptime
mkdir -p scripts
print_success "Directories ready"

# Step 8: Deploy Docker Compose
print_header "Step 8: Deploy with Docker Compose"
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
sleep 10
docker-compose ps

print_success "Docker Compose deployed"

# Step 9: Verification
print_header "Step 9: Verification"
echo "Waiting for services to be ready..."
sleep 15

echo ""
echo "Service Status:"
docker-compose ps

echo ""
echo "Testing endpoints:"
echo "- Main: https://$DOMAIN_NAME"
echo "- Grafana: https://grafana.$DOMAIN_NAME"
echo "- Portainer: https://portainer.$DOMAIN_NAME"
echo "- Status: https://status.$DOMAIN_NAME"

echo ""
print_success "Deployment completed!"

echo ""
print_header "Next Steps"
echo "1. Wait 24-48 hours for DNS propagation"
echo "2. Check SSL certificate:"
echo "   sudo certbot certificates"
echo "3. Monitor containers:"
echo "   docker-compose logs -f"
echo "4. Access services and configure them"
echo "5. Setup Grafana datasource and dashboards"
echo "6. Configure Portainer"
echo "7. Add uptime monitoring services in Uptime Kuma"

echo ""
echo "Useful commands:"
echo "  docker-compose ps                          # Check container status"
echo "  docker-compose logs -f <service>           # View service logs"
echo "  docker-compose down                        # Stop services"
echo "  docker-compose up -d                       # Start services"
echo "  sudo certbot renew --dry-run                # Test certificate renewal"
