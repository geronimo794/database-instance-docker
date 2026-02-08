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

# Allow ICMP (ping)
sudo iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# SSH - HANYA dari internal network dengan rate limiting
sudo iptables -A INPUT -s 192.168.177.0/24 -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --set
sudo iptables -A INPUT -s 192.168.177.0/24 -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 4 -j DROP
sudo iptables -A INPUT -s 192.168.177.0/24 -p tcp --dport 22 -j ACCEPT

# HTTP & HTTPS - public access
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# SSH - public access (HATI-HATI!)
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# WireGuard - UDP 51820
sudo iptables -A INPUT -p udp --dport 51820 -j ACCEPT

# ============================================
# Docker rules - HANYA jika Docker running
# ============================================

# Check if DOCKER-USER chain exists
if sudo iptables -L DOCKER-USER -n >/dev/null 2>&1; then
    echo "DOCKER-USER chain found, applying rules..."
    
    # Flush DOCKER-USER chain first
    sudo iptables -F DOCKER-USER
    
    # Docker rules
    sudo iptables -A DOCKER-USER -i eth0 -p tcp --dport 80 -j ACCEPT
    sudo iptables -A DOCKER-USER -i eth0 -p tcp --dport 443 -j ACCEPT
    sudo iptables -A DOCKER-USER -i eth0 -p udp --dport 51820 -j ACCEPT
    sudo iptables -A DOCKER-USER -i eth0 -s 192.168.177.0/24 -p tcp --dport 22 -j ACCEPT
    
    # Allow Docker internal
    sudo iptables -A DOCKER-USER -i docker0 -j ACCEPT
    sudo iptables -A DOCKER-USER -o docker0 -j ACCEPT
    
    # Drop everything else
    sudo iptables -A DOCKER-USER -j DROP
else
    echo "WARNING: DOCKER-USER chain not found. Start Docker first!"
fi

# Log dropped packets
sudo iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables-INPUT-dropped: " --log-level 4

# Make rules persistent
sudo netfilter-persistent save

echo "Firewall rules applied successfully!"