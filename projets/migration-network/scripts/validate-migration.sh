#!/bin/bash
# Script de validation post-migration réseau
# Vérification que la migration Huawei → Netgear s'est bien passée

set -e

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Répertoires
SCRIPT_DIR="$(dirname "$0")"
BACKUP_DIR="$SCRIPT_DIR/../configs/backups"
LOG_FILE="${BACKUP_DIR}/validation-$(date +%Y%m%d_%H%M%S).log"

echo -e "${BLUE}=== VALIDATION POST-MIGRATION RÉSEAU ===${NC}"
echo "Log: $LOG_FILE"
echo

# Créer le répertoire de log s'il n'existe pas
mkdir -p "$BACKUP_DIR"

# Charger les variables de migration si disponibles
if [ -f "$BACKUP_DIR/migration-vars.sh" ]; then
    source "$BACKUP_DIR/migration-vars.sh"
fi

# Fonction de logging
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# Fonction de test avec compteur
TESTS_PASSED=0
TESTS_TOTAL=0

test_check() {
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    if [ $? -eq 0 ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        log "${GREEN}✓ $1${NC}"
        return 0
    else
        log "${RED}✗ $1 - ÉCHEC${NC}"
        return 1
    fi
}

log "${YELLOW}1. Vérification configuration réseau de base${NC}"

# Interface réseau active
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
log "Interface réseau: $INTERFACE"

# IP actuelle
CURRENT_IP=$(ip addr show "$INTERFACE" | grep "inet " | awk '{print $2}' | cut -d/ -f1)
log "IP actuelle: $CURRENT_IP"

# Vérifier que l'IP est dans la bonne plage (10.0.0.x)
echo "$CURRENT_IP" | grep -q "^10\.0\.0\."
test_check "IP dans la plage cible (10.0.0.x)"

# Passerelle
CURRENT_GATEWAY=$(ip route | grep default | awk '{print $3}' | head -1)
log "Passerelle: $CURRENT_GATEWAY"

# Vérifier passerelle Netgear
[ "$CURRENT_GATEWAY" = "10.0.0.1" ]
test_check "Passerelle Netgear (10.0.0.1)"

log "\n${YELLOW}2. Tests de connectivité réseau${NC}"

# Test ping passerelle (Netgear)
ping -c 3 -W 2 10.0.0.1 &> /dev/null
test_check "Ping routeur Netgear (10.0.0.1)"

# Test ping Internet
ping -c 3 -W 5 8.8.8.8 &> /dev/null
test_check "Connectivité Internet"

# Test résolution DNS externe
nslookup google.com &> /dev/null
test_check "Résolution DNS externe"

log "\n${YELLOW}3. Tests de connectivité inter-machines${NC}"

# Test ping RPI (si IP connue)
RPI_IP="10.0.0.100"
ping -c 2 -W 3 "$RPI_IP" &> /dev/null
if test_check "Ping RPI ($RPI_IP)"; then
    # Test Home Assistant sur RPI
    curl -s -o /dev/null --max-time 5 "http://$RPI_IP:8123" 
    test_check "Home Assistant accessible"
fi

log "\n${YELLOW}4. Tests services Docker${NC}"

# Vérifier que Docker fonctionne
docker ps &> /dev/null
test_check "Docker daemon fonctionnel"

# Test PiHole
if docker ps | grep -q pihole; then
    log "Test PiHole..."
    docker exec $(docker ps -q -f name=pihole) nslookup google.com localhost &> /dev/null
    test_check "PiHole résolution DNS"
    
    # Test PiHole admin via NPM
    curl -s -o /dev/null --max-time 5 "http://localhost/admin"
    test_check "PiHole Admin via NPM"
fi

# Test Nginx Proxy Manager
if docker ps | grep -q nginx-proxy-manager; then
    curl -s -o /dev/null --max-time 5 "http://localhost:81"
    test_check "NPM interface admin"
    
    curl -s -o /dev/null --max-time 5 "http://localhost"
    test_check "NPM proxy HTTP"
fi

log "\n${YELLOW}5. Tests résolution DNS locale${NC}"

# Test résolution domaines locaux via PiHole
DNS_SERVER="10.0.0.101"

# Tester quelques domaines configurés
DOMAINS=("vault.homelab.local" "auth.homelab.local" "homeassistant.local")

for domain in "${DOMAINS[@]}"; do
    nslookup "$domain" "$DNS_SERVER" &> /dev/null
    test_check "Résolution $domain"
done

log "\n${YELLOW}6. Tests services web externes${NC}"

# Test accès aux services via domaines (si configurés)
# Note: Ces tests peuvent échouer si les certificats ne sont pas encore configurés

WEB_SERVICES=(
    "http://vault.homelab.local"
    "http://auth.homelab.local"  
    "http://pi.homelab.local"
)

for service in "${WEB_SERVICES[@]}"; do
    # Test avec curl, ignorer les erreurs SSL pour les domaines locaux
    curl -s -o /dev/null --max-time 5 -k "$service" 2>/dev/null || true
    # Ne pas faire échouer la validation sur ces tests car ils dépendent de la config SSL
    log "${BLUE}ℹ Test accès $service (informatif)${NC}"
done

log "\n${YELLOW}7. Vérification port forwarding${NC}"

# Test que les ports 80/443 sont bien forwardés (test externe nécessiterait IP publique)
# On vérifie juste que NPM écoute sur ces ports localement

netstat -tlnp 2>/dev/null | grep -q ":80 "
test_check "Port 80 en écoute locale"

netstat -tlnp 2>/dev/null | grep -q ":443 "
test_check "Port 443 en écoute locale"

log "\n${YELLOW}8. Vérification sécurité réseau${NC}"

# Vérifier que le SSH n'est pas exposé publiquement (ne devrait pas être forwardé)
# C'est un test de sécurité positif

if ! netstat -tlnp 2>/dev/null | grep -q "0.0.0.0:22 "; then
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    log "${GREEN}✓ SSH non exposé publiquement${NC}"
else
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    log "${YELLOW}⚠ SSH exposé sur 0.0.0.0:22 - Vérifier config${NC}"
fi

log "\n${YELLOW}9. Sauvegarde configuration finale${NC}"

# Sauvegarder la nouvelle configuration
{
    echo "# Configuration réseau post-migration - $(date)"
    echo "INTERFACE=$INTERFACE"
    echo "NEW_IP=$CURRENT_IP"
    echo "NEW_GATEWAY=$CURRENT_GATEWAY"
    echo "MIGRATION_SUCCESS=$([ $TESTS_PASSED -eq $TESTS_TOTAL ] && echo "true" || echo "false")"
    echo
    echo "# Route table"
    ip route
    echo
    echo "# Interface details" 
    ip addr show "$INTERFACE"
    echo
    echo "# Docker containers"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
} > "${BACKUP_DIR}/post-migration-config.txt"

log "${GREEN}✓ Configuration post-migration sauvegardée${NC}"

# Résumé final
log "\n${BLUE}=== RÉSUMÉ VALIDATION ===${NC}"
log "Tests passés: $TESTS_PASSED/$TESTS_TOTAL"

if [ $TESTS_PASSED -eq $TESTS_TOTAL ]; then
    log "${GREEN}🎉 MIGRATION RÉUSSIE !${NC}"
    log ""
    log "Configuration finale:"
    log "• IP: $CURRENT_IP"
    log "• Routeur: $CURRENT_GATEWAY (Netgear R7100LG)"
    log "• DNS: Fonctionnel via PiHole"
    log "• Services Docker: Opérationnels"
    log "• Home Assistant: Accessible"
    echo
    log "${GREEN}Le router Huawei peut maintenant être retiré définitivement.${NC}"
    
    # Marquer la migration comme réussie
    echo "MIGRATION_SUCCESS=true" >> "${BACKUP_DIR}/migration-status.txt"
    echo "MIGRATION_DATE=$(date)" >> "${BACKUP_DIR}/migration-status.txt"
    
else
    log "${RED}⚠ MIGRATION INCOMPLÈTE${NC}"
    log ""
    log "Problèmes détectés: $((TESTS_TOTAL - TESTS_PASSED)) test(s) échoué(s)"
    log "Consulter le log pour plus de détails: $LOG_FILE"
    log ""
    log "${YELLOW}Actions recommandées:${NC}"
    log "1. Vérifier la configuration réseau"
    log "2. Redémarrer les services si nécessaire" 
    log "3. Consulter rollback.sh en cas de problème majeur"
    
    # Marquer la migration comme incomplète
    echo "MIGRATION_SUCCESS=false" >> "${BACKUP_DIR}/migration-status.txt"
    echo "FAILED_TESTS=$((TESTS_TOTAL - TESTS_PASSED))" >> "${BACKUP_DIR}/migration-status.txt"
    
    exit 1
fi