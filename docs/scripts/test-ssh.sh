#!/bin/bash

# Script de test de connectivité SSH
# Valide l'accès SSH aux machines du home lab

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

# Fonction de log
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
        source "$PROJECT_ROOT/scripts/load-config.sh"
        log "INFO" "Configuration chargée: $HOMELAB_DOMAIN"
    else
        log "WARN" "Utilisation de la configuration par défaut"
        export DOCKER_HOST_IP="192.168.1.101"
        export HOMEASSISTANT_IP="192.168.1.100"
        export SSH_USER="homelab"
    fi
}

# Test SSH avec mot de passe
test_ssh_password() {
    local ip="$1"
    local user="$2"
    local hostname="$3"
    
    log "INFO" "Test SSH avec mot de passe: $user@$ip ($hostname)"
    
    if command -v sshpass &> /dev/null; then
        echo -n "Mot de passe SSH pour $user@$ip: "
        read -s password
        echo
        
        if sshpass -p "$password" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$user@$ip" "echo 'SSH OK'" 2>/dev/null; then
            echo "  ✅ Connexion SSH: OK"
            return 0
        else
            echo "  ❌ Connexion SSH: ÉCHEC"
            return 1
        fi
    else
        log "WARN" "sshpass non installé. Test SSH interactif..."
        if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$user@$ip" "echo 'SSH OK'" 2>/dev/null; then
            echo "  ✅ Connexion SSH: OK"
            return 0
        else
            echo "  ❌ Connexion SSH: ÉCHEC"
            return 1
        fi
    fi
}

# Test SSH avec clé
test_ssh_key() {
    local ip="$1"
    local user="$2"
    local hostname="$3"
    local key_path="$4"
    
    log "INFO" "Test SSH avec clé: $user@$ip ($hostname)"
    log "DEBUG" "Clé SSH: $key_path"
    
    if [ ! -f "$key_path" ]; then
        echo "  ❌ Clé SSH non trouvée: $key_path"
        return 1
    fi
    
    if ssh -i "$key_path" -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no "$user@$ip" "echo 'SSH OK'" 2>/dev/null; then
        echo "  ✅ Connexion SSH avec clé: OK"
        return 0
    else
        echo "  ❌ Connexion SSH avec clé: ÉCHEC"
        return 1
    fi
}

# Génération de clés SSH
generate_ssh_key() {
    local key_path="$1"
    local email="${2:-homelab@${HOMELAB_DOMAIN:-homelab.local}}"
    
    log "INFO" "Génération de la clé SSH: $key_path"
    
    if [ -f "$key_path" ]; then
        log "WARN" "Clé SSH existe déjà: $key_path"
        return 0
    fi
    
    mkdir -p "$(dirname "$key_path")"
    
    ssh-keygen -t rsa -b 4096 -f "$key_path" -C "$email" -N ""
    
    if [ $? -eq 0 ]; then
        echo "  ✅ Clé SSH générée: $key_path"
        echo "  📋 Clé publique:"
        cat "$key_path.pub"
        return 0
    else
        echo "  ❌ Échec génération clé SSH"
        return 1
    fi
}

# Copie de clé SSH vers machine distante
copy_ssh_key() {
    local ip="$1"
    local user="$2"
    local key_path="$3"
    
    log "INFO" "Copie de clé SSH vers $user@$ip"
    
    if [ ! -f "$key_path.pub" ]; then
        log "ERROR" "Clé publique non trouvée: $key_path.pub"
        return 1
    fi
    
    if command -v ssh-copy-id &> /dev/null; then
        if ssh-copy-id -i "$key_path.pub" "$user@$ip" 2>/dev/null; then
            echo "  ✅ Clé SSH copiée avec succès"
            return 0
        else
            echo "  ❌ Échec copie clé SSH"
            return 1
        fi
    else
        log "WARN" "ssh-copy-id non disponible. Copie manuelle requise:"
        echo "  cat $key_path.pub | ssh $user@$ip 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys'"
        return 1
    fi
}

# Test complet d'une machine
test_machine() {
    local ip="$1"
    local hostname="$2"
    local description="$3"
    
    log "INFO" "=== TEST SSH: $description ==="
    
    # Test de connectivité réseau d'abord
    if ! ping -c 1 -W 3 "$ip" > /dev/null 2>&1; then
        log "ERROR" "Machine non accessible: $ip"
        return 1
    fi
    
    echo "  ✅ Ping: OK"
    
    # Vérifier si le port SSH est ouvert
    if ! timeout 5 bash -c "</dev/tcp/$ip/22" 2>/dev/null; then
        echo "  ❌ Port SSH (22): Fermé"
        return 1
    fi
    
    echo "  ✅ Port SSH (22): Ouvert"
    
    # Tentative avec clé SSH si elle existe
    local key_path="$HOME/.ssh/homelab_rsa"
    if [ -f "$key_path" ]; then
        if test_ssh_key "$ip" "$SSH_USER" "$hostname" "$key_path"; then
            return 0
        fi
    fi
    
    # Tentative avec mot de passe
    if test_ssh_password "$ip" "$SSH_USER" "$hostname"; then
        # Proposer de copier la clé SSH
        echo -n "Voulez-vous configurer l'authentification par clé SSH ? (y/N): "
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            if [ ! -f "$key_path" ]; then
                generate_ssh_key "$key_path"
            fi
            copy_ssh_key "$ip" "$SSH_USER" "$key_path"
        fi
        return 0
    fi
    
    return 1
}

# Découverte interactive d'IPs
discover_machines() {
    log "INFO" "=== DÉCOUVERTE INTERACTIVE ==="
    
    # Obtenir le réseau local
    local local_ip=$(ifconfig | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | head -n 1)
    local network=$(echo "$local_ip" | cut -d. -f1-3).0/24
    
    log "INFO" "Réseau détecté: $network"
    log "INFO" "Scan des machines actives..."
    
    # Scan rapide du réseau
    nmap -sn "$network" 2>/dev/null | grep -E "(Nmap scan report)" | while read -r line; do
        local ip=$(echo "$line" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
        echo "Machine trouvée: $ip"
        
        # Test SSH sur chaque machine trouvée
        if timeout 3 bash -c "</dev/tcp/$ip/22" 2>/dev/null; then
            echo "  → SSH disponible sur $ip"
        fi
    done
    
    echo
    echo "Entrez manuellement les IPs des machines à tester:"
    echo -n "IP du PC Lenovo (Docker Host) [${DOCKER_HOST_IP}]: "
    read -r docker_ip
    export DOCKER_HOST_IP="${docker_ip:-$DOCKER_HOST_IP}"
    
    echo -n "IP du Raspberry Pi (Home Assistant) [${HOMEASSISTANT_IP}]: "
    read -r pi_ip
    export HOMEASSISTANT_IP="${pi_ip:-$HOMEASSISTANT_IP}"
}

# Fonction principale
main() {
    log "INFO" "Test de connectivité SSH Home Lab"
    
    # Chargement de la configuration
    load_config
    
    # Mode interactif si aucune machine n'est accessible
    if [ "$1" = "--discover" ]; then
        discover_machines
    fi
    
    # Test des machines configurées
    local success=0
    local total=0
    
    if [ -n "$DOCKER_HOST_IP" ]; then
        ((total++))
        if test_machine "$DOCKER_HOST_IP" "${DOCKER_HOST_HOSTNAME:-docker-host}" "PC Lenovo Docker Host"; then
            ((success++))
        fi
        echo
    fi
    
    if [ -n "$HOMEASSISTANT_IP" ]; then
        ((total++))
        if test_machine "$HOMEASSISTANT_IP" "${HOMEASSISTANT_HOSTNAME:-homeassistant-pi}" "Raspberry Pi Home Assistant"; then
            ((success++))
        fi
        echo
    fi
    
    # Résumé
    log "INFO" "Résultats: $success/$total machines SSH OK"
    
    if [ "$success" -eq "$total" ] && [ "$total" -gt 0 ]; then
        log "INFO" "✅ Toutes les machines sont accessibles en SSH"
        return 0
    else
        log "WARN" "⚠️  Certaines machines ne sont pas accessibles en SSH"
        return 1
    fi
}

# Gestion des arguments
case "${1:-}" in
    "--help"|"-h")
        echo "Usage: $0 [OPTIONS]"
        echo "Options:"
        echo "  --discover      Mode découverte interactive"
        echo "  --generate-key  Générer une nouvelle clé SSH"
        echo "  --help          Affiche cette aide"
        exit 0
        ;;
    "--generate-key")
        load_config
        key_path="$HOME/.ssh/homelab_rsa"
        generate_ssh_key "$key_path"
        ;;
    *)
        main "$@"
        ;;
esac