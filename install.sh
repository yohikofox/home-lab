#!/bin/bash

# Home Lab Universal Installer
# Usage: curl -sSL https://raw.githubusercontent.com/yohikofox/home-lab/main/install.sh | bash
# Or: git clone https://github.com/yohikofox/home-lab.git && cd home-lab && ./install.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="home-lab"
REPO_URL="https://github.com/yohikofox/home-lab.git"

# Global variables
OS_TYPE=""
DISTRO=""
ARCH=""
DOCKER_COMPOSE_CMD=""
INSTALL_DIR=""

# Logging functions
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${PURPLE}[SUCCESS]${NC} $1"
}

# Banner
show_banner() {
    cat << "EOF"
╔══════════════════════════════════════════════════════════╗
║                 🏠 HOME LAB INSTALLER 🏠                 ║
║                                                          ║
║  Universal installer for Yohikofox Home Lab             ║
║  • N8N Automation & Disaster Recovery                   ║
║  • Docker-based Architecture                            ║
║  • Cross-platform Support                               ║
╚══════════════════════════════════════════════════════════╝
EOF
}

# Detect system information
detect_system() {
    log "Détection de l'environnement système..."
    
    # Detect OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS_TYPE="linux"
        
        # Detect Linux distribution
        if [ -f /etc/os-release ]; then
            source /etc/os-release
            DISTRO="$ID"
        elif command -v lsb_release >/dev/null 2>&1; then
            DISTRO=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
        else
            DISTRO="unknown"
        fi
        
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="macos"
        DISTRO="macos"
        
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS_TYPE="windows"
        DISTRO="windows"
        
    else
        OS_TYPE="unknown"
        DISTRO="unknown"
    fi
    
    # Detect architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64|amd64)
            ARCH="amd64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        armv7l)
            ARCH="arm"
            ;;
        *)
            warning "Architecture non reconnue: $ARCH"
            ;;
    esac
    
    info "Système détecté: $OS_TYPE ($DISTRO) - $ARCH"
}

# Check if running as root (and warn against it)
check_root() {
    if [ "$EUID" -eq 0 ]; then
        error "Ce script ne doit PAS être exécuté en tant que root"
        error "Exécutez-le avec votre utilisateur normal qui a accès à sudo"
        exit 1
    fi
}

# Check and install prerequisites
install_prerequisites() {
    log "Vérification et installation des prérequis..."
    
    case $OS_TYPE in
        "linux")
            install_linux_prerequisites
            ;;
        "macos")
            install_macos_prerequisites
            ;;
        "windows")
            error "Installation automatique sur Windows non supportée"
            error "Veuillez utiliser WSL2 ou installer manuellement Docker Desktop"
            exit 1
            ;;
        *)
            error "Système d'exploitation non supporté: $OS_TYPE"
            exit 1
            ;;
    esac
}

# Install Linux prerequisites
install_linux_prerequisites() {
    # Update package lists
    case $DISTRO in
        "ubuntu"|"debian"|"raspbian")
            sudo apt-get update
            
            # Install basic tools
            sudo apt-get install -y curl wget git unzip openssl
            
            # Install Docker if not present
            if ! command -v docker &> /dev/null; then
                log "Installation de Docker..."
                curl -fsSL https://get.docker.com | sudo sh
                sudo usermod -aG docker $USER
                info "Docker installé. Vous devrez peut-être redémarrer votre session."
            fi
            
            # Install Docker Compose if not present
            if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null 2>&1; then
                log "Installation de Docker Compose..."
                sudo apt-get install -y docker-compose-plugin
            fi
            ;;
            
        "centos"|"rhel"|"fedora"|"almalinux"|"rocky")
            if command -v dnf &> /dev/null; then
                PKG_MGR="dnf"
            else
                PKG_MGR="yum"
            fi
            
            sudo $PKG_MGR update -y
            sudo $PKG_MGR install -y curl wget git unzip openssl
            
            # Install Docker
            if ! command -v docker &> /dev/null; then
                log "Installation de Docker..."
                curl -fsSL https://get.docker.com | sudo sh
                sudo systemctl enable docker
                sudo systemctl start docker
                sudo usermod -aG docker $USER
            fi
            
            # Install Docker Compose
            if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null 2>&1; then
                log "Installation de Docker Compose..."
                sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                sudo chmod +x /usr/local/bin/docker-compose
            fi
            ;;
            
        "arch"|"manjaro")
            sudo pacman -Syu --noconfirm
            sudo pacman -S --noconfirm curl wget git unzip openssl docker docker-compose
            sudo systemctl enable docker
            sudo systemctl start docker
            sudo usermod -aG docker $USER
            ;;
            
        *)
            warning "Distribution Linux non reconnue: $DISTRO"
            warning "Installation manuelle des prérequis nécessaire"
            ;;
    esac
    
    # Determine Docker Compose command
    if docker compose version &> /dev/null 2>&1; then
        DOCKER_COMPOSE_CMD="docker compose"
    elif command -v docker-compose &> /dev/null; then
        DOCKER_COMPOSE_CMD="docker-compose"
    else
        error "Docker Compose non trouvé après installation"
        exit 1
    fi
}

# Install macOS prerequisites
install_macos_prerequisites() {
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        log "Installation de Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # Install prerequisites
    brew install curl wget git openssl
    
    # Install Docker Desktop if not present
    if ! command -v docker &> /dev/null; then
        log "Installation de Docker Desktop..."
        warning "Docker Desktop sera téléchargé. Vous devrez l'installer manuellement."
        
        if [[ "$ARCH" == "arm64" ]]; then
            curl -L "https://desktop.docker.com/mac/main/arm64/Docker.dmg" -o /tmp/Docker.dmg
        else
            curl -L "https://desktop.docker.com/mac/main/amd64/Docker.dmg" -o /tmp/Docker.dmg
        fi
        
        warning "Veuillez installer Docker Desktop depuis /tmp/Docker.dmg puis relancer ce script"
        exit 1
    fi
    
    DOCKER_COMPOSE_CMD="docker compose"
}

# Clone or update repository
setup_repository() {
    log "Configuration du repository..."
    
    # If we're already in the repo directory, just update
    if [ -f "$SCRIPT_DIR/README.md" ] && grep -q "Yohikofox Home Lab" "$SCRIPT_DIR/README.md" 2>/dev/null; then
        log "Repository déjà présent, mise à jour..."
        git pull origin main 2>/dev/null || warning "Impossible de mettre à jour le repository"
        INSTALL_DIR="$SCRIPT_DIR"
    else
        # Clone the repository
        INSTALL_DIR="$HOME/$PROJECT_NAME"
        
        if [ -d "$INSTALL_DIR" ]; then
            log "Mise à jour du repository existant..."
            cd "$INSTALL_DIR"
            git pull origin main 2>/dev/null || {
                warning "Impossible de mettre à jour, re-clonage..."
                cd "$HOME"
                rm -rf "$INSTALL_DIR"
                git clone "$REPO_URL" "$INSTALL_DIR"
            }
        else
            log "Clonage du repository..."
            git clone "$REPO_URL" "$INSTALL_DIR"
        fi
        
        cd "$INSTALL_DIR"
    fi
    
    info "Repository configuré dans: $INSTALL_DIR"
}

# Generate environment configuration
generate_config() {
    log "Génération de la configuration..."
    
    local env_file="$INSTALL_DIR/docker-compose/n8n/.env"
    local env_example="$INSTALL_DIR/docker-compose/n8n/.env.example"
    
    if [ ! -f "$env_example" ]; then
        error "Fichier .env.example non trouvé"
        exit 1
    fi
    
    # Create .env file if it doesn't exist
    if [ ! -f "$env_file" ]; then
        log "Création du fichier de configuration..."
        cp "$env_example" "$env_file"
        
        # Generate random password
        local random_password
        if command -v openssl &> /dev/null; then
            random_password=$(openssl rand -base64 32)
        else
            random_password=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 32)
        fi
        
        # Replace placeholder password
        sed -i.bak "s/changeme_strong_password/$random_password/" "$env_file" 2>/dev/null || {
            sed -i "" "s/changeme_strong_password/$random_password/" "$env_file"
        }
        rm -f "$env_file.bak"
        
        success "Mot de passe N8N généré automatiquement"
    else
        info "Configuration existante préservée"
    fi
    
    # Set proper permissions
    chmod 600 "$env_file"
}

# Setup directories and permissions
setup_directories() {
    log "Configuration des répertoires..."
    
    local backup_dir="$INSTALL_DIR/backups"
    local logs_dir="$backup_dir/logs"
    
    # Create directories
    mkdir -p "$backup_dir"/{vaultwarden/{daily,weekly,monthly,configs},logs}
    mkdir -p "$INSTALL_DIR/config"
    
    # Set executable permissions on scripts
    find "$INSTALL_DIR/scripts" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    
    info "Répertoires configurés"
}

# Detect existing services
detect_existing_services() {
    log "Détection des services existants..."
    
    # Check for existing containers
    if command -v docker &> /dev/null; then
        local existing_containers=$(docker ps -a --format "table {{.Names}}" 2>/dev/null | tail -n +2 || true)
        
        if echo "$existing_containers" | grep -q "vaultwarden\|portainer\|nginx-proxy-manager"; then
            warning "Services existants détectés:"
            echo "$existing_containers" | grep -E "vaultwarden|portainer|nginx-proxy-manager" | sed 's/^/  - /'
            warning "L'installation N8N sera compatible mais n'affectera pas ces services"
        fi
    fi
}

# Start services
start_services() {
    log "Démarrage des services..."
    
    cd "$INSTALL_DIR/docker-compose/n8n"
    
    # Pull latest images
    $DOCKER_COMPOSE_CMD pull
    
    # Start services
    $DOCKER_COMPOSE_CMD up -d
    
    # Wait for services to be ready
    log "Attente du démarrage des services..."
    local retries=30
    
    while [ $retries -gt 0 ]; do
        if curl -s http://localhost:5678 >/dev/null 2>&1; then
            success "N8N est prêt!"
            break
        fi
        
        sleep 2
        ((retries--))
        
        if [ $retries -eq 0 ]; then
            error "Timeout: N8N ne répond pas après 60 secondes"
            error "Vérifiez les logs: $DOCKER_COMPOSE_CMD logs n8n"
            exit 1
        fi
    done
}

# Show final instructions
show_completion() {
    local env_file="$INSTALL_DIR/docker-compose/n8n/.env"
    local n8n_password=$(grep "N8N_PASSWORD=" "$env_file" | cut -d'=' -f2)
    
    cat << EOF

╔══════════════════════════════════════════════════════════╗
║                 🎉 INSTALLATION RÉUSSIE! 🎉              ║
╚══════════════════════════════════════════════════════════╝

🌐 ACCÈS N8N:
   URL: http://localhost:5678
   Utilisateur: admin
   Mot de passe: $n8n_password

📋 ÉTAPES SUIVANTES:

1. 🔐 Configurez vos credentials:
   Éditez: $env_file
   
   Tokens à configurer:
   • TELEGRAM_BOT_TOKEN (créez un bot via @BotFather)
   • TELEGRAM_CHAT_ID (votre ID de chat)
   • Google Drive credentials (optionnel)

2. 📥 Importez les workflows:
   Fichiers dans: $INSTALL_DIR/workflows/
   • daily_backup_workflow.json
   • health_monitoring_workflow.json  
   • monthly_test_restore_workflow.json

3. 🧪 Testez les scripts:
   $INSTALL_DIR/scripts/backup/vaultwarden_backup.sh daily
   $INSTALL_DIR/scripts/monitoring/health_check.sh

4. 📊 Surveillez les logs:
   $DOCKER_COMPOSE_CMD logs -f n8n

📚 DOCUMENTATION:
   • Architecture: $INSTALL_DIR/docs/ARCHITECTURE.md
   • Services: $INSTALL_DIR/docs/SERVICES.md
   • Réseau: $INSTALL_DIR/docs/NETWORK.md

🔧 GESTION DES SERVICES:
   cd $INSTALL_DIR/docker-compose/n8n
   $DOCKER_COMPOSE_CMD up -d     # Démarrer
   $DOCKER_COMPOSE_CMD down      # Arrêter
   $DOCKER_COMPOSE_CMD logs -f   # Logs en temps réel

⚠️  IMPORTANT:
   • Configurez vos tokens avant d'activer les workflows
   • Sauvegardez votre fichier .env
   • Testez les workflows manuellement avant automation

EOF

    success "Installation terminée avec succès!"
    info "Repository: $INSTALL_DIR"
}

# Cleanup on failure
cleanup() {
    if [ $? -ne 0 ]; then
        error "Installation échouée"
        warning "Nettoyage des ressources..."
        
        if [ -n "$INSTALL_DIR" ] && [ -d "$INSTALL_DIR/docker-compose/n8n" ]; then
            cd "$INSTALL_DIR/docker-compose/n8n" 2>/dev/null
            $DOCKER_COMPOSE_CMD down 2>/dev/null || true
        fi
    fi
}

# Main installation process
main() {
    trap cleanup EXIT
    
    show_banner
    check_root
    detect_system
    install_prerequisites
    setup_repository
    detect_existing_services
    generate_config
    setup_directories
    start_services
    show_completion
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi