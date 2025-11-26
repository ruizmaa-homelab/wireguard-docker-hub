#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WG_CONF="$SCRIPT_DIR/../config/wg_confs/wg0.conf"
IFACE=$(ip route | grep default | awk '{print $5}' | head -n1)

# Check kernel
echo -n "    Kernel IP Forwarding:             "
if [ "$(sysctl -n net.ipv4.ip_forward)" -eq 1 ]; then echo "ACTIVE"; else echo "ERROR"; fi
echo -n "    Kernel Valid Mark:                "
if [ "$(sysctl -n net.ipv4.conf.all.src_valid_mark)" -eq 1 ]; then echo "ACTIVE"; else echo "ERROR"; fi

# Check MTU in file
echo -n "    MTU Configuration (1420):         "
if [ -f "$WG_CONF" ]; then
    if grep -q "MTU = 1420" "$WG_CONF"; then 
        echo "OK"
    else 
        echo "MISSING (MTU not set)"
    fi
else
    echo "ERROR (File not found)"
fi

# Check iptables rules (firewall)
echo -n "    Firewall - NAT Rule (Masquerade): "
if sudo iptables -t nat -C POSTROUTING -o $IFACE -j MASQUERADE 2>/dev/null; then echo "APPLIED"; else echo "ERROR"; fi

echo -n "    Firewall - Input Rule WireGuard:  "
if sudo iptables -C INPUT -i wg0 -j ACCEPT 2>/dev/null; then echo "APPLIED"; else echo "ERROR"; fi
