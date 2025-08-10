#!/bin/bash
# Script de vérifications pré-migration réseau
# Suppression Router Huawei → Migration vers Netgear R7100LG

set -e

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Répertoires
BACKUP_DIR="$(dirname "$0")/../configs/backups"
LOG_FILE="${BACKUP_DIR}/pre-migration-$(date +%Y%m%d_%H%M%S).log"

echo -e "${BLUE}=== PRÉ-MIGRATION RÉSEAU - VÉRIFICATIONS ===${NC}"
echo "Log: $LOG_FILE"
echo

# Créer le répertoire de backup s'il n'existe pas
mkdir -p "$BACKUP_DIR"

# Fonction de logging
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# Fonction de vérification avec status
check_status() {
    if [ $? -eq 0 ]; then
        log "${GREEN}✓ $1${NC}"
    else
        log "${RED}✗ $1 - ÉCHEC${NC}"
        return 1
    fi
}

log "${YELLOW}1. Vérification de la connectivité actuelle${NC}"

# Test de connectivité Internet
log "Test connectivité Internet..."
ping -c 3 8.8.8.8 &> /dev/null
check_status "Connectivité Internet"

# Test résolution DNS
log "Test résolution DNS..."
nslookup google.com &> /dev/null
check_status "Résolution DNS"

# Identification de la configuration réseau actuelle
log "\n${YELLOW}2. Audit configuration réseau actuelle${NC}"

# Interface réseau active
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
log "Interface réseau principale: $INTERFACE"

# IP actuelle
CURRENT_IP=$(ip addr show "$INTERFACE" | grep "inet " | awk '{print $2}' | cut -d/ -f1)
log "IP actuelle: $CURRENT_IP"

# Passerelle actuelle  
CURRENT_GATEWAY=$(ip route | grep default | awk '{print $3}' | head -1)
log "Passerelle actuelle: $CURRENT_GATEWAY"

# DNS actuel
CURRENT_DNS=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | head -1)
log "DNS actuel: $CURRENT_DNS"

# Sauvegarder la configuration réseau actuelle
log "\n${YELLOW}3. Sauvegarde configuration réseau${NC}"

{
    echo "# Configuration réseau avant migration - $(date)"
    echo "INTERFACE=$INTERFACE"
    echo "CURRENT_IP=$CURRENT_IP"
    echo "CURRENT_GATEWAY=$CURRENT_GATEWAY" 
    echo "CURRENT_DNS=$CURRENT_DNS"
    echo
    echo "# Route table"
    ip route
    echo
    echo "# Interface details"
    ip addr show "$INTERFACE"
    echo
    echo "# DNS configuration"
    cat /etc/resolv.conf
} > "${BACKUP_DIR}/current-network-config.txt"

check_status "Sauvegarde configuration réseau"

log "\n${YELLOW}4. Vérification services critiques${NC}"

# Test PiHole (si sur cette machine)
if docker ps | grep -q pihole; then
    log "Test PiHole Docker..."
    docker exec $(docker ps -q -f name=pihole) nslookup google.com localhost &> /dev/null
    check_status "PiHole fonctionnel"
fi

# Test Nginx Proxy Manager
if docker ps | grep -q nginx-proxy-manager; then
    log "Test Nginx Proxy Manager..."
    curl -s -o /dev/null http://localhost:81
    check_status "Nginx Proxy Manager accessible"
fi

# Test Home Assistant (si accessible)
log "Test Home Assistant (RPI)..."
if ping -c 1 -W 2 "$CURRENT_GATEWAY" &> /dev/null; then
    # Essayer de détecter l'IP du RPI via arp ou scan réseau
    RPI_IP=$(arp -a | grep -i "b8:27:eb\|dc:a6:32" | awk '{print $2}' | tr -d '()')
    if [ ! -z "$RPI_IP" ]; then
        curl -s -o /dev/null --max-time 5 "http://$RPI_IP:8123" 
        check_status "Home Assistant accessible ($RPI_IP)"
    else
        log "${YELLOW}⚠ RPI IP non détectée automatiquement${NC}"
    fi
fi

log "\n${YELLOW}5. Vérifications de sécurité${NC}"

# Vérifier qu'aucun service critique n'écoute sur toutes les interfaces
log "Vérification exposition services..."
EXPOSED_SERVICES=$(netstat -tlnp 2>/dev/null | grep ":.*0.0.0.0:" | wc -l)
if [ "$EXPOSED_SERVICES" -gt 5 ]; then
    log "${YELLOW}⚠ $EXPOSED_SERVICES services exposés sur 0.0.0.0${NC}"
else
    log "${GREEN}✓ Nombre de services exposés acceptable${NC}"
fi

# Vérifier les règles iptables critiques  
if command -v iptables &> /dev/null; then
    IPTABLES_RULES=$(iptables -L | wc -l)
    log "Règles iptables: $IPTABLES_RULES"
fi

log "\n${YELLOW}6. Préparation fichiers migration${NC}"

# Générer le fichier de variables pour les scripts de migration
{
    echo "# Variables de migration générées automatiquement"
    echo "export CURRENT_INTERFACE=$INTERFACE"
    echo "export CURRENT_IP=$CURRENT_IP" 
    echo "export CURRENT_GATEWAY=$CURRENT_GATEWAY"
    echo "export TARGET_IP=10.0.0.101"
    echo "export TARGET_GATEWAY=10.0.0.1"
    echo "export TARGET_DNS=10.0.0.101"
    echo "export MIGRATION_DATE=$(date '+%Y-%m-%d %H:%M:%S')"
} > "${BACKUP_DIR}/migration-vars.sh"

check_status "Génération variables de migration"

log "\n${YELLOW}7. Vérification espace disque${NC}"
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 90 ]; then
    log "${RED}✗ Espace disque critique: $DISK_USAGE%${NC}"
else
    log "${GREEN}✓ Espace disque OK: $DISK_USAGE%${NC}"
fi

log "\n${BLUE}=== RÉSUMÉ PRÉ-MIGRATION ===${NC}"
log "Configuration actuelle sauvegardée dans: $BACKUP_DIR"
log "Interface: $INTERFACE"
log "IP actuelle: $CURRENT_IP → Target: 10.0.0.101" 
log "Passerelle: $CURRENT_GATEWAY → Target: 10.0.0.1"

if [ -f "${BACKUP_DIR}/migration-vars.sh" ]; then
    log "${GREEN}✓ Prêt pour la migration${NC}"
    echo
    log "${YELLOW}Prochaines étapes:${NC}"
    log "1. Configurer le routeur Netgear R7100LG"
    log "2. Exécuter le script de migration"
    log "3. Valider avec validate-migration.sh"
else
    log "${RED}✗ Préparation incomplète${NC}"
    exit 1
fi