#!/bin/bash

# Flush existing rules (EXCEPT Docker chains)
sudo iptables -F INPUT
sudo iptables -F OUTPUT
sudo iptables -F FORWARD
# JANGAN flush DOCKER chains!

# Default policies
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT

# Allow loopback
sudo iptables -A INPUT -i lo -j ACCEPT

# Allow established & related
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT  # ✅ PENTING untuk Docker

# Allow ICMP (ping)
sudo iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# ============================================
# INTERNAL NETWORK - Full Access
# ============================================
# Allow ALL traffic from internal network 192.168.177.0/24
sudo iptables -A INPUT -s 192.168.177.0/24 -j ACCEPT

# ============================================
# PUBLIC ACCESS - Restricted
# ============================================
# HTTP & HTTPS - public access
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# WireGuard - UDP 51820
sudo iptables -A INPUT -p udp --dport 51820 -j ACCEPT

# SSH public access dengan rate limiting ketat
sudo iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --set
sudo iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 3 -j DROP
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# ============================================
# DOCKER INTERNET ACCESS
# ============================================
# Allow Docker containers to access internet
sudo iptables -A FORWARD -i docker0 -o eth0 -j ACCEPT
sudo iptables -A FORWARD -i docker0 -o wg0 -j ACCEPT  # Jika pakai WireGuard
# Response dari internet ke Docker sudah di-handle oleh ESTABLISHED,RELATED di atas

# ============================================
# Docker rules - HANYA jika Docker running
# ============================================

# Check if DOCKER-USER chain exists
if sudo iptables -L DOCKER-USER -n >/dev/null 2>&1; then
    echo "DOCKER-USER chain found, applying rules..."
    
    # Flush DOCKER-USER chain first
    sudo iptables -F DOCKER-USER
    
    # Allow ALL traffic from internal network to Docker containers
    sudo iptables -A DOCKER-USER -s 192.168.177.0/24 -j ACCEPT
    
    # Public access - hanya HTTP, HTTPS, WireGuard
    sudo iptables -A DOCKER-USER -i eth0 -p tcp --dport 80 -j ACCEPT
    sudo iptables -A DOCKER-USER -i eth0 -p tcp --dport 443 -j ACCEPT
    sudo iptables -A DOCKER-USER -i eth0 -p udp --dport 51820 -j ACCEPT
    
    # Allow Docker internal communication
    sudo iptables -A DOCKER-USER -i docker0 -j ACCEPT
    sudo iptables -A DOCKER-USER -o docker0 -j ACCEPT
    
    # Drop everything else
    sudo iptables -A DOCKER-USER -j DROP
else
    echo "WARNING: DOCKER-USER chain not found. Start Docker first!"
fi

# Log dropped packets (limited to avoid log flooding)
sudo iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables-INPUT-dropped: " --log-level 4
sudo iptables -A FORWARD -m limit --limit 5/min -j LOG --log-prefix "iptables-FORWARD-dropped: " --log-level 4

# Make rules persistent
sudo netfilter-persistent save

echo "Firewall rules applied successfully!"
echo ""
echo "Summary:"
echo "- Internal network (192.168.177.0/24): FULL ACCESS to all ports"
echo "- Public access: HTTP (80), HTTPS (443), WireGuard (51820), SSH (22) with rate limiting"
echo "- Docker containers: Full internet access + internal network access"
echo "- Docker public access: Limited to HTTP/HTTPS/WireGuard"