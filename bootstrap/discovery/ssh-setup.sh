#!/bin/bash

# Configuration SSH pour l'installation bootstrap
# Usage: ./ssh-setup.sh [config.yml]

set -e

# Chargement des fonctions communes
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../install/common.sh"

# Configuration SSH
SSH_KEY_TYPE="rsa"
SSH_KEY_BITS="4096"
SSH_CONFIG_DIR="$HOME/.ssh"
SSH_CONFIG_FILE="$SSH_CONFIG_DIR/config"
HOMELAB_SSH_CONFIG="$SSH_CONFIG_DIR/homelab_config"

# Génération d'une paire de clés SSH
generate_ssh_key() {
    local key_path="$1"
    local key_comment="$2"
    
    if [ -f "$key_path" ]; then
        warn "Clé SSH existante trouvée: $key_path"
        
        read -p "Voulez-vous la remplacer? [y/N]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info "Conservation de la clé existante"
            return 0
        fi
        
        info "Sauvegarde de l'ancienne clé..."
        mv "$key_path" "${key_path}.backup.$(date +%Y%m%d_%H%M%S)"
        mv "${key_path}.pub" "${key_path}.pub.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
    fi
    
    info "Génération de la clé SSH: $key_path"
    
    ssh-keygen -t "$SSH_KEY_TYPE" -b "$SSH_KEY_BITS" -f "$key_path" -C "$key_comment" -N ""
    
    if [ $? -eq 0 ]; then
        success "Clé SSH générée: $key_path"
        chmod 600 "$key_path"
        chmod 644 "${key_path}.pub"
    else
        error "Échec de génération de la clé SSH"
    fi
}

# Configuration du fichier SSH config
setup_ssh_config() {
    local config_file="$1"
    
    info "Configuration SSH pour Home Lab..."
    
    # Chargement de la configuration
    load_config "$config_file"
    
    # Récupération des paramètres
    local ssh_key=$(get_nested_config "options.ssh_key_path" "~/.ssh/homelab_rsa")
    ssh_key=$(eval echo "$ssh_key")
    
    local docker_host_ip=$(get_nested_config "machines.docker_host.ip" "192.168.1.101")
    local docker_host_user=$(get_nested_config "machines.docker_host.user" "homelab")
    local docker_host_hostname=$(get_nested_config "machines.docker_host.hostname" "lenovo")
    
    local ha_host_ip=$(get_nested_config "machines.homeassistant.ip" "192.168.1.100")
    local ha_host_user=$(get_nested_config "machines.homeassistant.user" "homelab")
    local ha_host_hostname=$(get_nested_config "machines.homeassistant.hostname" "homeassistant")
    
    local ssh_port=$(get_nested_config "security.ssh_port" "22")
    
    # Création de la configuration SSH pour Home Lab
    cat > "$HOMELAB_SSH_CONFIG" << EOF
# Configuration SSH Home Lab
# Généré automatiquement le $(date)

# Configuration globale Home Lab
Host homelab-*
    User homelab
    Port $ssh_port
    IdentityFile $ssh_key
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
    ConnectTimeout 10
    ServerAliveInterval 30
    ServerAliveCountMax 3

# Docker Host (PC Lenovo)
Host homelab-docker docker-host $docker_host_hostname
    HostName $docker_host_ip
    User $docker_host_user
    
# Home Assistant (Raspberry Pi)
Host homelab-ha homeassistant ha-host $ha_host_hostname
    HostName $ha_host_ip
    User $ha_host_user

# Alias pour accès rapide
Host hl-docker
    HostName $docker_host_ip
    User $docker_host_user
    
Host hl-ha
    HostName $ha_host_ip  
    User $ha_host_user
EOF

    success "Configuration SSH créée: $HOMELAB_SSH_CONFIG"
    
    # Intégration dans le fichier SSH config principal
    if [ ! -f "$SSH_CONFIG_FILE" ]; then
        touch "$SSH_CONFIG_FILE"
        chmod 600 "$SSH_CONFIG_FILE"
    fi
    
    # Vérifier si déjà inclus
    if ! grep -q "Include.*homelab_config" "$SSH_CONFIG_FILE"; then
        # Ajouter l'inclusion en haut du fichier
        local temp_config=$(mktemp)
        echo "# Home Lab Configuration" > "$temp_config"
        echo "Include ~/.ssh/homelab_config" >> "$temp_config"
        echo "" >> "$temp_config"
        cat "$SSH_CONFIG_FILE" >> "$temp_config"
        mv "$temp_config" "$SSH_CONFIG_FILE"
        
        success "Configuration Home Lab intégrée dans ~/.ssh/config"
    else
        info "Configuration Home Lab déjà présente dans ~/.ssh/config"
    fi
}

# Déploiement de la clé publique sur un host
deploy_ssh_key() {
    local host="$1"
    local user="$2"
    local key_file="$3"
    local password="$4"
    
    info "Déploiement de la clé SSH sur $user@$host..."
    
    local pub_key_file="${key_file}.pub"
    if [ ! -f "$pub_key_file" ]; then
        error "Clé publique non trouvée: $pub_key_file"
    fi
    
    local pub_key_content=$(cat "$pub_key_file")
    
    # Tentative avec ssh-copy-id si disponible
    if command -v ssh-copy-id &> /dev/null; then
        if [ -n "$password" ]; then
            # Utiliser sshpass si mot de passe fourni
            if command -v sshpass &> /dev/null; then
                info "Déploiement avec mot de passe..."
                if sshpass -p "$password" ssh-copy-id -i "$pub_key_file" -o StrictHostKeyChecking=no "$user@$host"; then
                    success "Clé déployée avec ssh-copy-id"
                    return 0
                fi
            fi
        else
            # Tentative sans mot de passe (clé existante ou agent SSH)
            if ssh-copy-id -i "$pub_key_file" -o StrictHostKeyChecking=no "$user@$host" 2>/dev/null; then
                success "Clé déployée avec ssh-copy-id"
                return 0
            fi
        fi
    fi
    
    # Méthode manuelle si ssh-copy-id échoue
    info "Déploiement manuel de la clé..."
    
    local ssh_opts="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"
    local ssh_cmd="ssh $ssh_opts"
    
    if [ -n "$password" ] && command -v sshpass &> /dev/null; then
        ssh_cmd="sshpass -p '$password' $ssh_cmd"
    fi
    
    local remote_cmd="
        mkdir -p ~/.ssh
        chmod 700 ~/.ssh
        touch ~/.ssh/authorized_keys
        chmod 600 ~/.ssh/authorized_keys
        if ! grep -q '$pub_key_content' ~/.ssh/authorized_keys; then
            echo '$pub_key_content' >> ~/.ssh/authorized_keys
            echo 'Clé ajoutée'
        else
            echo 'Clé déjà présente'
        fi
    "
    
    if eval "$ssh_cmd $user@$host '$remote_cmd'"; then
        success "Clé déployée manuellement"
        return 0
    else
        error "Échec du déploiement de la clé SSH"
    fi
}

# Test de connexion SSH
test_ssh_access() {
    local host="$1"
    local user="$2"
    local key_file="$3"
    
    info "Test de connexion SSH: $user@$host"
    
    if test_ssh_connection "$host" "$user" "$key_file"; then
        success "✅ Connexion SSH OK: $user@$host"
        
        # Test de sudo si possible
        local sudo_test=$(ssh_exec "$host" "$user" "sudo -n echo 'sudo OK' 2>/dev/null || echo 'sudo KO'" "$key_file")
        if [[ "$sudo_test" =~ "sudo OK" ]]; then
            success "✅ Accès sudo OK: $user@$host"
        else
            warn "⚠️ Accès sudo limité: $user@$host"
        fi
        
        return 0
    else
        error "❌ Connexion SSH échouée: $user@$host"
        return 1
    fi
}

# Configuration SSH interactive
interactive_ssh_setup() {
    local config_file="$1"
    
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}              CONFIGURATION SSH INTERACTIVE                      ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    
    # Chargement de la configuration
    load_config "$config_file"
    
    local ssh_key=$(get_nested_config "options.ssh_key_path" "~/.ssh/homelab_rsa")
    ssh_key=$(eval echo "$ssh_key")
    
    local docker_host_ip=$(get_nested_config "machines.docker_host.ip" "192.168.1.101")
    local docker_host_user=$(get_nested_config "machines.docker_host.user" "homelab")
    
    local ha_host_ip=$(get_nested_config "machines.homeassistant.ip" "192.168.1.100")
    local ha_host_user=$(get_nested_config "machines.homeassistant.user" "homelab")
    
    echo -e "${BLUE}Configuration détectée:${NC}"
    echo "  Clé SSH: $ssh_key"
    echo "  Docker Host: $docker_host_user@$docker_host_ip"
    echo "  Home Assistant: $ha_host_user@$ha_host_ip"
    echo
    
    # Génération ou utilisation de clé existante
    if [ ! -f "$ssh_key" ]; then
        echo -e "${YELLOW}Aucune clé SSH trouvée.${NC}"
        read -p "Générer une nouvelle clé SSH? [Y/n]: " -n 1 -r
        echo
        
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            generate_ssh_key "$ssh_key" "homelab@$(hostname)"
        else
            error "Clé SSH requise pour continuer"
        fi
    else
        info "Clé SSH existante trouvée: $ssh_key"
    fi
    
    # Configuration SSH
    setup_ssh_config "$config_file"
    
    # Déploiement des clés
    echo -e "${BLUE}Déploiement des clés SSH:${NC}"
    
    # Docker Host
    echo -e "${YELLOW}Configuration Docker Host ($docker_host_ip):${NC}"
    read -p "Mot de passe pour $docker_host_user (vide si clé déjà installée): " -s docker_password
    echo
    
    if ! test_ssh_connection "$docker_host_ip" "$docker_host_user" "$ssh_key"; then
        deploy_ssh_key "$docker_host_ip" "$docker_host_user" "$ssh_key" "$docker_password"
    fi
    
    test_ssh_access "$docker_host_ip" "$docker_host_user" "$ssh_key"
    
    # Home Assistant
    echo -e "${YELLOW}Configuration Home Assistant ($ha_host_ip):${NC}"
    read -p "Mot de passe pour $ha_host_user (vide si clé déjà installée): " -s ha_password
    echo
    
    if ! test_ssh_connection "$ha_host_ip" "$ha_host_user" "$ssh_key"; then
        deploy_ssh_key "$ha_host_ip" "$ha_host_user" "$ssh_key" "$ha_password"
    fi
    
    test_ssh_access "$ha_host_ip" "$ha_host_user" "$ssh_key"
    
    echo -e "${GREEN}Configuration SSH terminée!${NC}"
    echo
    echo -e "${BLUE}Connexions disponibles:${NC}"
    echo "  ssh homelab-docker    # Docker Host"
    echo "  ssh homelab-ha        # Home Assistant"  
    echo "  ssh hl-docker         # Raccourci Docker"
    echo "  ssh hl-ha             # Raccourci HA"
    echo
}

# Configuration SSH automatique
automatic_ssh_setup() {
    local config_file="$1"
    local discovery_results="$2"
    
    show_progress 2 "Configuration SSH" "IN_PROGRESS"
    
    load_config "$config_file"
    
    local ssh_key=$(get_nested_config "options.ssh_key_path" "~/.ssh/homelab_rsa")
    ssh_key=$(eval echo "$ssh_key")
    
    # Génération de clé si nécessaire
    if [ ! -f "$ssh_key" ]; then
        info "Génération de la clé SSH..."
        generate_ssh_key "$ssh_key" "homelab@$(hostname)"
    fi
    
    # Configuration SSH
    setup_ssh_config "$config_file"
    
    # Si résultats de découverte fournis, utiliser les informations détectées
    if [ -n "$discovery_results" ]; then
        local hosts=$(echo "$discovery_results" | jq -r '.hosts')
        local host_count=$(echo "$hosts" | jq '. | length')
        
        for ((i=0; i<host_count; i++)); do
            local host=$(echo "$hosts" | jq -r ".[$i]")
            local ip=$(echo "$host" | jq -r '.ip')
            local type=$(echo "$host" | jq -r '.type')
            local ssh_available=$(echo "$host" | jq -r '.ssh_available // false')
            local ssh_user=$(echo "$host" | jq -r '.ssh_user // "homelab"')
            
            if [ "$ssh_available" = "true" ] && [ "$type" != "router" ]; then
                info "Test de connexion SSH: $ssh_user@$ip"
                
                if ! test_ssh_connection "$ip" "$ssh_user" "$ssh_key"; then
                    warn "Accès SSH non configuré pour $ssh_user@$ip"
                    # En mode automatique, on ne peut pas demander de mot de passe
                    # L'utilisateur devra le faire manuellement
                fi
            fi
        done
    fi
    
    show_progress 2 "Configuration SSH" "DONE"
}

# Affichage des informations de connexion SSH
show_ssh_info() {
    local config_file="$1"
    
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                 INFORMATIONS CONNEXION SSH                     ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    
    if [ ! -f "$HOMELAB_SSH_CONFIG" ]; then
        warn "Configuration SSH Home Lab non trouvée"
        return 1
    fi
    
    echo -e "${BLUE}Fichier de configuration:${NC} $HOMELAB_SSH_CONFIG"
    echo -e "${BLUE}Intégration SSH config:${NC} $SSH_CONFIG_FILE"
    echo
    
    echo -e "${BLUE}Connexions disponibles:${NC}"
    
    # Extraire les hosts de la configuration
    local hosts=($(grep "^Host " "$HOMELAB_SSH_CONFIG" | grep -v "homelab-\*" | awk '{print $2}' | tr '\n' ' '))
    
    for host_alias in "${hosts[@]}"; do
        local host_info=$(ssh -G "$host_alias" 2>/dev/null | head -10)
        local hostname=$(echo "$host_info" | grep "^hostname " | awk '{print $2}')
        local user=$(echo "$host_info" | grep "^user " | awk '{print $2}')
        local port=$(echo "$host_info" | grep "^port " | awk '{print $2}')
        
        if [ -n "$hostname" ] && [ -n "$user" ]; then
            printf "  %-20s # %s@%s:%s\n" "ssh $host_alias" "$user" "$hostname" "$port"
        fi
    done
    
    echo
    
    # Test de connectivité
    echo -e "${BLUE}Test de connectivité:${NC}"
    
    for host_alias in "${hosts[@]}"; do
        if [[ "$host_alias" =~ ^(homelab-|hl-) ]]; then
            printf "  %-20s : " "$host_alias"
            
            if ssh -o ConnectTimeout=5 -o BatchMode=yes "$host_alias" "exit" 2>/dev/null; then
                echo -e "${GREEN}✅ OK${NC}"
            else
                echo -e "${RED}❌ Échec${NC}"
            fi
        fi
    done
    
    echo
}

# Fonction principale
main() {
    local config_file="${1:-../config.yml}"
    local mode="interactive"
    local discovery_results=""
    
    # Parsing des arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --config)
                config_file="$2"
                shift 2
                ;;
            --auto|--automatic)
                mode="automatic"
                shift
                ;;
            --interactive)
                mode="interactive"
                shift
                ;;
            --discovery)
                discovery_results="$2"
                shift 2
                ;;
            --info)
                mode="info"
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help)
                echo "Usage: $0 [options]"
                echo "Options:"
                echo "  --config FILE         Fichier de configuration"
                echo "  --interactive         Mode interactif (défaut)"
                echo "  --automatic           Mode automatique"
                echo "  --discovery RESULTS   Résultats de découverte réseau"
                echo "  --info                Afficher les infos SSH"
                echo "  --verbose             Mode verbeux"
                echo "  --help                Afficher cette aide"
                exit 0
                ;;
            *)
                config_file="$1"
                shift
                ;;
        esac
    done
    
    init_logging
    
    # Vérification des prérequis
    mkdir -p "$SSH_CONFIG_DIR"
    chmod 700 "$SSH_CONFIG_DIR"
    
    case "$mode" in
        "interactive")
            interactive_ssh_setup "$config_file"
            ;;
        "automatic")  
            automatic_ssh_setup "$config_file" "$discovery_results"
            ;;
        "info")
            show_ssh_info "$config_file"
            ;;
        *)
            error "Mode non supporté: $mode"
            ;;
    esac
    
    success "Configuration SSH terminée"
}

# Exécution si script appelé directement
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi