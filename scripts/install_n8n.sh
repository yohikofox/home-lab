#!/bin/bash

# N8N Installation Script for Vaultwarden Disaster Recovery
# Usage: ./install_n8n.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
N8N_DIR="$PROJECT_ROOT/docker-compose/n8n"
BACKUP_DIR="$PROJECT_ROOT/backups"

# Logging function
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log "Vérification des prérequis..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        error "Docker n'est pas installé"
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        error "Docker Compose n'est pas installé"
        exit 1
    fi
    
    # Check if Vaultwarden container exists
    if ! docker ps -a --format "table {{.Names}}" | grep -q "^vaultwarden$"; then
        warning "Container Vaultwarden non trouvé. Assurez-vous qu'il est configuré."
    fi
    
    log "Prérequis validés ✅"
}

# Create directories and set permissions
setup_directories() {
    log "Création des répertoires..."
    
    mkdir -p "$BACKUP_DIR"/{vaultwarden/{daily,weekly,monthly,configs},logs}
    mkdir -p "$PROJECT_ROOT/config"
    
    # Set proper permissions
    chmod -R 755 "$PROJECT_ROOT/scripts"
    chmod +x "$PROJECT_ROOT/scripts"/{backup,monitoring}/*.sh
    
    # Create backup directory with proper permissions for Docker
    sudo chown -R 1000:1000 "$BACKUP_DIR" 2>/dev/null || {
        warning "Impossible de changer les permissions de $BACKUP_DIR. Vous devrez le faire manuellement."
    }
    
    log "Répertoires créés ✅"
}

# Generate environment file
generate_env_file() {
    log "Configuration de l'environnement..."
    
    local env_file="$N8N_DIR/.env"
    
    if [ -f "$env_file" ]; then
        warning "Le fichier .env existe déjà. Sauvegarde en .env.backup"
        cp "$env_file" "$env_file.backup"
    fi
    
    # Generate random password if not exists
    if [ ! -f "$env_file" ]; then
        log "Génération du fichier .env..."
        cp "$N8N_DIR/.env.example" "$env_file"
        
        # Generate random password
        RANDOM_PASSWORD=$(openssl rand -base64 32 2>/dev/null || tr -dc A-Za-z0-9 </dev/urandom | head -c 32)
        sed -i.bak "s/changeme_strong_password/$RANDOM_PASSWORD/" "$env_file" 2>/dev/null || {
            sed -i "" "s/changeme_strong_password/$RANDOM_PASSWORD/" "$env_file"
        }
        rm -f "$env_file.bak"
        
        log "Mot de passe N8N généré automatiquement"
    fi
    
    log "Configuration terminée ✅"
    log "⚠️  N'oubliez pas de configurer les tokens Telegram et Google Drive dans $env_file"
}

# Start N8N
start_n8n() {
    log "Démarrage de N8N..."
    
    cd "$N8N_DIR"
    
    # Pull latest images
    docker-compose pull
    
    # Start services
    docker-compose up -d
    
    # Wait for N8N to be ready
    log "Attente du démarrage de N8N..."
    for i in {1..30}; do
        if curl -s http://localhost:5678 >/dev/null 2>&1; then
            break
        fi
        sleep 2
    done
    
    if curl -s http://localhost:5678 >/dev/null 2>&1; then
        log "N8N démarré avec succès ✅"
        log "Interface accessible sur: http://localhost:5678"
    else
        error "Timeout: N8N ne répond pas après 60 secondes"
        exit 1
    fi
}

# Import workflows
import_workflows() {
    log "Configuration des workflows..."
    
    # Wait a bit more for N8N to be fully ready
    sleep 10
    
    local workflows_dir="$PROJECT_ROOT/workflows"
    
    if [ -d "$workflows_dir" ]; then
        log "Workflows trouvés dans $workflows_dir"
        log "⚠️  Importez manuellement les workflows via l'interface N8N:"
        
        for workflow in "$workflows_dir"/*.json; do
            if [ -f "$workflow" ]; then
                log "  - $(basename "$workflow")"
            fi
        done
    else
        warning "Répertoire workflows non trouvé"
    fi
}

# Configure Nginx Proxy Manager
configure_nginx() {
    log "Configuration Nginx Proxy Manager..."
    
    # Check if running behind NPM
    if docker ps --format "table {{.Names}}" | grep -q "nginx-proxy-manager"; then
        log "Nginx Proxy Manager détecté"
        log "⚠️  Configurez manuellement:"
        log "  - Domaine: n8n.yolo.yt"
        log "  - Forward Hostname/IP: n8n (ou IP du serveur)"
        log "  - Forward Port: 5678"
        log "  - SSL: Activé avec Let's Encrypt"
    else
        warning "Nginx Proxy Manager non détecté. N8N sera accessible uniquement en local."
    fi
}

# Display final instructions
show_final_instructions() {
    log "Installation terminée! 🎉"
    echo ""
    echo -e "${GREEN}📋 Étapes suivantes:${NC}"
    echo "1. Accédez à N8N sur http://localhost:5678"
    echo "2. Configurez les credentials dans le fichier .env:"
    echo "   - Token Telegram Bot"
    echo "   - Credentials Google Drive"
    echo "3. Importez les workflows depuis l'interface N8N"
    echo "4. Configurez Nginx Proxy Manager pour n8n.yolo.yt"
    echo "5. Testez les workflows manuellement"
    echo ""
    echo -e "${GREEN}📁 Fichiers importants:${NC}"
    echo "   - Configuration: $N8N_DIR/.env"
    echo "   - Workflows: $PROJECT_ROOT/workflows/"
    echo "   - Scripts: $PROJECT_ROOT/scripts/"
    echo "   - Logs: docker-compose logs n8n"
    echo ""
    echo -e "${YELLOW}🔐 Credentials N8N:${NC}"
    echo "   - Utilisateur: admin"
    echo "   - Mot de passe: voir $N8N_DIR/.env"
}

# Main installation process
main() {
    log "🚀 Installation N8N pour Disaster Recovery Vaultwarden"
    log "=================================================="
    
    check_prerequisites
    setup_directories
    generate_env_file
    start_n8n
    import_workflows
    configure_nginx
    show_final_instructions
}

# Run installation
main "$@"