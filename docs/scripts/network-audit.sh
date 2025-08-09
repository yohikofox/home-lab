#!/bin/bash

# Script d'audit réseau Home Lab
# Analyse l'état actuel des machines et services

set -e

# Répertoire du projet
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction de log avec timestamp
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "ERROR") echo -e "${RED}[$timestamp][ERROR]${NC} $message" >&2 ;;
        "WARN")  echo -e "${YELLOW}[$timestamp][WARN]${NC} $message" ;;
        "INFO")  echo -e "${GREEN}[$timestamp][INFO]${NC} $message" ;;
        "DEBUG") echo -e "${BLUE}[$timestamp][DEBUG]${NC} $message" ;;
    esac
}

# Chargement de la configuration
load_config() {
    if [ -f "$PROJECT_ROOT/scripts/load-config.sh" ]; then
        log "INFO" "Chargement de la configuration..."
        source "$PROJECT_ROOT/scripts/load-config.sh"
    else
        log "WARN" "Configuration par défaut utilisée"
        export DOCKER_HOST_IP="192.168.1.101"
        export HOMEASSISTANT_IP="192.168.1.100"
        export ROUTER_IP="192.168.1.1"
        export NETWORK_SUBNET="192.168.1.0/24"
        export SSH_USER="homelab"
    fi
}

# Vérification des outils requis
check_tools() {
    local tools=("nmap" "ping" "ssh" "curl" "netstat")
    local missing_tools=()
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        log "ERROR" "Outils manquants: ${missing_tools[*]}"
        log "INFO" "Installation requise:"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            log "INFO" "  brew install nmap"
        else
            log "INFO" "  sudo apt install nmap curl netcat-openbsd"
        fi
        return 1
    fi
}

# Découverte du réseau
network_discovery() {
    log "INFO" "=== DÉCOUVERTE RÉSEAU ==="
    
    # Détection de l'interface réseau active
    local gateway_ip=$(route -n get default 2>/dev/null | grep gateway | awk '{print $2}' || echo "192.168.1.1")
    local local_ip=$(ifconfig | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | head -n 1)
    
    log "INFO" "Interface locale: $local_ip"
    log "INFO" "Passerelle: $gateway_ip"
    
    # Scan du réseau pour découvrir les machines actives
    log "INFO" "Scan du réseau ${NETWORK_SUBNET}..."
    nmap -sn "$NETWORK_SUBNET" 2>/dev/null | grep -E "(Nmap scan report|MAC Address)" | while read -r line; do
        if [[ $line == *"Nmap scan report"* ]]; then
            ip=$(echo "$line" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
            echo "IP découverte: $ip"
        elif [[ $line == *"MAC Address"* ]]; then
            mac=$(echo "$line" | grep -oE '([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}')
            vendor=$(echo "$line" | sed 's/.*(//' | sed 's/).*//')
            echo "  MAC: $mac ($vendor)"
        fi
    done
}

# Test de connectivité pour une machine
test_connectivity() {
    local ip="$1"
    local hostname="$2"
    local description="$3"
    
    log "INFO" "Test connectivité: $description ($ip)"
    
    # Test ping
    if ping -c 3 -W 3 "$ip" > /dev/null 2>&1; then
        echo "  ✅ Ping: OK"
        ping_status="OK"
    else
        echo "  ❌ Ping: ÉCHEC"
        ping_status="FAIL"
        return 1
    fi
    
    # Test SSH (port 22)
    if timeout 5 bash -c "</dev/tcp/$ip/22" 2>/dev/null; then
        echo "  ✅ SSH (22): Port ouvert"
        ssh_status="OPEN"
    else
        echo "  ❌ SSH (22): Port fermé"
        ssh_status="CLOSED"
    fi
    
    # Test HTTP (port 80)
    if timeout 5 bash -c "</dev/tcp/$ip/80" 2>/dev/null; then
        echo "  ✅ HTTP (80): Port ouvert"
    else
        echo "  ⚠️  HTTP (80): Port fermé"
    fi
    
    # Test HTTPS (port 443)
    if timeout 5 bash -c "</dev/tcp/$ip/443" 2>/dev/null; then
        echo "  ✅ HTTPS (443): Port ouvert"
    else
        echo "  ⚠️  HTTPS (443): Port fermé"
    fi
    
    return 0
}

# Audit du PC Lenovo (Docker Host)
audit_docker_host() {
    log "INFO" "=== AUDIT PC LENOVO (DOCKER HOST) ==="
    
    if test_connectivity "$DOCKER_HOST_IP" "${DOCKER_HOST_HOSTNAME:-docker-host}" "PC Lenovo Docker Host"; then
        
        # Test des ports Docker spécifiques
        local docker_ports=(2376 9000 81 19999 5678)
        for port in "${docker_ports[@]}"; do
            if timeout 5 bash -c "</dev/tcp/$DOCKER_HOST_IP/$port" 2>/dev/null; then
                echo "  ✅ Port $port: Ouvert"
            else
                echo "  ⚠️  Port $port: Fermé"
            fi
        done
        
        # Test SSH avec clé (si configuré)
        if [ -f ~/.ssh/homelab_rsa ]; then
            if ssh -i ~/.ssh/homelab_rsa -o ConnectTimeout=5 -o BatchMode=yes "$SSH_USER@$DOCKER_HOST_IP" "echo 'SSH OK'" 2>/dev/null; then
                echo "  ✅ SSH avec clé: OK"
            else
                echo "  ❌ SSH avec clé: ÉCHEC"
            fi
        fi
        
        # Détection de l'OS et services
        if command -v nmap &> /dev/null; then
            log "DEBUG" "Scan détaillé des services..."
            nmap -sV -p22,80,443,2376,9000,81 "$DOCKER_HOST_IP" 2>/dev/null | grep -E "(open|closed)"
        fi
        
    else
        log "ERROR" "PC Lenovo non accessible à l'IP $DOCKER_HOST_IP"
    fi
}

# Audit du Raspberry Pi
audit_raspberry_pi() {
    log "INFO" "=== AUDIT RASPBERRY PI (HOME ASSISTANT) ==="
    
    if test_connectivity "$HOMEASSISTANT_IP" "${HOMEASSISTANT_HOSTNAME:-homeassistant-pi}" "Raspberry Pi Home Assistant"; then
        
        # Test des ports Home Assistant spécifiques
        local ha_ports=(8123 1883 8086 3000)
        for port in "${ha_ports[@]}"; do
            if timeout 5 bash -c "</dev/tcp/$HOMEASSISTANT_IP/$port" 2>/dev/null; then
                echo "  ✅ Port $port: Ouvert"
            else
                echo "  ⚠️  Port $port: Fermé"
            fi
        done
        
        # Test de Home Assistant web interface
        if curl -s -m 5 "http://$HOMEASSISTANT_IP:8123" > /dev/null 2>&1; then
            echo "  ✅ Home Assistant Web: Accessible"
        else
            echo "  ⚠️  Home Assistant Web: Non accessible"
        fi
        
    else
        log "ERROR" "Raspberry Pi non accessible à l'IP $HOMEASSISTANT_IP"
    fi
}

# Audit du routeur
audit_router() {
    log "INFO" "=== AUDIT ROUTEUR ==="
    
    if test_connectivity "$ROUTER_IP" "router" "Routeur principal"; then
        
        # Test interface web du routeur
        if curl -s -m 5 "http://$ROUTER_IP" > /dev/null 2>&1; then
            echo "  ✅ Interface web: Accessible"
        else
            echo "  ⚠️  Interface web: Non accessible"
        fi
        
        # Test UPnP (si activé)
        if timeout 5 bash -c "</dev/tcp/$ROUTER_IP/1900" 2>/dev/null; then
            echo "  ✅ UPnP: Activé"
        else
            echo "  ⚠️  UPnP: Désactivé"
        fi
        
    else
        log "ERROR" "Routeur non accessible à l'IP $ROUTER_IP"
    fi
}

# Test de résolution DNS
test_dns_resolution() {
    log "INFO" "=== TEST RÉSOLUTION DNS ==="
    
    local test_domains=("google.com" "github.com" "$HOMELAB_DOMAIN")
    
    for domain in "${test_domains[@]}"; do
        if nslookup "$domain" > /dev/null 2>&1; then
            echo "  ✅ $domain: Résolu"
        else
            echo "  ❌ $domain: Échec résolution"
        fi
    done
}

# Génération du rapport
generate_report() {
    local report_file="/tmp/homelab-audit-$(date +%Y%m%d-%H%M%S).md"
    
    log "INFO" "Génération du rapport: $report_file"
    
    cat > "$report_file" << EOF
# Rapport d'audit Home Lab

**Date**: $(date '+%Y-%m-%d %H:%M:%S')  
**Configuration**: $HOMELAB_DOMAIN

## Résumé

- **Réseau**: $NETWORK_SUBNET
- **Docker Host**: $DOCKER_HOST_IP
- **Home Assistant**: $HOMEASSISTANT_IP  
- **Routeur**: $ROUTER_IP

## Résultats détaillés

$(cat /tmp/audit-details.log 2>/dev/null || echo "Détails non disponibles")

## Recommandations

### Actions prioritaires
- [ ] Configurer SSH avec clés
- [ ] Installer Docker sur le PC Lenovo
- [ ] Vérifier Home Assistant sur Raspberry Pi
- [ ] Configurer DNS local

### Actions optionnelles
- [ ] Activer firewall (ufw)
- [ ] Configurer fail2ban
- [ ] Mettre en place monitoring

---
*Généré par homelab-audit.sh*
EOF

    echo "Rapport sauvegardé: $report_file"
}

# Fonction principale
main() {
    log "INFO" "Démarrage de l'audit Home Lab"
    
    # Redirection des détails vers un fichier temporaire
    exec 3>&1 4>&2
    exec 1>/tmp/audit-details.log 2>&1
    
    # Chargement de la configuration
    load_config
    
    # Vérification des outils
    if ! check_tools; then
        exec 1>&3 2>&4
        return 1
    fi
    
    # Exécution des audits
    network_discovery
    echo
    audit_docker_host  
    echo
    audit_raspberry_pi
    echo
    audit_router
    echo
    test_dns_resolution
    
    # Restauration des sorties standard
    exec 1>&3 2>&4
    
    # Génération du rapport
    generate_report
    
    log "INFO" "Audit terminé"
}

# Gestion des arguments
case "${1:-}" in
    "--help"|"-h")
        echo "Usage: $0 [OPTIONS]"
        echo "Options:"
        echo "  --docker-host    Audit uniquement du PC Lenovo"
        echo "  --raspberry-pi   Audit uniquement du Raspberry Pi"  
        echo "  --network-only   Découverte réseau uniquement"
        echo "  --help          Affiche cette aide"
        exit 0
        ;;
    "--docker-host")
        load_config
        check_tools && audit_docker_host
        ;;
    "--raspberry-pi")
        load_config  
        check_tools && audit_raspberry_pi
        ;;
    "--network-only")
        load_config
        check_tools && network_discovery
        ;;
    *)
        main "$@"
        ;;
esac