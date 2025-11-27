#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."
COMPOSE_FILE="$PROJECT_ROOT/docker-compose.yml"

# Basic system update and essential package installation
echo -e "    ${YELLOW}[1/6]${NC} Updating system and installing essential packages..."
sudo apt update -qq > /dev/null
sudo apt upgrade -y -qq > /dev/null
sudo apt install -y -qq nano ca-certificates curl gnupg > /dev/null

# Basic configuration
echo -e "    ${YELLOW}[2/6]${NC} Configuring terminal..."
if ! grep -q "xterm-256color" ~/.bashrc; then
    echo 'export TERM=xterm-256color' >> ~/.bashrc
fi

# Install Docker
echo -e "    ${YELLOW}[3/6]${NC} Setting up Docker repository..."
. /etc/os-release
echo "      -> Detected Distro: $ID"
echo "      -> Detected Codename: $VERSION_CODENAME"

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/$ID/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/$ID
Suites: $VERSION_CODENAME
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

echo -e "    ${YELLOW}[4/6]${NC} Installing Docker Engine..."
sudo apt update -y -qq > /dev/null
sudo apt install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null

echo -e "    ${YELLOW}[5/6]${NC} Configuring permissions..."
sudo usermod -aG docker $USER

echo -e "    ${YELLOW}[6/6]${NC} Verifying installation..."
if sg docker -c "docker run --rm hello-world" > /dev/null 2>&1; then
    echo -e "      ${GREEN}-> Docker is running correctly.${NC}"
else
    echo -e "      ${RED}-> Error: Docker verification failed.${NC}"
    exit 1
fi
