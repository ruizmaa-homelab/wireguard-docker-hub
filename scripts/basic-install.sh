#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."
COMPOSE_FILE="$PROJECT_ROOT/docker-compose.yml"

# Basic system update and essential package installation
echo "[1/6] Updating system and installing essential packages..."
sudo apt update -y
sudo apt upgrade -y
sudo apt install nano ca-certificates curl gnupg -y

# Basic configuration
echo "[2/6] Configuring terminal..."
if ! grep -q "xterm-256color" ~/.bashrc; then
    echo 'export TERM=xterm-256color' >> ~/.bashrc
fi

# Install Docker
echo "[3/6] Setting up Docker repository..."

. /etc/os-release
echo "    Detected Distro: $ID"
echo "    Detected Codename: $VERSION_CODENAME"

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/$ID/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/$ID
Suites: $VERSION_CODENAME
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

echo "[4/6] Installing Docker Engine..."
sudo apt update -y
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

echo "[5/6] Configuring docker user permissions..."
sudo usermod -aG docker $USER

echo "[6/6] Verifying Docker installation..."
if sg docker -c "docker run --rm hello-world"; then
    echo "Docker installed and verified successfully."
else
    echo "Docker installation verification failed. Please check the installation."
    exit 1
fi
