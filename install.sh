#!/bin/bash

# Pyrodactyl Installer - GitHub Ready
# By Lorinplayz.dev

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo -e "${RED}❌ Please do not run this script as root directly${NC}"
    echo -e "${YELLOW}   Run it as a normal user with sudo privileges${NC}"
    exit 1
fi

# Clear screen
clear

# Banner
echo -e "${GREEN}"
echo "  _      ____  _____  _____ _   _   _____  _           __     ________"
echo " | |    / __ \|  __ \|_   _| \ | | |  __ \| |        /\\ \\   / /___  /"
echo " | |   | |  | | |__) | | | |  \| | | |__) | |       /  \\ \\_/ /   / / "
echo " | |   | |  | |  _  /  | | | . \` | |  ___/| |      / /\ \\   /   / /  "
echo " | |___| |__| | | \ \ _| |_| |\  | | |    | |____ / ____ \| |   / /__ "
echo " |______\____/|_|  \_\_____|_| \_| |_|    |______/_/    \_\_|  /_____|"
echo -e "${NC}"
echo -e "${YELLOW}            Pyrodactyl Installer - GitHub Edition${NC}"
echo -e "${BLUE}            Made By: Lorinplayz.dev${NC}"
echo ""

# Auto-fix function
fix_docker_issues() {
    echo -e "${YELLOW}🔧 Fixing Docker issues...${NC}"
    sudo systemctl stop docker 2>/dev/null
    sudo apt remove -y docker docker-engine docker.io containerd runc docker-ce docker-ce-cli containerd.io docker-compose-plugin 2>/dev/null
    sudo apt autoremove -y 2>/dev/null
    sudo rm -rf /var/lib/docker /etc/docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
}

# Auto-fix YAML function
fix_yaml() {
    echo -e "${YELLOW}🔧 Fixing YAML configuration...${NC}"
    cd ~/pyrodactyl-panel 2>/dev/null || mkdir -p ~/pyrodactyl-panel && cd ~/pyrodactyl-panel
    cat > docker-compose.yml << 'EOF'
version: '3.8'

x-common:
  &common
  image: ghcr.io/pyrodactyl-oss/pyrodactyl:latest
  networks:
    - pyrodactyl
  environment:
    APP_URL: "http://SERVER_IP_PLACEHOLDER"
    APP_TIMEZONE: "UTC"
    APP_ENVIRONMENT_ONLY: "false"
    DB_HOST: database
    DB_PORT: 3306
    DB_DATABASE: panel
    DB_USERNAME: pyrodactyl
    DB_PASSWORD: "SecurePass123!"
    CACHE_DRIVER: redis
    SESSION_DRIVER: redis
    QUEUE_CONNECTION: redis
    REDIS_HOST: cache
    REDIS_PASSWORD: "SecureRedis123!"
    REDIS_PORT: 6379

services:
  database:
    image: mariadb:10.11
    restart: always
    command: --default-authentication-plugin=mysql_native_password
    volumes:
      - /var/lib/pyrodactyl/database:/var/lib/mysql
    networks:
      - pyrodactyl
    environment:
      MYSQL_ROOT_PASSWORD: "RootPass123!"
      MYSQL_DATABASE: panel
      MYSQL_USER: pyrodactyl
      MYSQL_PASSWORD: "SecurePass123!"

  cache:
    image: redis:alpine
    restart: always
    command: redis-server --requirepass "SecureRedis123!"
    volumes:
      - /var/lib/pyrodactyl/redis:/data
    networks:
      - pyrodactyl

  panel:
    <<: *common
    restart: always
    ports:
      - "8080:80"
    volumes:
      - /var/lib/pyrodactyl/panel/var:/app/var
      - /var/lib/pyrodactyl/panel/logs:/app/storage/logs
      - /var/lib/pyrodactyl/panel/nginx:/etc/nginx/http.d
      - /var/lib/pyrodactyl/panel/ssl:/etc/letsencrypt
    depends_on:
      - database
      - cache

networks:
  pyrodactyl:
    driver: bridge
EOF
}

# Main installation
echo -e "${GREEN}[1/6] Updating system...${NC}"
sudo apt update -y

echo -e "${GREEN}[2/6] Installing Docker...${NC}"
if ! command -v docker &> /dev/null; then
    fix_docker_issues
else
    echo -e "${GREEN}✅ Docker already installed${NC}"
fi

echo -e "${GREEN}[3/6] Setting up Pyrodactyl...${NC}"
mkdir -p ~/pyrodactyl-panel
cd ~/pyrodactyl-panel

# Get server IP
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || echo "YOUR_SERVER_IP")

# Create YAML with proper IP
fix_yaml
sed -i "s|SERVER_IP_PLACEHOLDER|$SERVER_IP|g" docker-compose.yml

echo -e "${GREEN}[4/6] Starting containers...${NC}"
sudo docker compose up -d

if [ $? -ne 0 ]; then
    echo -e "${YELLOW}⚠️ First attempt failed, trying with sudo docker-compose...${NC}"
    sudo docker-compose up -d
fi

echo -e "${GREEN}[5/6] Waiting for database...${NC}"
sleep 15

echo -e "${GREEN}[6/6] Creating admin user...${NC}"
sudo docker compose exec panel php artisan p:user:make 2>/dev/null || sudo docker-compose exec panel php artisan p:user:make 2>/dev/null

# Final output
echo ""
echo -e "${GREEN}══════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ INSTALLATION COMPLETE!${NC}"
echo -e "${GREEN}══════════════════════════════════════════════${NC}"
echo -e "${CYAN}📱 Panel URL: ${GREEN}http://$SERVER_IP:8080${NC}"
echo -e "${CYAN}📱 Ubuntu Version: $(lsb_release -rs)${NC}"
echo ""
echo -e "${YELLOW}📝 Commands:${NC}"
echo -e "   cd ~/pyrodactyl-panel"
echo -e "   sudo docker compose ps"
echo -e "   sudo docker compose logs panel"
echo ""
echo -e "${PURPLE}Made with ❤️  By: Lorinplayz.dev${NC}"
echo -e "${BLUE}GitHub: https://github.com/lorinplayz/pyrodactyl-installer${NC}"
