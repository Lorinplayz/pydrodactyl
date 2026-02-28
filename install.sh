#!/bin/bash

# Pyrodactyl Installer for Ubuntu 24.04
# Fixed and optimized version

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}"
echo "  _      ____  _____  _____ _   _   _____  _           __     ________"
echo " | |    / __ \|  __ \|_   _| \ | | |  __ \| |        /\\ \\   / /___  /"
echo " | |   | |  | | |__) | | | |  \| | | |__) | |       /  \\ \\_/ /   / / "
echo " | |   | |  | |  _  /  | | | . \` | |  ___/| |      / /\ \\   /   / /  "
echo " | |___| |__| | | \ \ _| |_| |\  | | |    | |____ / ____ \| |   / /__ "
echo " |______\____/|_|  \_\_____|_| \_| |_|    |______/_/    \_\_|  /_____|"
echo -e "${NC}"
echo -e "${YELLOW}Pyrodactyl Installer -  Optimized${NC}"
echo ""

# Step 1: Install Docker
echo -e "${GREEN}[1/7] Installing Docker...${NC}"
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Step 2: Start Docker
echo -e "${GREEN}[2/7] Starting Docker service...${NC}"
sudo systemctl start docker
sudo systemctl enable docker

# Step 3: Add user to docker group
echo -e "${GREEN}[3/7] Adding user to docker group...${NC}"
sudo usermod -aG docker $USER

# Step 4: Create directory and download compose file
echo -e "${GREEN}[4/7] Setting up Pyrodactyl panel...${NC}"
mkdir -p ~/pyrodactyl-panel
cd ~/pyrodactyl-panel
curl -Lo docker-compose.yml https://raw.githubusercontent.com/pyrohost/pyrodactyl/main/docker-compose.example.yml

# Step 5: Guide user to edit config
echo -e "${YELLOW}[5/7] IMPORTANT: Edit the configuration file${NC}"
echo -e "Please change the following in docker-compose.yml:"
echo -e "  - APP_URL: Change to ${YELLOW}http://$(curl -s ifconfig.me)${NC}"
echo -e "  - DB_PASSWORD: Set a secure password"
echo -e "  - REDIS_PASSWORD: Set a secure password"
echo ""
read -p "Press Enter after you've edited the file (nano will open)..."

# Open nano for editing
nano docker-compose.yml

# Step 6: Start the panel
echo -e "${GREEN}[6/7] Starting Pyrodactyl panel...${NC}"
# Apply group changes without logging out
newgrp docker << EOF
cd ~/pyrodactyl-panel
docker compose up -d
echo "Waiting 10 seconds for database to initialize..."
sleep 10
docker compose ps
EOF

# Step 7: Create admin user
echo -e "${GREEN}[7/7] Creating admin user...${NC}"
cd ~/pyrodactyl-panel
docker compose exec panel php artisan p:user:make

# Final instructions
echo ""
echo -e "${GREEN}✅ Installation complete!${NC}"
echo -e "Your panel is running at: ${YELLOW}http://$(curl -s ifconfig.me):8080${NC}"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo "  cd ~/pyrodactyl-panel"
echo "  docker compose ps              # Check status"
echo "  docker compose logs panel       # View logs"
echo "  docker compose restart           # Restart panel"
echo "  docker compose down              # Stop panel"
echo ""
echo -e "${RED}If you get permission errors, logout and login again, then run:${NC}"
echo "  cd ~/pyrodactyl-panel && docker compose exec panel php artisan p:user:make"
