#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

if [ -z "$REAL_USER" ]; then
    REAL_USER="${SUDO_USER:-$USER}"
    REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."
COMPOSE_FILE="$PROJECT_ROOT/docker-compose.yml"

# Basic system update and essential package installation
echo -e "    ${YELLOW}[1/6]${NC} Updating system and installing essential packages..."
sudo apt-get update -qq > /dev/null
sudo apt-get upgrade -y -qq > /dev/null
sudo apt-get install -y -qq apt-utils nano ca-certificates curl gnupg iputils-ping > /dev/null

# Basic configuration
echo -e "    ${YELLOW}[2/6]${NC} Configuring terminal for $REAL_USER..."
if ! grep -q "xterm-256color" "$REAL_HOME/.bashrc"; then
    echo 'export TERM=xterm-256color' >> "$REAL_HOME/.bashrc"
    chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.bashrc"
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
sudo apt-get update -y -qq > /dev/null
sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null

echo -e "    ${YELLOW}[5/6]${NC} Configuring Docker permissions for $REAL_USER..."
sudo usermod -aG docker "$REAL_USER"

echo -e "    ${YELLOW}[6/6]${NC} Verifying installation..."
if sg docker -c "docker run --rm hello-world" > /dev/null 2>&1; then
    echo -e "      ${GREEN}-> Docker is running correctly.${NC}"
else
    echo -e "      ${RED}-> Error: Docker verification failed.${NC}"
    exit 1
fi
