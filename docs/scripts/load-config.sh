#!/bin/bash

# Script de chargement de la configuration Home Lab
# Usage: source scripts/load-config.sh

set -e

# Répertoire du projet
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" >&2 ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} $message" ;;
        "INFO")  echo -e "${GREEN}[INFO]${NC} $message" ;;
        "DEBUG") echo -e "${BLUE}[DEBUG]${NC} $message" ;;
    esac
}

# Vérification des fichiers de configuration
check_config_files() {
    local config_found=false
    
    # Vérifier .env
    if [ -f "$PROJECT_ROOT/.env" ]; then
        log "INFO" "Chargement de .env"
        # Export de toutes les variables du .env
        set -a
        source "$PROJECT_ROOT/.env"
        set +a
        config_found=true
    elif [ -f "$PROJECT_ROOT/.env.example" ]; then
        log "WARN" "Fichier .env non trouvé, utilisation de .env.example"
        log "WARN" "Copiez .env.example vers .env et adaptez les valeurs"
        set -a
        source "$PROJECT_ROOT/.env.example"
        set +a
        config_found=true
    fi
    
    # Vérifier config.yml
    if [ -f "$PROJECT_ROOT/config.yml" ]; then
        log "INFO" "Fichier config.yml trouvé"
        export CONFIG_FILE="$PROJECT_ROOT/config.yml"
    elif [ -f "$PROJECT_ROOT/config.yml.example" ]; then
        log "WARN" "Fichier config.yml non trouvé, utilisation de config.yml.example"
        log "WARN" "Copiez config.yml.example vers config.yml et adaptez les valeurs"
        export CONFIG_FILE="$PROJECT_ROOT/config.yml.example"
    fi
    
    if [ "$config_found" = false ]; then
        log "ERROR" "Aucun fichier de configuration trouvé"
        log "ERROR" "Créez un fichier .env ou config.yml à partir des exemples"
        return 1
    fi
    
    return 0
}

# Initialisation des variables par défaut
init_default_variables() {
    # Domaines
    export HOMELAB_DOMAIN="${HOMELAB_DOMAIN:-homelab.local}"
    export VAULTWARDEN_DOMAIN="${VAULTWARDEN_SUBDOMAIN:-vault}.${HOMELAB_DOMAIN}"
    export ZITADEL_DOMAIN="${ZITADEL_SUBDOMAIN:-auth}.${HOMELAB_DOMAIN}"
    export SNIPEIT_DOMAIN="${SNIPEIT_SUBDOMAIN:-assets}.${HOMELAB_DOMAIN}"
    export OCTOPRINT_DOMAIN="${OCTOPRINT_SUBDOMAIN:-print}.${HOMELAB_DOMAIN}"
    export PIHOLE_DOMAIN="${PIHOLE_SUBDOMAIN:-pi}.${HOMELAB_DOMAIN}"
    export PORTAINER_DOMAIN="${PORTAINER_SUBDOMAIN:-portainer}.${HOMELAB_DOMAIN}"
    export NPM_DOMAIN="${NPM_SUBDOMAIN:-npm}.${HOMELAB_DOMAIN}"
    export N8N_DOMAIN="${N8N_SUBDOMAIN:-n8n}.${HOMELAB_DOMAIN}"
    export NETDATA_DOMAIN="${NETDATA_SUBDOMAIN:-monitoring}.${HOMELAB_DOMAIN}"
    export DOCS_DOMAIN="${DOCS_SUBDOMAIN:-docs}.${HOMELAB_DOMAIN}"
    
    # IPs et réseau
    export DOCKER_HOST_IP="${DOCKER_HOST_IP:-192.168.1.101}"
    export HOMEASSISTANT_IP="${HOMEASSISTANT_IP:-192.168.1.100}"
    export ROUTER_IP="${ROUTER_IP:-192.168.1.1}"
    export NETWORK_SUBNET="${NETWORK_SUBNET:-192.168.1.0/24}"
    
    # Hostnames
    export DOCKER_HOST_HOSTNAME="${DOCKER_HOST_HOSTNAME:-docker-host}"
    export HOMEASSISTANT_HOSTNAME="${HOMEASSISTANT_HOSTNAME:-homeassistant-pi}"
    
    # Utilisateur SSH
    export SSH_USER="${SSH_USER:-homelab}"
    
    # Répertoires
    export DOCKER_DATA_DIR="${DOCKER_DATA_DIR:-/opt/docker-data}"
    export BACKUP_DIR="${BACKUP_DIR:-/opt/backups}"
    export SECRETS_DIR="${SECRETS_DIR:-/home/${SSH_USER}/.homelab/secrets}"
    
    # Email
    export SSL_EMAIL="${SSL_EMAIL:-admin@${HOMELAB_DOMAIN}}"
    
    log "DEBUG" "Variables initialisées avec domaine: ${HOMELAB_DOMAIN}"
}

# Fonction pour afficher la configuration chargée
show_config() {
    log "INFO" "Configuration chargée:"
    echo "  Domaine principal: ${HOMELAB_DOMAIN}"
    echo "  Docker Host: ${DOCKER_HOST_HOSTNAME} (${DOCKER_HOST_IP})"
    echo "  Home Assistant: ${HOMEASSISTANT_HOSTNAME} (${HOMEASSISTANT_IP})"
    echo "  Services:"
    echo "    - Vaultwarden: https://${VAULTWARDEN_DOMAIN}"
    echo "    - Zitadel: https://${ZITADEL_DOMAIN}"
    echo "    - PiHole: https://${PIHOLE_DOMAIN}"
    echo "    - Portainer: https://${PORTAINER_DOMAIN}"
    echo "    - Documentation: https://${DOCS_DOMAIN}"
}

# Fonction pour générer les fichiers de configuration à partir des templates
generate_configs() {
    local template_dir="$PROJECT_ROOT/templates"
    local output_dir="$PROJECT_ROOT/generated"
    
    mkdir -p "$output_dir"
    
    log "INFO" "Génération des configurations à partir des templates..."
    
    # Traiter tous les fichiers .template
    if [ -d "$template_dir" ]; then
        find "$template_dir" -name "*.template" -type f | while read -r template_file; do
            local output_file="$output_dir/$(basename "$template_file" .template)"
            
            # Remplacer les variables dans le template
            envsubst < "$template_file" > "$output_file"
            
            log "DEBUG" "Template généré: $(basename "$output_file")"
        done
    fi
}

# Fonction principale
main() {
    log "INFO" "Initialisation de la configuration Home Lab"
    
    # Vérification et chargement des fichiers de config
    if ! check_config_files; then
        return 1
    fi
    
    # Initialisation des variables par défaut
    init_default_variables
    
    # Génération des configurations si nécessaire
    if [ "$1" = "--generate" ]; then
        generate_configs
    fi
    
    # Affichage de la configuration si demandé
    if [ "$1" = "--show" ] || [ "$2" = "--show" ]; then
        show_config
    fi
    
    log "INFO" "Configuration initialisée avec succès"
}

# Exécution si le script est appelé directement (pas sourcé)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi