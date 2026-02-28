#!/bin/bash

# Pyrodactyl Installer for Ubuntu 24.04
# Fixed version with all error handling

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_message() {
    echo -e "${2}${1}${NC}"
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

print_message "            Pyrodactyl Installer - Ubuntu 204 Edition" "${YELLOW}"
print_message "            Fixed Version - Compatible with all errors" "${BLUE}"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    print_message "❌ Please do not run this script as root directly" "${RED}"
    print_message "   Run it as a normal user with sudo privileges" "${YELLOW}"
    exit 1
fi

# Step 1: Update system
print_message "[1/9] Updating system packages..." "${GREEN}"
sudo apt update -y

# Step 2: Remove old Docker installations
print_message "[2/9] Removing old Docker installations..." "${GREEN}"
sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Step 3: Install Docker
print_message "[3/9] Installing Docker..." "${GREEN}"
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Step 4: Install Docker Compose Plugin
print_message "[4/9] Installing Docker Compose plugin..." "${GREEN}"
sudo apt install -y docker-compose-plugin

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

# Download compose file
curl -Lo docker-compose.yml https://raw.githubusercontent.com/pyrohost/pyrodactyl/main/docker-compose.example.yml

# Get server IP
SERVER_IP=$(curl -s ifconfig.me)

# Step 8: Guide user to edit config
print_message "[8/9] Configuration Setup" "${YELLOW}"
print_message "=========================================" "${BLUE}"
print_message "Please change the following in docker-compose.yml:" "${YELLOW}"
print_message "  - APP_URL: Change to ${GREEN}http://$SERVER_IP${NC}" "${NC}"
print_message "  - DB_PASSWORD: Set a secure password" "${NC}"
print_message "  - REDIS_PASSWORD: Set a secure password" "${NC}"
print_message "=========================================" "${BLUE}"
echo ""

# Ask user if they want to edit now
read -p "Do you want to edit the configuration file now? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Check if nano is installed
    if ! command -v nano &> /dev/null; then
        sudo apt install -y nano
    fi
    nano docker-compose.yml
else
    print_message "You can edit it later with: nano ~/pyrodactyl-panel/docker-compose.yml" "${YELLOW}"
fi

# Step 9: Start the panel
print_message "[9/9] Starting Pyrodactyl panel..." "${GREEN}"

# Try with sudo first (most reliable method)
print_message "Starting with sudo (most reliable)..." "${BLUE}"
cd ~/pyrodactyl-panel

# Check if docker-compose.yml exists
if [ ! -f docker-compose.yml ]; then
    print_message "❌ docker-compose.yml not found!" "${RED}"
    exit 1
fi

# Start containers with sudo
sudo docker compose up -d

if [ $? -eq 0 ]; then
    print_message "✅ Panel started successfully with sudo!" "${GREEN}"
    
    # Wait for database
    print_message "Waiting 15 seconds for database to initialize..." "${YELLOW}"
    sleep 15
    
    # Create admin user
    print_message "Creating admin user..." "${GREEN}"
    sudo docker compose exec panel php artisan p:user:make
    
    # Show status
    print_message "Panel status:" "${BLUE}"
    sudo docker compose ps
else
    print_message "❌ Failed to start with sudo. Trying without sudo..." "${YELLOW}"
    
    # Try without sudo
    docker compose up -d
    
    if [ $? -eq 0 ]; then
        print_message "✅ Panel started successfully!" "${GREEN}"
        
        # Wait for database
        print_message "Waiting 15 seconds for database to initialize..." "${YELLOW}"
        sleep 15
        
        # Create admin user
        print_message "Creating admin user..." "${GREEN}"
        docker compose exec panel php artisan p:user:make
        
        # Show status
        print_message "Panel status:" "${BLUE}"
        docker compose ps
    else
        print_message "❌ Failed to start panel." "${RED}"
        print_message "Trying one more method with full paths..." "${YELLOW}"
        
        # Try with docker-compose (hyphen) instead of docker compose
        sudo docker-compose up -d 2>/dev/null || docker-compose up -d 2>/dev/null
        
        if [ $? -eq 0 ]; then
            print_message "✅ Panel started with docker-compose!" "${GREEN}"
            sleep 15
            sudo docker-compose exec panel php artisan p:user:make 2>/dev/null || docker-compose exec panel php artisan p:user:make
        else
            print_message "❌ All methods failed. Please check Docker installation." "${RED}"
            exit 1
        fi
    fi
fi

# Final instructions
print_message "" "${NC}"
print_message "══════════════════════════════════════════════" "${GREEN}"
print_message "✅ INSTALLATION COMPLETE!" "${GREEN}"
print_message "══════════════════════════════════════════════" "${GREEN}"
print_message "" "${NC}"
print_message "📱 Your panel is running at: ${GREEN}http://$SERVER_IP:8080${NC}" "${NC}"
print_message "" "${NC}"
print_message "📝 USEFUL COMMANDS:" "${BLUE}"
print_message "   cd ~/pyrodactyl-panel" "${NC}"
print_message "   sudo docker compose ps              # Check status" "${NC}"
print_message "   sudo docker compose logs panel       # View logs" "${NC}"
print_message "   sudo docker compose restart          # Restart panel" "${NC}"
print_message "   sudo docker compose down             # Stop panel" "${NC}"
print_message "" "${NC}"
print_message "⚠️  IF YOU GET PERMISSION ERRORS:" "${YELLOW}"
print_message "   Option 1: Logout and login again, then use commands WITHOUT sudo" "${NC}"
print_message "   Option 2: Continue using sudo with all docker commands" "${NC}"
print_message "   Option 3: Reboot the server: sudo reboot" "${NC}"
print_message "" "${NC}"
print_message "🔧 To create another admin user later:" "${BLUE}"
print_message "   cd ~/pyrodactyl-panel && sudo docker compose exec panel php artisan p:user:make" "${NC}"
print_message "" "${NC}"
print_message "══════════════════════════════════════════════" "${GREEN}"
