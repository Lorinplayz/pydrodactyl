#!/bin/bash

# Pyrodactyl Installer for ALL Ubuntu Versions
# Compatible with Ubuntu 16.04, 18.04, 20.04, 22.04, 24.04

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Function to print colored output
print_message() {
    echo -e "${2}${1}${NC}"
}

# Detect Ubuntu version
detect_ubuntu_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        UBUNTU_VERSION=$VERSION_ID
        UBUNTU_CODENAME=$UBUNTU_CODENAME
    else
        UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || echo "unknown")
    fi
    
    echo $UBUNTU_VERSION
}

# Clear screen
clear

# Banner
print_message "
  _      ____  _____  _____ _   _   _____  _           __     ________
 | |    / __ \|  __ \|_   _| \ | | |  __ \| |        /\\ \\   / /___  /
 | |   | |  | | |__) | | | |  \| | | |__) | |       /  \\ \\_/ /   / / 
 | |   | |  | |  _  /  | | | . \` | |  ___/| |      / /\ \\   /   / /  
 | |___| |__| | | \ \ _| |_| |\  | | |    | |____ / ____ \| |   / /__ 
 |______\____/|_|  \_\_____|_| \_| |_|    |______/_/    \_\_|  /_____|
" "${GREEN}"

print_message "            Pyrodactyl Installer - Lorinplayz.dev" "${YELLOW}"
print_message "            Compatible with Ubuntu 16.04 → 24.04" "${BLUE}"
echo ""

# Detect Ubuntu version
UBUNTU_VER=$(detect_ubuntu_version)
print_message "📋 Detected Ubuntu Version: ${GREEN}$UBUNTU_VER${NC}" "${NC}"

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    print_message "❌ Please do not run this script as root directly" "${RED}"
    print_message "   Run it as a normal user with sudo privileges" "${YELLOW}"
    exit 1
fi

# Step 1: Update system
print_message "[1/9] Updating system packages..." "${GREEN}"
sudo apt update -y
sudo apt upgrade -y

# Step 2: Install dependencies
print_message "[2/9] Installing dependencies..." "${GREEN}"
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    gnupg \
    lsb-release \
    wget \
    git \
    nano

# Step 3: Remove old Docker installations
print_message "[3/9] Removing old Docker installations..." "${GREEN}"
sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Step 4: Install Docker based on Ubuntu version
print_message "[4/9] Installing Docker for Ubuntu $UBUNTU_VER..." "${GREEN}"

# For Ubuntu 16.04, 18.04, 20.04 - Use stable repo
if [[ "$UBUNTU_VER" == "16.04" || "$UBUNTU_VER" == "18.04" || "$UBUNTU_VER" == "20.04" ]]; then
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add stable repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update and install Docker
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    
    # Install Docker Compose v1 for older versions
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    DOCKER_COMPOSE_CMD="docker-compose"
    
# For Ubuntu 22.04 and 24.04 - Use Docker Compose v2
elif [[ "$UBUNTU_VER" == "22.04" || "$UBUNTU_VER" == "24.04" ]]; then
    # Use official Docker install script
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    
    # Install Docker Compose plugin
    sudo apt install -y docker-compose-plugin
    DOCKER_COMPOSE_CMD="docker compose"
    
else
    # Unknown version - try generic method
    print_message "⚠️ Unknown Ubuntu version. Trying generic installation..." "${YELLOW}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo apt install -y docker-compose-plugin || sudo apt install -y docker-compose
    DOCKER_COMPOSE_CMD="docker compose"
fi

# Step 5: Start and enable Docker
print_message "[5/9] Starting Docker service..." "${GREEN}"
sudo systemctl start docker
sudo systemctl enable docker

# Step 6: Add user to docker group
print_message "[6/9] Adding user to docker group..." "${GREEN}"
sudo usermod -aG docker $USER

# Step 7: Create directory and download compose file
print_message "[7/9] Setting up Pyrodactyl panel..." "${GREEN}"
mkdir -p ~/pyrodactyl-panel
cd ~/pyrodactyl-panel

# Download appropriate compose file
if [[ "$UBUNTU_VER" == "16.04" || "$UBUNTU_VER" == "18.04" ]]; then
    # Use older compose file format for older Ubuntu
    curl -Lo docker-compose.yml https://raw.githubusercontent.com/pyrohost/pyrodactyl/main/docker-compose.example.yml
    # Convert to v3 format for older Docker
    sed -i 's/version: '"'"'3.8'"'"'/version: '"'"'3.3'"'"'/g' docker-compose.yml
else
    curl -Lo docker-compose.yml https://raw.githubusercontent.com/pyrohost/pyrodactyl/main/docker-compose.example.yml
fi

# Get server IP
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || echo "YOUR_SERVER_IP")

# Step 8: Configure
print_message "[8/9] Configuration Setup" "${YELLOW}"
print_message "=========================================" "${BLUE}"
print_message "Please change the following in docker-compose.yml:" "${YELLOW}"
print_message "  - APP_URL: Change to ${GREEN}http://$SERVER_IP${NC}" "${NC}"
print_message "  - DB_PASSWORD: Set a secure password" "${NC}"
print_message "  - REDIS_PASSWORD: Set a secure password" "${NC}"
print_message "=========================================" "${BLUE}"
echo ""

read -p "Do you want to edit the configuration file now? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    nano docker-compose.yml
fi

# Step 9: Start the panel
print_message "[9/9] Starting Pyrodactyl panel..." "${GREEN}"

# Start with appropriate command
if [[ "$DOCKER_COMPOSE_CMD" == "docker-compose" ]]; then
    sudo docker-compose up -d
    sleep 15
    sudo docker-compose exec panel php artisan p:user:make
    sudo docker-compose ps
else
    sudo docker compose up -d
    sleep 15
    sudo docker compose exec panel php artisan p:user:make
    sudo docker compose ps
fi

# Final instructions
print_message "" "${NC}"
print_message "══════════════════════════════════════════════" "${GREEN}"
print_message "✅ INSTALLATION COMPLETE!" "${GREEN}"
print_message "══════════════════════════════════════════════" "${GREEN}"
print_message "" "${NC}"
print_message "📱 Ubuntu Version: ${GREEN}$UBUNTU_VER${NC}" "${NC}"
print_message "📱 Panel URL: ${GREEN}http://$SERVER_IP:8080${NC}" "${NC}"
print_message "📱 Docker Command: ${GREEN}$DOCKER_COMPOSE_CMD${NC}" "${NC}"
print_message "" "${NC}"
print_message "📝 USEFUL COMMANDS:" "${BLUE}"
print_message "   cd ~/pyrodactyl-panel" "${NC}"
if [[ "$DOCKER_COMPOSE_CMD" == "docker-compose" ]]; then
    print_message "   sudo docker-compose ps              # Check status" "${NC}"
    print_message "   sudo docker-compose logs panel       # View logs" "${NC}"
else
    print_message "   sudo docker compose ps               # Check status" "${NC}"
    print_message "   sudo docker compose logs panel        # View logs" "${NC}"
fi
print_message "" "${NC}"
print_message "⚠️  IMPORTANT: Logout and login again for group changes to take effect!" "${YELLOW}"
print_message "    Run: ${GREEN}exit${NC} then SSH back in" "${NC}"
print_message "" "${NC}"
print_message "══════════════════════════════════════════════" "${GREEN}"
