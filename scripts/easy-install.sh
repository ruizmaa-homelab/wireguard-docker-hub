#!/bin/bash
set -e

echo "=============================================="
echo "   WIREGUARD HUB - AUTOMATED INSTALLER        "
echo "=============================================="

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."
COMPOSE_FILE="$PROJECT_ROOT/docker-compose.yml"
WG_CONFIG="$PROJECT_ROOT/config/wg_confs/wg0.conf" 
TIMEOUT=0

# Run base Docker installation
echo ""
echo ">>> STEP 1: Installing Docker & System Deps..."
sudo bash "$SCRIPT_DIR/basic-install.sh"

# Detect and inject public IP
echo ""
echo ">>> STEP 2: Configuring Public IP..."
PUBLIC_IP=$(curl -s ifconfig.me)
echo "    Detected IP: $PUBLIC_IP"

if [ -f "$COMPOSE_FILE" ]; then
    # Replaces the line containing SERVERURL=... with the real IP
    sed -i "s|SERVERURL=.*|SERVERURL=$PUBLIC_IP|g" "$COMPOSE_FILE"
    echo "    IP injected into docker-compose.yml"
else
    echo "    Error: docker-compose.yml not found!"
    exit 1
fi

# Start Docker (to generate configs)
echo ""
echo ">>> STEP 3: Starting WireGuard and waiting to generate configs..."
cd "$PROJECT_ROOT"
sudo docker compose up -d

while [ ! -f "$WG_CONFIG" ]; do
    sleep 1
    ((TIMEOUT++))
    if [ $TIMEOUT -gt 30 ]; then
        echo "    Error: Timed out waiting for $WG_CONFIG"
        echo "    Check path (is it wg0.conf or wg_confs/wg0.conf?)"
        exit 1
    fi
done
echo "    File generated successfully!"

# Apply network fixes (MTU & iptables)
echo ""
echo ">>> STEP 4: Applying Network Fixes (MTU & Firewall)..."
sudo bash "$SCRIPT_DIR/fix-vps-net.sh"

# Finalize and fix permissions
echo ""
echo ">>> STEP 5: Finalizing..."
cd "$PROJECT_ROOT"
sudo docker compose restart

# Return ownership of files to the real user (not root)
if [ -n "$SUDO_USER" ]; then
    echo "    Fixing file permissions for user: $SUDO_USER"
    sudo chown -R "$SUDO_USER:$SUDO_USER" "$PROJECT_ROOT/config"
fi

echo ""
echo "=============================================="
echo "           INSTALLATION COMPLETE!"
echo "=============================================="
echo ""
