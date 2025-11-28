#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}==============================================${NC}"
echo -e "${CYAN}   WIREGUARD HUB - AUTOMATED INSTALLER        ${NC}"
echo -e "${CYAN}==============================================${NC}"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."
COMPOSE_FILE="$PROJECT_ROOT/docker-compose.yml"
WG_CONFIG="$PROJECT_ROOT/config/wg_confs/wg0.conf" 
TIMEOUT=0

# Run base Docker installation
echo ""
echo -e "\n${YELLOW}>>> STEP 1: Installing Docker & System Deps...${NC}"
sudo bash "$SCRIPT_DIR/basic-install.sh"

# Detect and inject public IP
echo ""
echo -e "\n${YELLOW}>>> STEP 2: Configuring Public IP...${NC}"
PUBLIC_IP=$(curl -s ifconfig.me)
echo "    Detected IP: $PUBLIC_IP"

if [ -f "$COMPOSE_FILE" ]; then
    # Replaces the line containing SERVERURL=... with the real IP
    sed -i "s|SERVERURL=.*|SERVERURL=$PUBLIC_IP|g" "$COMPOSE_FILE"
    echo -e "    ${GREEN}IP injected into docker-compose.yml${NC}"
else
    echo -e "    ${RED}Error: docker-compose.yml not found!${NC}"
    exit 1
fi

# Start Docker (to generate configs)
echo ""
echo -e "\n${YELLOW}>>> STEP 3: Starting WireGuard (Generating Configs)...${NC}"
cd "$PROJECT_ROOT"
sudo docker compose up -d > /dev/null 2>&1

echo -n "    Waiting for config generation"
while [ ! -f "$WG_CONFIG" ]; do
    sleep 1
    echo -n "."
    TIMEOUT=$((TIMEOUT+1))
    if [ $TIMEOUT -gt 30 ]; then
        echo ""
        echo -e "    ${RED}Error: Timed out waiting for $WG_CONFIG${NC}"
        echo "    Check path (is it wg0.conf or wg_confs/wg0.conf?)"
        exit 1
    fi
done
echo ""
echo -e "    ${GREEN}File generated successfully!${NC}"

# Apply network fixes (MTU & iptables)
echo ""
echo -e "\n${YELLOW}>>> STEP 4: Applying Network Fixes (MTU & Firewall)...${NC}"
sudo bash "$SCRIPT_DIR/fix-vps-net.sh"

# Finalize and fix permissions
echo ""
echo -e "\n${YELLOW}>>> STEP 5: Finalizing...${NC}"
cd "$PROJECT_ROOT"
sudo docker compose restart > /dev/null 2>&1

# Return ownership of files to the real user (not root)
if [ -n "$SUDO_USER" ]; then
    echo "    Fixing file permissions for user: $SUDO_USER"
    sudo chown -R "$SUDO_USER:$SUDO_USER" "$PROJECT_ROOT/config"
fi

echo ""
echo -e "${GREEN}==============================================${NC}"
echo -e "${GREEN}           INSTALLATION COMPLETE!             ${NC}"
echo -e "${GREEN}==============================================${NC}"
echo ""
echo -e "${CYAN}IMPORTANT:${NC}"
echo -e "To use Docker without 'sudo' and fix terminal colors,"
echo -e "please log out and log back in. Run this:"
echo ""
echo -e "    ${YELLOW}exit${NC}"
echo ""
