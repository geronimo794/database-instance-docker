#!/bin/bash

# ============================================
# FIREWALL SCRIPT - Ubuntu 24.04
# Supports: Docker, WireGuard (wg-easy), SSH
# ============================================

set -e

# ============================================
# CONFIGURATION - Edit these as needed
# ============================================
INTERNAL_NETS=("192.168.177.0/24" "10.0.0.0/8")
PUBLIC_IFACE="eth0"
WG_IFACE="wg0"
WG_SUBNET="192.168.177.0/24"
WG_PORT="51820"
SSH_PORT="22"
SSH_RATE_SECONDS=60
SSH_RATE_HITCOUNT=3

# ============================================
# FLUSH EXISTING RULES (preserve Docker chains)
# ============================================
echo "Flushing existing rules..."
sudo iptables -F INPUT
sudo iptables -F OUTPUT
sudo iptables -F FORWARD

# ============================================
# DEFAULT POLICIES
# ============================================
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT

# ============================================
# INPUT CHAIN
# ============================================

# Loopback
sudo iptables -A INPUT -i lo -j ACCEPT

# Established & related connections
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Drop invalid packets
sudo iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

# ICMP (ping)
sudo iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# Internal networks - full access
for NET in "${INTERNAL_NETS[@]}"; do
    sudo iptables -A INPUT -s "$NET" -j ACCEPT
done

# WireGuard interface - allow all traffic from connected clients
sudo iptables -A INPUT -i "$WG_IFACE" -j ACCEPT

# Public access - HTTP, HTTPS
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Public access - WireGuard UDP
sudo iptables -A INPUT -p udp --dport "$WG_PORT" -j ACCEPT

# Public access - SSH with rate limiting
sudo iptables -A INPUT -p tcp --dport "$SSH_PORT" -m conntrack --ctstate NEW -m recent --set --name sshbrute
sudo iptables -A INPUT -p tcp --dport "$SSH_PORT" -m conntrack --ctstate NEW -m recent --update --seconds "$SSH_RATE_SECONDS" --hitcount "$SSH_RATE_HITCOUNT" --name sshbrute -j DROP
sudo iptables -A INPUT -p tcp --dport "$SSH_PORT" -j ACCEPT

# ============================================
# FORWARD CHAIN
# ============================================

# Established & related (critical for Docker + WireGuard)
sudo iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Drop invalid packets
sudo iptables -A FORWARD -m conntrack --ctstate INVALID -j DROP

# Docker containers → internet
sudo iptables -A FORWARD -i docker0 -o "$PUBLIC_IFACE" -j ACCEPT

# Docker containers ↔ WireGuard
sudo iptables -A FORWARD -i docker0 -o "$WG_IFACE" -j ACCEPT
sudo iptables -A FORWARD -i "$WG_IFACE" -o docker0 -j ACCEPT

# WireGuard clients → internet (THIS WAS MISSING)
sudo iptables -A FORWARD -i "$WG_IFACE" -o "$PUBLIC_IFACE" -j ACCEPT

# WireGuard clients → internal Docker networks (br-* interfaces)
sudo iptables -A FORWARD -i "$WG_IFACE" -j ACCEPT

# ============================================
# NAT - Masquerade for WireGuard clients
# ============================================
# Check if masquerade rule already exists (wg-easy may set this)
if ! sudo iptables -t nat -C POSTROUTING -s "$WG_SUBNET" -o "$PUBLIC_IFACE" -j MASQUERADE 2>/dev/null; then
    echo "Adding NAT masquerade for WireGuard subnet..."
    sudo iptables -t nat -A POSTROUTING -s "$WG_SUBNET" -o "$PUBLIC_IFACE" -j MASQUERADE
fi

# ============================================
# DOCKER-USER CHAIN
# ============================================
if sudo iptables -L DOCKER-USER -n >/dev/null 2>&1; then
    echo "DOCKER-USER chain found, applying rules..."

    sudo iptables -F DOCKER-USER

    # Allow established & related
    sudo iptables -A DOCKER-USER -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

    # Internal networks → all Docker ports
    for NET in "${INTERNAL_NETS[@]}"; do
        sudo iptables -A DOCKER-USER -s "$NET" -j ACCEPT
    done

    # WireGuard traffic ↔ Docker (THIS WAS MISSING)
    sudo iptables -A DOCKER-USER -i "$WG_IFACE" -j ACCEPT
    sudo iptables -A DOCKER-USER -o "$WG_IFACE" -j ACCEPT

    # Docker internal communication
    sudo iptables -A DOCKER-USER -i docker0 -j ACCEPT
    sudo iptables -A DOCKER-USER -o docker0 -j ACCEPT

    # Allow Docker custom bridge networks (br-* interfaces from docker-compose)
    sudo iptables -A DOCKER-USER -i br-+ -j ACCEPT
    sudo iptables -A DOCKER-USER -o br-+ -j ACCEPT

    # Public access - only specific ports
    sudo iptables -A DOCKER-USER -i "$PUBLIC_IFACE" -p tcp --dport 80 -j ACCEPT
    sudo iptables -A DOCKER-USER -i "$PUBLIC_IFACE" -p tcp --dport 443 -j ACCEPT
    sudo iptables -A DOCKER-USER -i "$PUBLIC_IFACE" -p udp --dport "$WG_PORT" -j ACCEPT

    # Drop everything else from public
    sudo iptables -A DOCKER-USER -i "$PUBLIC_IFACE" -j DROP

    # Return for non-public traffic (don't block inter-container traffic)
    sudo iptables -A DOCKER-USER -j RETURN
else
    echo "WARNING: DOCKER-USER chain not found. Start Docker first!"
fi

# ============================================
# LOGGING - Dropped packets (rate limited)
# ============================================
sudo iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables-INPUT-dropped: " --log-level 4
sudo iptables -A FORWARD -m limit --limit 5/min -j LOG --log-prefix "iptables-FORWARD-dropped: " --log-level 4

# ============================================
# PERSIST RULES
# ============================================
sudo netfilter-persistent save

echo ""
echo "============================================"
echo "Firewall rules applied successfully!"
echo "============================================"
echo ""
echo "Internal networks: ${INTERNAL_NETS[*]} → FULL ACCESS"
echo "WireGuard clients: Internet access + Docker access"
echo "Public access: HTTP(80), HTTPS(443), WG($WG_PORT), SSH($SSH_PORT) rate-limited"
echo "Docker public: HTTP(80), HTTPS(443), WG($WG_PORT) only"
echo ""
echo "Verify with: sudo iptables -L -v -n --line-numbers"