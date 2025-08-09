#!/bin/bash

# Audit complet de la configuration réseau actuelle
# Usage: ./current-audit.sh [--output audit-results.json]

set -e

# Chargement des fonctions communes
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../install/common.sh"

OUTPUT_FILE="audit-$(date +%Y%m%d-%H%M%S).json"

# Audit de la configuration réseau actuelle
audit_network_config() {
    info "Audit de la configuration réseau..."
    
    local network_info="{}"
    
    # Interface réseau principale
    local default_route=$(ip route | grep '^default' | head -1)
    local interface=$(echo "$default_route" | awk '{print $5}')
    local gateway=$(echo "$default_route" | awk '{print $3}')
    
    # Information IP locale
    local ip_info=$(ip addr show "$interface" | grep 'inet ' | head -1)
    local local_ip=$(echo "$ip_info" | awk '{print $2}' | cut -d'/' -f1)
    local subnet=$(echo "$ip_info" | awk '{print $2}')
    
    # DNS configuré
    local dns_servers=$(grep "^nameserver" /etc/resolv.conf | awk '{print $2}' | tr '\n' ',' | sed 's/,$//')
    
    network_info=$(jq -n \
        --arg interface "$interface" \
        --arg local_ip "$local_ip" \
        --arg gateway "$gateway" \
        --arg subnet "$subnet" \
        --arg dns_servers "$dns_servers" \
        '{
            interface: $interface,
            local_ip: $local_ip,
            gateway: $gateway,
            subnet: $subnet,
            dns_servers: ($dns_servers | split(","))
        }')
    
    echo "$network_info"
}

# Audit des services Docker
audit_docker_services() {
    info "Audit des services Docker..."
    
    if ! command -v docker &> /dev/null; then
        warn "Docker non installé"
        echo "null"
        return
    fi
    
    local services=[]
    
    # Liste des containers
    local containers=$(docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | tail -n +2)
    
    while IFS=$'\t' read -r name image status ports; do
        if [ -n "$name" ]; then
            # Nettoyage des ports
            local clean_ports=$(echo "$ports" | sed 's/[0-9.]*://g' | sed 's/->[^,]*//g')
            
            services=$(echo "$services" | jq '. += [{
                name: "'$name'",
                image: "'$image'", 
                status: "'$status'",
                ports: "'$clean_ports'"
            }]')
        fi
    done <<< "$containers"
    
    # Docker Compose projects
    local compose_projects=[]
    if command -v docker-compose &> /dev/null || docker compose version &> /dev/null 2>&1; then
        # Recherche des fichiers docker-compose
        local compose_files=($(find /home -name "docker-compose.yml" 2>/dev/null | head -10))
        
        for file in "${compose_files[@]}"; do
            local project_dir=$(dirname "$file")
            local project_name=$(basename "$project_dir")
            
            compose_projects=$(echo "$compose_projects" | jq '. += [{
                name: "'$project_name'",
                path: "'$project_dir'",
                file: "'$file'"
            }]')
        done
    fi
    
    # Volumes Docker
    local volumes=[]
    if docker volume ls &> /dev/null; then
        local volume_list=$(docker volume ls --format "table {{.Name}}\t{{.Driver}}" | tail -n +2)
        
        while IFS=$'\t' read -r name driver; do
            if [ -n "$name" ]; then
                volumes=$(echo "$volumes" | jq '. += [{
                    name: "'$name'",
                    driver: "'$driver'"
                }]')
            fi
        done <<< "$volume_list"
    fi
    
    # Réseaux Docker
    local networks=[]
    if docker network ls &> /dev/null; then
        local network_list=$(docker network ls --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}" | tail -n +2)
        
        while IFS=$'\t' read -r name driver scope; do
            if [ -n "$name" ] && [ "$name" != "bridge" ] && [ "$name" != "host" ] && [ "$name" != "none" ]; then
                networks=$(echo "$networks" | jq '. += [{
                    name: "'$name'",
                    driver: "'$driver'",
                    scope: "'$scope'"
                }]')
            fi
        done <<< "$network_list"
    fi
    
    jq -n \
        --argjson services "$services" \
        --argjson compose_projects "$compose_projects" \
        --argjson volumes "$volumes" \
        --argjson networks "$networks" \
        '{
            services: $services,
            compose_projects: $compose_projects,
            volumes: $volumes,
            networks: $networks
        }'
}

# Audit Home Assistant (si accessible)
audit_homeassistant() {
    info "Audit Home Assistant..."
    
    local ha_info="null"
    
    # Recherche d'instances HA sur le réseau
    local ha_hosts=($(nmap -p 8123 192.168.1.0/24 2>/dev/null | grep -B1 "8123/tcp open" | grep "Nmap scan report" | awk '{print $NF}' | tr -d '()'))
    
    if [ ${#ha_hosts[@]} -gt 0 ]; then
        local ha_host="${ha_hosts[0]}"
        
        # Test d'accès à l'API HA
        local ha_api_test=$(curl -s --connect-timeout 5 "http://$ha_host:8123/api/" || echo "")
        
        if [[ "$ha_api_test" =~ "requires_auth" ]]; then
            ha_info=$(jq -n \
                --arg host "$ha_host" \
                --arg port "8123" \
                --arg status "accessible" \
                '{
                    host: $host,
                    port: ($port | tonumber),
                    status: $status,
                    api_accessible: true
                }')
        fi
    fi
    
    echo "$ha_info"
}

# Audit des certificats SSL
audit_ssl_certificates() {
    info "Audit des certificats SSL..."
    
    local certs=[]
    
    # Recherche des certificats Let's Encrypt
    local letsencrypt_dirs=(
        "/etc/letsencrypt/live"
        "/home/*/letsencrypt"
        "/opt/letsencrypt"
        "/var/lib/docker/volumes"
    )
    
    for dir in "${letsencrypt_dirs[@]}"; do
        if [ -d "$dir" ]; then
            local cert_dirs=$(find "$dir" -name "*.pem" -o -name "fullchain.pem" 2>/dev/null | head -10)
            
            for cert_file in $cert_dirs; do
                if [ -f "$cert_file" ]; then
                    local cert_info=$(openssl x509 -in "$cert_file" -text -noout 2>/dev/null | grep -E "(Subject:|Not After)" || echo "")
                    
                    if [ -n "$cert_info" ]; then
                        local subject=$(echo "$cert_info" | grep "Subject:" | sed 's/.*CN = *//' | sed 's/,.*//')
                        local expiry=$(echo "$cert_info" | grep "Not After" | sed 's/.*Not After : *//')
                        
                        certs=$(echo "$certs" | jq '. += [{
                            subject: "'$subject'",
                            file: "'$cert_file'",
                            expiry: "'$expiry'"
                        }]')
                    fi
                fi
            done
        fi
    done
    
    echo "$certs"
}

# Audit des domaines configurés
audit_domains() {
    info "Audit des domaines..."
    
    local domains=[]
    
    # Recherche dans les configurations nginx
    local nginx_configs=($(find /etc/nginx /opt/nginx /home/*/nginx 2>/dev/null -name "*.conf" | head -20))
    
    for config in "${nginx_configs[@]}"; do
        if [ -f "$config" ]; then
            local server_names=$(grep -i "server_name" "$config" | sed 's/.*server_name *//' | sed 's/;.*//' | tr ' ' '\n' | grep -v "^$")
            
            for domain in $server_names; do
                if [[ "$domain" =~ \. ]] && [ "$domain" != "_" ]; then
                    domains=$(echo "$domains" | jq '. += [{"domain": "'$domain'", "source": "'$config'"}]')
                fi
            done
        fi
    done
    
    # Recherche dans les configurations Docker
    local docker_env_files=($(find /home -name ".env" -o -name "docker-compose.yml" 2>/dev/null | head -20))
    
    for file in "${docker_env_files[@]}"; do
        if [ -f "$file" ]; then
            local domain_refs=$(grep -i "domain\|host" "$file" | grep "yolo.yt" | head -5)
            
            while IFS= read -r line; do
                if [ -n "$line" ]; then
                    local domain=$(echo "$line" | grep -o '[a-zA-Z0-9.-]*\.yolo\.yt' | head -1)
                    if [ -n "$domain" ]; then
                        domains=$(echo "$domains" | jq '. += [{"domain": "'$domain'", "source": "'$file'"}]')
                    fi
                fi
            done <<< "$domain_refs"
        fi
    done
    
    echo "$domains"
}

# Audit des ports forwarding
audit_port_forwarding() {
    info "Audit du port forwarding..."
    
    local port_info=[]
    
    # Test des ports ouverts depuis l'extérieur (si possible)
    local common_ports=(80 443 22 8123 9000 5678)
    local gateway=$(ip route | grep '^default' | awk '{print $3}')
    
    for port in "${common_ports[@]}"; do
        # Test de connectivité locale
        if timeout 2 bash -c "</dev/tcp/$gateway/$port" 2>/dev/null; then
            port_info=$(echo "$port_info" | jq '. += [{
                port: '$port',
                status: "open_local",
                target: "'$gateway'"
            }]')
        fi
    done
    
    echo "$port_info"
}

# Génération du rapport complet
generate_audit_report() {
    local output_file="$1"
    
    show_progress 1 "Audit réseau" "IN_PROGRESS"
    local network=$(audit_network_config)
    show_progress 1 "Audit réseau" "DONE"
    
    show_progress 2 "Audit Docker" "IN_PROGRESS"  
    local docker=$(audit_docker_services)
    show_progress 2 "Audit Docker" "DONE"
    
    show_progress 3 "Audit Home Assistant" "IN_PROGRESS"
    local homeassistant=$(audit_homeassistant)
    show_progress 3 "Audit Home Assistant" "DONE"
    
    show_progress 4 "Audit certificats SSL" "IN_PROGRESS"
    local ssl_certs=$(audit_ssl_certificates)
    show_progress 4 "Audit certificats SSL" "DONE"
    
    show_progress 5 "Audit domaines" "IN_PROGRESS"
    local domains=$(audit_domains) 
    show_progress 5 "Audit domaines" "DONE"
    
    show_progress 6 "Audit port forwarding" "IN_PROGRESS"
    local ports=$(audit_port_forwarding)
    show_progress 6 "Audit port forwarding" "DONE"
    
    # Compilation du rapport final
    local audit_report=$(jq -n \
        --argjson network "$network" \
        --argjson docker "$docker" \
        --argjson homeassistant "$homeassistant" \
        --argjson ssl_certs "$ssl_certs" \
        --argjson domains "$domains" \
        --argjson ports "$ports" \
        '{
            timestamp: now,
            hostname: "'$(hostname)'",
            audit: {
                network: $network,
                docker: $docker,
                homeassistant: $homeassistant,
                ssl_certificates: $ssl_certs,
                domains: $domains,
                port_forwarding: $ports
            }
        }')
    
    # Sauvegarde du rapport
    echo "$audit_report" | jq '.' > "$output_file"
    
    success "Rapport d'audit sauvegardé: $output_file"
    
    echo "$audit_report"
}

# Affichage du rapport d'audit
display_audit_report() {
    local report="$1"
    
    echo
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}              RAPPORT D'AUDIT - CONFIGURATION ACTUELLE          ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    
    local timestamp=$(echo "$report" | jq -r '.timestamp')
    local hostname=$(echo "$report" | jq -r '.hostname')
    
    echo -e "${BLUE}Machine auditée:${NC} $hostname"
    echo -e "${BLUE}Date d'audit:${NC} $(date -d "@$timestamp" 2>/dev/null || date)"
    echo
    
    # Configuration réseau
    echo -e "${BLUE}📡 Configuration réseau:${NC}"
    local network=$(echo "$report" | jq -r '.audit.network')
    local interface=$(echo "$network" | jq -r '.interface')
    local local_ip=$(echo "$network" | jq -r '.local_ip')
    local gateway=$(echo "$network" | jq -r '.gateway')
    local subnet=$(echo "$network" | jq -r '.subnet')
    
    echo "  Interface: $interface"
    echo "  IP locale: $local_ip"
    echo "  Passerelle: $gateway"
    echo "  Sous-réseau: $subnet"
    echo
    
    # Services Docker
    echo -e "${BLUE}🐳 Services Docker:${NC}"
    local docker_services=$(echo "$report" | jq -r '.audit.docker.services[]? | "\(.name) (\(.image)) - \(.status)"')
    
    if [ -n "$docker_services" ]; then
        echo "$docker_services" | while read -r service; do
            echo "  • $service"
        done
    else
        echo "  Aucun service Docker trouvé"
    fi
    echo
    
    # Home Assistant
    echo -e "${BLUE}🏠 Home Assistant:${NC}"
    local ha_info=$(echo "$report" | jq -r '.audit.homeassistant')
    if [ "$ha_info" != "null" ]; then
        local ha_host=$(echo "$ha_info" | jq -r '.host')
        local ha_status=$(echo "$ha_info" | jq -r '.status')
        echo "  Host: $ha_host:8123"
        echo "  Status: $ha_status"
    else
        echo "  Home Assistant non détecté"
    fi
    echo
    
    # Domaines configurés
    echo -e "${BLUE}🌐 Domaines configurés:${NC}"
    local domains=$(echo "$report" | jq -r '.audit.domains[]?.domain' | sort -u)
    
    if [ -n "$domains" ]; then
        echo "$domains" | while read -r domain; do
            echo "  • $domain"
        done
    else
        echo "  Aucun domaine trouvé"
    fi
    echo
    
    # Certificats SSL
    echo -e "${BLUE}🔒 Certificats SSL:${NC}"
    local certs=$(echo "$report" | jq -r '.audit.ssl_certificates[]? | "\(.subject) (expire: \(.expiry))"')
    
    if [ -n "$certs" ]; then
        echo "$certs" | while read -r cert; do
            echo "  • $cert"
        done
    else
        echo "  Aucun certificat trouvé"
    fi
    echo
}

# Fonction principale
main() {
    local output_file="$OUTPUT_FILE"
    
    # Parsing des arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --output)
                output_file="$2"
                shift 2
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help)
                echo "Usage: $0 [options]"
                echo "Options:"
                echo "  --output FILE     Fichier de sortie (défaut: audit-timestamp.json)"
                echo "  --verbose         Mode verbeux"
                echo "  --help            Afficher cette aide"
                exit 0
                ;;
            *)
                shift
                ;;
        esac
    done
    
    init_logging
    check_prerequisites
    
    info "Début de l'audit de configuration actuelle"
    
    # Génération du rapport
    local report=$(generate_audit_report "$output_file")
    
    # Affichage du rapport
    display_audit_report "$report"
    
    success "Audit terminé - Rapport sauvegardé: $output_file"
}

# Exécution si script appelé directement
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi