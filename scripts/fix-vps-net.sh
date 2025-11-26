#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WG_CONF="$SCRIPT_DIR/../config/wg_confs/wg0.conf"
IFACE=$(ip route | grep default | awk '{print $5}' | head -n1)

echo "    [1/7] Detecting interface..."
echo "      -> Detected Interface: $IFACE"
echo "      -> Config Path: $WG_CONF"

# Install required packages
echo "    [2/7] Installing required packages for network fixes..."
sudo apt update -y -qq > /dev/null
sudo apt upgrade -y -qq > /dev/null
sudo apt install -y -qq iptables-persistent netfilter-persistent > /dev/null

# Kernel settings
echo "    [3/7] Configuring Kernel Forwarding..."
cat <<EOF | sudo tee /etc/sysctl.d/99-wireguard-optimize.conf > /dev/null
net.ipv4.ip_forward=1
net.ipv4.conf.all.src_valid_mark=1
EOF
sudo sysctl -p /etc/sysctl.d/99-wireguard-optimize.conf > /dev/null

# Fix MTU
echo "    [4/7] Checking MTU configuration..."
if [ -f "$WG_CONF" ]; then
    if grep -q "MTU =" "$WG_CONF"; then
        echo "      -> MTU was already configured."
    else
        echo "      -> Injecting MTU = 1420 into $WG_CONF..."
        sudo sed -i '/\[Interface\]/a MTU = 1420' $WG_CONF
    fi
else
    echo "      -> ERROR: $WG_CONF not found. Start the container first."
    echo "      -> Please start the Docker container ONCE to generate the config, run this script to apply the MTU setting."
    echo "      -> Also check path (is it wg0.conf or wg_confs/wg0.conf?)"
fi

# NAT (Masquerade) rules
echo "    [5/7] Applying Firewall rules..."
add_rule() {
    if ! sudo iptables -C "$@" 2>/dev/null; then
        sudo iptables -I "$@"
    fi
}

add_rule INPUT -i wg0 -j ACCEPT
add_rule FORWARD -i wg0 -j ACCEPT
add_rule FORWARD -o wg0 -j ACCEPT

if ! sudo iptables -t nat -C POSTROUTING -o $IFACE -j MASQUERADE 2>/dev/null; then
    sudo iptables -t nat -A POSTROUTING -o $IFACE -j MASQUERADE
    echo "      -> Added NAT Masquerade rule."
fi

# Rules persistently
echo "    [6/7] Saving firewall rules..."
sudo netfilter-persistent save > /dev/null

# Final configuration check
echo "    [7/7] Final network configuration check:"
bash "$SCRIPT_DIR/check-network-config.sh"
