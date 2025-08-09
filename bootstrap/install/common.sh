#!/bin/bash

# Fonctions communes pour l'installation bootstrap
# Source: source install/common.sh

# Configuration et variables globales
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$BOOTSTRAP_DIR")"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variables globales
CONFIG_FILE=""
LOG_FILE=""
DRY_RUN=false
VERBOSE=false
CURRENT_STEP=0
TOTAL_STEPS=10

# Logging functions
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Couleur selon le niveau
    local color=""
    case $level in
        "ERROR") color="$RED" ;;
        "WARN")  color="$YELLOW" ;;
        "INFO")  color="$GREEN" ;;
        "DEBUG") color="$CYAN" ;;
        *)       color="$NC" ;;
    esac
    
    # Affichage console
    echo -e "${color}[${timestamp}] [${level}]${NC} $message"
    
    # Écriture dans le log si défini
    if [ -n "$LOG_FILE" ]; then
        echo "[${timestamp}] [${level}] $message" >> "$LOG_FILE"
    fi
}

error() {
    log "ERROR" "$*"
    exit 1
}

warn() {
    log "WARN" "$*"
}

info() {
    log "INFO" "$*"
}

debug() {
    if [ "$VERBOSE" = true ]; then
        log "DEBUG" "$*"
    fi
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

# Progress bar avec étapes
show_progress() {
    local step="$1"
    local title="$2"
    local status="$3"  # PENDING, IN_PROGRESS, DONE, ERROR
    
    CURRENT_STEP=$step
    
    local icon=""
    local color=""
    case $status in
        "PENDING")     icon="⏳"; color="$YELLOW" ;;
        "IN_PROGRESS") icon="🔄"; color="$BLUE" ;;
        "DONE")        icon="✅"; color="$GREEN" ;;
        "ERROR")       icon="❌"; color="$RED" ;;
        *)             icon="⚪"; color="$NC" ;;
    esac
    
    printf "${color}[%2d/%2d] %-40s %s${NC}\n" "$step" "$TOTAL_STEPS" "$title" "$icon"
}

# Chargement de la configuration YAML
load_config() {
    local config_file="$1"
    
    if [ ! -f "$config_file" ]; then
        error "Fichier de configuration non trouvé: $config_file"
    fi
    
    CONFIG_FILE="$config_file"
    info "Configuration chargée: $config_file"
}

# Lecture d'une valeur dans le config YAML (simple parser)
get_config() {
    local key="$1"
    local default_value="$2"
    
    if [ -z "$CONFIG_FILE" ]; then
        error "Configuration non chargée"
    fi
    
    # Simple parser YAML (pour les cas basiques)
    local value=$(grep "^${key}:" "$CONFIG_FILE" | sed 's/^[^:]*:[[:space:]]*//' | sed 's/^["'\'']\|["'\'']$//g')
    
    if [ -z "$value" ]; then
        echo "$default_value"
    else
        echo "$value"
    fi
}

# Obtenir une valeur nested dans le YAML (ex: machines.docker_host.ip)
get_nested_config() {
    local path="$1"
    local default_value="$2"
    
    if [ -z "$CONFIG_FILE" ]; then
        error "Configuration non chargée"  
    fi
    
    # Utilise yq si disponible, sinon parser basique
    if command -v yq &> /dev/null; then
        local value=$(yq eval ".$path" "$CONFIG_FILE" 2>/dev/null)
        if [ "$value" = "null" ] || [ -z "$value" ]; then
            echo "$default_value"
        else
            echo "$value"
        fi
    else
        # Parser basique pour les cas simples
        local keys=($(echo "$path" | tr '.' ' '))
        local current_section=""
        local indent_level=0
        local found_value=""
        
        while IFS= read -r line; do
            # Ignorer les commentaires et lignes vides
            if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "${line// }" ]]; then
                continue
            fi
            
            # Calculer le niveau d'indentation
            local current_indent=$(echo "$line" | sed 's/[^ ].*$//' | wc -c)
            
            # Si on trouve la première clé
            if [[ "$line" =~ ^[[:space:]]*${keys[0]}: ]]; then
                if [ ${#keys[@]} -eq 1 ]; then
                    found_value=$(echo "$line" | sed 's/^[^:]*:[[:space:]]*//' | sed 's/^["'\'']\|["'\'']$//g')
                    break
                else
                    current_section="${keys[0]}"
                    indent_level=$current_indent
                fi
            elif [ -n "$current_section" ] && [ ${#keys[@]} -gt 1 ]; then
                # Chercher les clés suivantes
                if [[ "$line" =~ ^[[:space:]]*${keys[1]}: ]] && [ $current_indent -gt $indent_level ]; then
                    if [ ${#keys[@]} -eq 2 ]; then
                        found_value=$(echo "$line" | sed 's/^[^:]*:[[:space:]]*//' | sed 's/^["'\'']\|["'\'']$//g')
                        break
                    fi
                fi
            fi
        done < "$CONFIG_FILE"
        
        if [ -z "$found_value" ]; then
            echo "$default_value"
        else
            echo "$found_value"
        fi
    fi
}

# Vérification des prérequis système
check_prerequisites() {
    info "Vérification des prérequis..."
    
    local missing_tools=()
    
    # Outils requis
    local required_tools=("ssh" "scp" "nmap" "curl" "jq")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    # Outils optionnels mais recommandés
    if ! command -v "sshpass" &> /dev/null; then
        warn "sshpass non installé - authentification par mot de passe non disponible"
    fi
    
    if ! command -v "yq" &> /dev/null; then
        warn "yq non installé - utilisation du parser YAML basique"
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        error "Outils manquants: ${missing_tools[*]}"
    fi
    
    success "Prérequis validés"
}

# Génération de mot de passe sécurisé
generate_password() {
    local length="${1:-32}"
    local complexity="${2:-true}"
    
    if [ "$complexity" = "true" ]; then
        # Mot de passe complexe avec symboles
        tr -dc 'A-Za-z0-9!@#$%^&*()_+=' < /dev/urandom | head -c "$length"
    else
        # Mot de passe simple (lettres et chiffres)
        tr -dc 'A-Za-z0-9' < /dev/urandom | head -c "$length"
    fi
}

# Stockage sécurisé des secrets
store_secret() {
    local service="$1"
    local key="$2" 
    local value="$3"
    
    local secrets_dir=$(get_nested_config "security.secrets_storage" "~/.homelab/secrets")
    secrets_dir=$(eval echo "$secrets_dir")  # Expansion du ~
    
    mkdir -p "$secrets_dir"
    chmod 700 "$secrets_dir"
    
    local secret_file="$secrets_dir/${service}.env"
    
    # Ajouter ou mettre à jour la clé
    if [ -f "$secret_file" ]; then
        # Supprimer l'ancienne valeur si elle existe
        sed -i.bak "/^${key}=/d" "$secret_file"
        rm -f "${secret_file}.bak"
    fi
    
    echo "${key}=${value}" >> "$secret_file"
    chmod 600 "$secret_file"
    
    debug "Secret stocké: $service.$key"
}

# Récupération d'un secret
get_secret() {
    local service="$1"
    local key="$2"
    local default_value="$3"
    
    local secrets_dir=$(get_nested_config "security.secrets_storage" "~/.homelab/secrets")
    secrets_dir=$(eval echo "$secrets_dir")
    
    local secret_file="$secrets_dir/${service}.env"
    
    if [ -f "$secret_file" ]; then
        local value=$(grep "^${key}=" "$secret_file" | cut -d'=' -f2-)
        if [ -n "$value" ]; then
            echo "$value"
            return
        fi
    fi
    
    echo "$default_value"
}

# Test de connectivité SSH
test_ssh_connection() {
    local host="$1"
    local user="$2"
    local key_file="$3"
    local port="${4:-22}"
    
    local ssh_opts="-o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"
    
    if [ -n "$key_file" ] && [ -f "$key_file" ]; then
        ssh_opts="$ssh_opts -i $key_file"
    fi
    
    if ssh $ssh_opts -p "$port" "$user@$host" "exit" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Exécution de commande SSH
ssh_exec() {
    local host="$1"
    local user="$2"
    local command="$3"
    local key_file="$4"
    local port="${5:-22}"
    
    local ssh_opts="-o ConnectTimeout=30 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"
    
    if [ -n "$key_file" ] && [ -f "$key_file" ]; then
        ssh_opts="$ssh_opts -i $key_file"
    fi
    
    if [ "$DRY_RUN" = true ]; then
        debug "[DRY_RUN] SSH $user@$host: $command"
        return 0
    fi
    
    ssh $ssh_opts -p "$port" "$user@$host" "$command"
}

# Copie de fichier via SCP
scp_copy() {
    local source="$1"
    local host="$2"
    local user="$3"
    local destination="$4"
    local key_file="$5"
    local port="${6:-22}"
    
    local scp_opts="-o ConnectTimeout=30 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"
    
    if [ -n "$key_file" ] && [ -f "$key_file" ]; then
        scp_opts="$scp_opts -i $key_file"
    fi
    
    if [ "$DRY_RUN" = true ]; then
        debug "[DRY_RUN] SCP $source -> $user@$host:$destination"
        return 0
    fi
    
    scp $scp_opts -P "$port" "$source" "$user@$host:$destination"
}

# Attente qu'un service soit prêt
wait_for_service() {
    local host="$1"
    local port="$2"
    local timeout="${3:-60}"
    local service_name="${4:-Service}"
    
    info "Attente de $service_name sur $host:$port..."
    
    local count=0
    while [ $count -lt $timeout ]; do
        if timeout 3 bash -c "</dev/tcp/$host/$port" 2>/dev/null; then
            success "$service_name prêt sur $host:$port"
            return 0
        fi
        
        sleep 1
        ((count++))
        
        if [ $((count % 10)) -eq 0 ]; then
            debug "Attente $service_name: ${count}s/${timeout}s"
        fi
    done
    
    error "Timeout: $service_name non disponible sur $host:$port après ${timeout}s"
}

# Sauvegarde avant modification
create_backup() {
    local host="$1"
    local user="$2"
    local key_file="$3"
    local backup_name="${4:-$(date +%Y%m%d-%H%M%S)}"
    
    info "Création de sauvegarde: $backup_name"
    
    local backup_script="
        sudo mkdir -p /backup/$backup_name
        sudo cp -r /etc /backup/$backup_name/
        sudo cp -r /home /backup/$backup_name/ 2>/dev/null || true
        sudo docker system export > /backup/$backup_name/docker-export.tar 2>/dev/null || true
        sudo tar czf /backup/backup-$backup_name.tar.gz /backup/$backup_name/
        sudo rm -rf /backup/$backup_name/
        echo 'Backup created: /backup/backup-$backup_name.tar.gz'
    "
    
    ssh_exec "$host" "$user" "$backup_script" "$key_file"
}

# Initialisation des logs
init_logging() {
    local log_dir="$HOME/.homelab/logs"
    mkdir -p "$log_dir"
    
    LOG_FILE="$log_dir/bootstrap-$(date +%Y%m%d-%H%M%S).log"
    
    info "Logging initialisé: $LOG_FILE"
}

# Nettoyage en cas d'erreur
cleanup() {
    if [ $? -ne 0 ]; then
        warn "Erreur détectée, nettoyage en cours..."
        # Ici on pourrait ajouter du rollback automatique
    fi
}

# Trap pour nettoyage automatique
trap cleanup EXIT

# Export des fonctions pour utilisation dans d'autres scripts
export -f log error warn info debug success
export -f show_progress load_config get_config get_nested_config
export -f check_prerequisites generate_password store_secret get_secret
export -f test_ssh_connection ssh_exec scp_copy wait_for_service
export -f create_backup init_logging