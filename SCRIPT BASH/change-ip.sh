#!/bin/bash

# Script de modification IP fixe - Simple et direct
# Usage: ./set-ip.sh

set -e

echo "==============================="
echo "  Modification IP Interface"
echo "==============================="

# Fonction de validation IP
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        IFS='.' read -r -a octets <<< "$ip"
        for octet in "${octets[@]}"; do
            if ((octet < 0 || octet > 255)); then
                return 1
            fi
        done
        return 0
    else
        return 1
    fi
}

# Affichage des interfaces disponibles
echo "🔍 Interfaces réseau disponibles:"
ip link show | grep -E "^[0-9]+" | awk '{print "   " $2}' | sed 's/://'
echo

# Demande de l'interface
while true; do
    read -p "📝 Interface à configurer: " INTERFACE
    
    if ip link show "$INTERFACE" &>/dev/null; then
        echo "✓ Interface valide: $INTERFACE"
        break
    else
        echo "❌ Interface inexistante. Réessayez."
    fi
done

# Demande de l'IP
while true; do
    read -p "📝 Nouvelle adresse IP: " NEW_IP
    
    if validate_ip "$NEW_IP"; then
        echo "✓ Adresse IP valide: $NEW_IP"
        break
    else
        echo "❌ Adresse IP invalide. Format: 192.168.1.50"
    fi
done

# Récupération des paramètres réseau actuels
CURRENT_GATEWAY=$(ip route | grep default | awk '{print $3}' | head -1)
CURRENT_DNS=$(grep "nameserver" /etc/resolv.conf | head -2 | awk '{print $2}' | tr '\n' ',' | sed 's/,$//')

if [ -z "$CURRENT_DNS" ]; then
    CURRENT_DNS="8.8.8.8,1.1.1.1"
fi

echo
echo "📋 Configuration à appliquer:"
echo "   Interface: $INTERFACE"
echo "   Nouvelle IP: $NEW_IP/24"
echo "   Gateway: $CURRENT_GATEWAY (conservée)"
echo "   DNS: $CURRENT_DNS (conservés)"
echo

read -p "❓ Continuer? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Opération annulée"
    exit 0
fi

# Sauvegarde
if [ -f /etc/netplan/01-netcfg.yaml ]; then
    sudo cp /etc/netplan/01-netcfg.yaml "/etc/netplan/01-netcfg.yaml.backup_$(date +%s)"
    echo "✓ Sauvegarde créée"
fi

# Création configuration netplan
echo "⚙️  Application de la nouvelle IP..."

DNS_ARRAY=$(echo $CURRENT_DNS | sed 's/,/, /g')

sudo tee /etc/netplan/01-netcfg.yaml > /dev/null <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    $INTERFACE:
      dhcp4: false
      dhcp6: false
      addresses:
        - $NEW_IP/24
      routes:
        - to: default
          via: $CURRENT_GATEWAY
      nameservers:
        addresses: [$DNS_ARRAY]
EOF

# Permissions et nettoyage
sudo chmod 600 /etc/netplan/01-netcfg.yaml

# Désactivation cloud-init réseau (empêche DHCP au redémarrage)
echo "🔒 Désactivation cloud-init réseau..."
sudo mkdir -p /etc/cloud/cloud.cfg.d/
sudo tee /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg > /dev/null <<EOF
network: {config: disabled}
EOF

# Configuration systemd-networkd explicite (priorité absolue)
echo "🔒 Création configuration systemd-networkd prioritaire..."
sudo mkdir -p /etc/systemd/network/
sudo tee /etc/systemd/network/00-${INTERFACE}.network > /dev/null <<EOF
[Match]
Name=$INTERFACE

[Network]
DHCP=no
Address=$NEW_IP/24
Gateway=$CURRENT_GATEWAY
DNS=$DNS_ARRAY
EOF

# Nettoyage DHCP
sudo pkill dhclient 2>/dev/null || true
sudo rm -f /var/lib/dhcp/dhclient.*.leases 2>/dev/null || true

# Application
sudo systemctl restart systemd-networkd
sudo netplan apply
sleep 3

# Suppression anciennes IPs (après application netplan)
echo "🧹 Nettoyage des anciennes IPs..."
ALL_IPS=$(ip addr show $INTERFACE | grep "inet " | awk '{print $2}' | grep -v "127.0.0.1")
for ip_with_mask in $ALL_IPS; do
    OLD_IP=$(echo $ip_with_mask | cut -d'/' -f1)
    if [ "$OLD_IP" != "$NEW_IP" ]; then
        echo "  Suppression: $OLD_IP/24"
        sudo ip addr del $OLD_IP/24 dev $INTERFACE 2>/dev/null || true
    fi
done

# Vérification
FINAL_IP=$(ip addr show $INTERFACE | grep "inet " | awk '{print $2}' | head -1 | cut -d'/' -f1)

if [ "$FINAL_IP" = "$NEW_IP" ]; then
    echo
    echo "🎉 =========================="
    echo "   MODIFICATION RÉUSSIE !"
    echo "=========================="
    echo "✓ Interface: $INTERFACE"
    echo "✓ Nouvelle IP: $FINAL_IP"
    echo
else
    echo
    echo "❌ Erreur lors de l'application"
    echo "IP actuelle: $FINAL_IP"
    exit 1
fi