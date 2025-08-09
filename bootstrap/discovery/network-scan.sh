#!/bin/bash

# Script de découverte réseau pour l'installation bootstrap
# Usage: ./network-scan.sh [config.yml]

set -e

# Chargement des fonctions communes
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../install/common.sh"

# Configuration par défaut
DEFAULT_CONFIG="$SCRIPT_DIR/../config.yml"
NETWORK_CACHE="$HOME/.homelab/cache/network-scan.json"

# Fonctions de découverte réseau

# Détection du réseau local
detect_local_network() {
    info "Détection du réseau local..."
    
    # Obtenir l'interface réseau principale
    local default_route=$(ip route | grep '^default' | head -1)
    local interface=$(echo "$default_route" | awk '{print $5}')
    local gateway=$(echo "$default_route" | awk '{print $3}')
    
    if [ -z "$interface" ] || [ -z "$gateway" ]; then
        # Fallback sur d'autres méthodes
        interface=$(ip route | grep -E '192\.168\.|10\.|172\.' | head -1 | awk '{print $3}' | head -1)
        gateway=$(ip route | grep -E '192\.168\.|10\.|172\.' | head -1 | awk '{print $1}' | sed 's|/.*||')
    fi
    
    # Obtenir l'adresse IP et le masque
    local ip_info=$(ip addr show "$interface" | grep 'inet ' | head -1)
    local local_ip=$(echo "$ip_info" | awk '{print $2}' | cut -d'/' -f1)
    local subnet=$(echo "$ip_info" | awk '{print $2}')
    
    debug "Interface: $interface"
    debug "IP locale: $local_ip"
    debug "Passerelle: $gateway"  
    debug "Sous-réseau: $subnet"
    
    # Retourner les informations réseau
    jq -n \
        --arg interface "$interface" \
        --arg local_ip "$local_ip" \
        --arg gateway "$gateway" \
        --arg subnet "$subnet" \
        '{
            interface: $interface,
            local_ip: $local_ip,
            gateway: $gateway,
            subnet: $subnet
        }'
}

# Scan des hosts actifs sur le réseau
scan_network_hosts() {
    local subnet="$1"
    info "Scan des hosts sur $subnet..."
    
    local hosts_found=()
    local scan_results=$(nmap -sn "$subnet" 2>/dev/null | grep -E "Nmap scan report|MAC Address")
    
    local current_ip=""
    local current_mac=""
    local current_hostname=""
    
    while IFS= read -r line; do
        if [[ "$line" =~ "Nmap scan report for" ]]; then
            # Sauvegarder le host précédent s'il existe
            if [ -n "$current_ip" ]; then
                hosts_found+=("$current_ip|$current_mac|$current_hostname")
            fi
            
            # Nouveau host
            if [[ "$line" =~ \(([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\) ]]; then
                current_hostname=$(echo "$line" | sed 's/.*for \(.*\) (.*/\1/')
                current_ip="${BASH_REMATCH[1]}"
            else
                current_ip=$(echo "$line" | awk '{print $NF}')
                current_hostname=""
            fi
            current_mac=""
            
        elif [[ "$line" =~ "MAC Address:" ]]; then
            current_mac=$(echo "$line" | sed 's/.*MAC Address: \([^ ]*\).*/\1/')
        fi
    done <<< "$scan_results"
    
    # Ajouter le dernier host
    if [ -n "$current_ip" ]; then
        hosts_found+=("$current_ip|$current_mac|$current_hostname")
    fi
    
    # Convertir en JSON
    local hosts_json="[]"
    for host_info in "${hosts_found[@]}"; do
        IFS='|' read -r ip mac hostname <<< "$host_info"
        hosts_json=$(echo "$hosts_json" | jq '. += [{
            ip: "'$ip'",
            mac: "'$mac'",
            hostname: "'$hostname'",
            online: true
        }]')
    done
    
    echo "$hosts_json"
}

# Identification des services sur un host
identify_services() {
    local ip="$1"
    debug "Identification des services sur $ip..."
    
    local services=[]
    
    # Scan des ports courants
    local common_ports="22,80,443,8123,9000,19999,5678,81"
    local port_scan=$(nmap -Pn -p "$common_ports" "$ip" 2>/dev/null | grep "open")
    
    while IFS= read -r line; do
        if [[ "$line" =~ ([0-9]+)/tcp.*open ]]; then
            local port="${BASH_REMATCH[1]}"
            local service=""
            
            # Identifier le service selon le port
            case "$port" in
                22)    service="SSH" ;;
                80)    service="HTTP" ;;
                443)   service="HTTPS" ;;
                8123)  service="Home Assistant" ;;
                9000)  service="Portainer" ;;
                19999) service="Netdata" ;;
                5678)  service="N8N" ;;
                81)    service="Nginx Proxy Manager" ;;
                *)     service="Unknown" ;;
            esac
            
            services=$(echo "$services" | jq '. += [{
                port: '$port',
                service: "'$service'",
                state: "open"
            }]')
        fi
    done <<< "$port_scan"
    
    echo "$services"
}

# Identification du type de machine
identify_machine_type() {
    local ip="$1"
    local hostname="$2"
    local services="$3"
    
    local machine_type="unknown"
    local confidence=0
    
    # Analyse basée sur le hostname
    if [[ "$hostname" =~ homeassistant|hass|rpi ]]; then
        machine_type="homeassistant"
        confidence=$((confidence + 50))
    elif [[ "$hostname" =~ lenovo|docker|server ]]; then
        machine_type="docker_host"
        confidence=$((confidence + 30))
    fi
    
    # Analyse basée sur les services détectés
    local has_hass=$(echo "$services" | jq '.[] | select(.port == 8123)' | wc -l)
    local has_portainer=$(echo "$services" | jq '.[] | select(.port == 9000)' | wc -l)
    local has_npm=$(echo "$services" | jq '.[] | select(.port == 81)' | wc -l)
    
    if [ "$has_hass" -gt 0 ]; then
        machine_type="homeassistant"
        confidence=$((confidence + 70))
    elif [ "$has_portainer" -gt 0 ] || [ "$has_npm" -gt 0 ]; then
        machine_type="docker_host" 
        confidence=$((confidence + 60))
    fi
    
    # Vérification SSH
    local ssh_available=$(echo "$services" | jq '.[] | select(.port == 22)' | wc -l)
    if [ "$ssh_available" -gt 0 ]; then
        confidence=$((confidence + 20))
    fi
    
    echo "$machine_type"
}

# Test de connectivité SSH sur les hosts trouvés
test_ssh_connectivity() {
    local hosts_json="$1"
    local ssh_key="$2"
    local ssh_user="${3:-homelab}"
    
    info "Test de connectivité SSH..."
    
    local updated_hosts="$hosts_json"
    local host_count=$(echo "$hosts_json" | jq '. | length')
    
    for ((i=0; i<host_count; i++)); do
        local host=$(echo "$hosts_json" | jq -r ".[$i]")
        local ip=$(echo "$host" | jq -r '.ip')
        local hostname=$(echo "$host" | jq -r '.hostname')
        
        debug "Test SSH sur $ip ($hostname)..."
        
        local ssh_available=false
        local ssh_user_found=""
        
        # Test avec différents utilisateurs courants
        local test_users=("$ssh_user" "homelab" "pi" "ubuntu" "debian" "admin")
        
        for user in "${test_users[@]}"; do
            if test_ssh_connection "$ip" "$user" "$ssh_key"; then
                ssh_available=true
                ssh_user_found="$user"
                debug "SSH OK: $user@$ip"
                break
            fi
        done
        
        # Mettre à jour les informations SSH dans le JSON
        updated_hosts=$(echo "$updated_hosts" | jq ".[$i] += {
            ssh_available: $ssh_available,
            ssh_user: \"$ssh_user_found\"
        }")
    done
    
    echo "$updated_hosts"
}

# Analyse complète d'un réseau
perform_network_discovery() {
    local config_file="$1"
    
    show_progress 1 "Découverte réseau" "IN_PROGRESS"
    
    # Chargement de la configuration
    load_config "$config_file"
    
    # Détection du réseau local
    local network_info=$(detect_local_network)
    local subnet=$(echo "$network_info" | jq -r '.subnet')
    local gateway=$(echo "$network_info" | jq -r '.gateway')
    
    info "Réseau détecté: $subnet (passerelle: $gateway)"
    
    # Scan des hosts
    local hosts=$(scan_network_hosts "$subnet")
    local host_count=$(echo "$hosts" | jq '. | length')
    info "$host_count hosts trouvés"
    
    # Enrichissement des informations pour chaque host
    local enriched_hosts="$hosts"
    
    for ((i=0; i<host_count; i++)); do
        local host=$(echo "$hosts" | jq -r ".[$i]")
        local ip=$(echo "$host" | jq -r '.ip')
        local hostname=$(echo "$host" | jq -r '.hostname')
        
        # Skip de la passerelle
        if [ "$ip" = "$gateway" ]; then
            enriched_hosts=$(echo "$enriched_hosts" | jq ".[$i] += {
                type: \"router\",
                services: []
            }")
            continue
        fi
        
        debug "Analyse de $ip ($hostname)..."
        
        # Scan des services
        local services=$(identify_services "$ip")
        
        # Identification du type de machine
        local machine_type=$(identify_machine_type "$ip" "$hostname" "$services")
        
        # Mise à jour du JSON
        enriched_hosts=$(echo "$enriched_hosts" | jq ".[$i] += {
            type: \"$machine_type\",
            services: $services
        }")
    done
    
    # Test SSH
    local ssh_key=$(get_nested_config "options.ssh_key_path" "~/.ssh/id_rsa")
    ssh_key=$(eval echo "$ssh_key")
    
    if [ -f "$ssh_key" ]; then
        enriched_hosts=$(test_ssh_connectivity "$enriched_hosts" "$ssh_key")
    else
        warn "Clé SSH non trouvée: $ssh_key"
    fi
    
    # Compilation du résultat final
    local discovery_result=$(jq -n \
        --argjson network "$network_info" \
        --argjson hosts "$enriched_hosts" \
        '{
            timestamp: now,
            network: $network,
            hosts: $hosts,
            summary: {
                total_hosts: ($hosts | length),
                ssh_ready: ($hosts | map(select(.ssh_available == true)) | length),
                docker_hosts: ($hosts | map(select(.type == "docker_host")) | length),
                homeassistant_hosts: ($hosts | map(select(.type == "homeassistant")) | length)
            }
        }')
    
    show_progress 1 "Découverte réseau" "DONE"
    
    echo "$discovery_result"
}

# Mise en cache des résultats
cache_discovery_results() {
    local results="$1"
    
    mkdir -p "$(dirname "$NETWORK_CACHE")"
    echo "$results" > "$NETWORK_CACHE"
    
    debug "Résultats mis en cache: $NETWORK_CACHE"
}

# Chargement depuis le cache
load_cached_results() {
    if [ -f "$NETWORK_CACHE" ]; then
        local cache_age=$(($(date +%s) - $(stat -f %m "$NETWORK_CACHE" 2>/dev/null || stat -c %Y "$NETWORK_CACHE" 2>/dev/null || echo 0)))
        
        # Cache valide pour 1 heure
        if [ $cache_age -lt 3600 ]; then
            debug "Chargement depuis le cache (âge: ${cache_age}s)"
            cat "$NETWORK_CACHE"
            return 0
        fi
    fi
    
    return 1
}

# Affichage des résultats de découverte
display_discovery_results() {
    local results="$1"
    
    echo
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                    RÉSULTATS DE DÉCOUVERTE RÉSEAU               ${NC}"  
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    
    # Informations réseau
    local network=$(echo "$results" | jq -r '.network')
    local subnet=$(echo "$network" | jq -r '.subnet')
    local gateway=$(echo "$network" | jq -r '.gateway')
    local interface=$(echo "$network" | jq -r '.interface')
    
    echo -e "${BLUE}Réseau:${NC}"
    echo "  Interface: $interface"
    echo "  Sous-réseau: $subnet"
    echo "  Passerelle: $gateway"
    echo
    
    # Statistiques
    local summary=$(echo "$results" | jq -r '.summary')
    local total=$(echo "$summary" | jq -r '.total_hosts')
    local ssh_ready=$(echo "$summary" | jq -r '.ssh_ready')
    local docker_hosts=$(echo "$summary" | jq -r '.docker_hosts')  
    local ha_hosts=$(echo "$summary" | jq -r '.homeassistant_hosts')
    
    echo -e "${BLUE}Statistiques:${NC}"
    echo "  Hosts trouvés: $total"
    echo "  SSH disponible: $ssh_ready"
    echo "  Docker hosts: $docker_hosts"
    echo "  Home Assistant: $ha_hosts"
    echo
    
    # Liste des hosts
    echo -e "${BLUE}Hosts découverts:${NC}"
    
    local hosts=$(echo "$results" | jq -r '.hosts')
    local host_count=$(echo "$hosts" | jq '. | length')
    
    printf "%-15s %-20s %-15s %-10s %-20s %s\n" "IP" "Hostname" "Type" "SSH" "MAC" "Services"
    echo "────────────────────────────────────────────────────────────────────────────────────"
    
    for ((i=0; i<host_count; i++)); do
        local host=$(echo "$hosts" | jq -r ".[$i]")
        local ip=$(echo "$host" | jq -r '.ip')
        local hostname=$(echo "$host" | jq -r '.hostname // "N/A"')
        local type=$(echo "$host" | jq -r '.type')
        local mac=$(echo "$host" | jq -r '.mac // "N/A"')
        local ssh_status=$(echo "$host" | jq -r '.ssh_available // false')
        local ssh_user=$(echo "$host" | jq -r '.ssh_user // "N/A"')
        
        # Couleur selon le type
        local type_color="$NC"
        case "$type" in
            "docker_host")     type_color="$GREEN" ;;
            "homeassistant")   type_color="$PURPLE" ;;
            "router")          type_color="$BLUE" ;;
            *)                 type_color="$YELLOW" ;;
        esac
        
        # Statut SSH
        local ssh_display=""
        if [ "$ssh_status" = "true" ]; then
            ssh_display="${GREEN}✅ $ssh_user${NC}"
        else
            ssh_display="${RED}❌ N/A${NC}"
        fi
        
        # Services
        local services_list=$(echo "$host" | jq -r '.services[]?.service // empty' | tr '\n' ',' | sed 's/,$//')
        
        printf "%-15s %-20s ${type_color}%-15s${NC} %-18s %-20s %s\n" \
            "$ip" "$hostname" "$type" "$ssh_display" "$mac" "$services_list"
    done
    
    echo
}

# Recommandations basées sur la découverte
show_recommendations() {
    local results="$1"
    local config_file="$2"
    
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                        RECOMMANDATIONS                          ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    
    local hosts=$(echo "$results" | jq -r '.hosts')
    local docker_hosts=$(echo "$hosts" | jq '.[] | select(.type == "docker_host")')
    local ha_hosts=$(echo "$hosts" | jq '.[] | select(.type == "homeassistant")')
    
    # Vérifier si les machines attendues sont trouvées
    local expected_docker_ip=$(get_nested_config "machines.docker_host.ip" "")
    local expected_ha_ip=$(get_nested_config "machines.homeassistant.ip" "")
    
    if [ -n "$expected_docker_ip" ]; then
        local found_docker=$(echo "$hosts" | jq ".[] | select(.ip == \"$expected_docker_ip\")")
        if [ -n "$found_docker" ]; then
            success "✅ Docker host trouvé à l'IP configurée: $expected_docker_ip"
        else
            warn "⚠️ Docker host non trouvé à l'IP configurée: $expected_docker_ip"
            
            # Suggérer des alternatives
            local docker_candidates=$(echo "$hosts" | jq -r '.[] | select(.type == "docker_host" or (.services[]?.port == 9000)) | .ip')
            if [ -n "$docker_candidates" ]; then
                echo "  Candidats Docker host trouvés:"
                echo "$docker_candidates" | while read ip; do
                    echo "    - $ip"
                done
            fi
        fi
    fi
    
    if [ -n "$expected_ha_ip" ]; then
        local found_ha=$(echo "$hosts" | jq ".[] | select(.ip == \"$expected_ha_ip\")")
        if [ -n "$found_ha" ]; then
            success "✅ Home Assistant trouvé à l'IP configurée: $expected_ha_ip"
        else
            warn "⚠️ Home Assistant non trouvé à l'IP configurée: $expected_ha_ip"
            
            local ha_candidates=$(echo "$hosts" | jq -r '.[] | select(.type == "homeassistant" or (.services[]?.port == 8123)) | .ip')
            if [ -n "$ha_candidates" ]; then
                echo "  Candidats Home Assistant trouvés:"
                echo "$ha_candidates" | while read ip; do
                    echo "    - $ip"
                done
            fi
        fi
    fi
    
    # Recommandations SSH
    local hosts_no_ssh=$(echo "$hosts" | jq '.[] | select(.ssh_available != true and .type != "router")')
    if [ -n "$hosts_no_ssh" ] && [ "$hosts_no_ssh" != "null" ]; then
        warn "⚠️ Hosts sans accès SSH:"
        echo "$hosts_no_ssh" | jq -r '.ip' | while read ip; do
            echo "  - $ip : Configurez SSH ou vérifiez les clés"
        done
    fi
    
    # Prochaines étapes recommandées
    echo
    echo -e "${BLUE}Prochaines étapes recommandées:${NC}"
    
    if [ -f "$config_file" ]; then
        echo "1. Vérifiez la configuration dans: $config_file"
        echo "2. Ajustez les IPs si nécessaire"
    else
        echo "1. Copiez config.yml.example vers config.yml"
        echo "2. Adaptez les IPs découvertes dans la configuration"
    fi
    
    echo "3. Configurez SSH sur les machines cibles"
    echo "4. Lancez l'installation: ./deploy.sh --config config.yml"
    
    echo
}

# Fonction principale
main() {
    local config_file="${1:-$DEFAULT_CONFIG}"
    local use_cache=true
    local force_refresh=false
    
    # Parsing des arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --no-cache)
                use_cache=false
                shift
                ;;
            --refresh)
                force_refresh=true
                use_cache=false
                shift
                ;;
            --config)
                config_file="$2"
                shift 2
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help)
                echo "Usage: $0 [options] [config.yml]"
                echo "Options:"
                echo "  --no-cache    Ne pas utiliser le cache"
                echo "  --refresh     Forcer le refresh du cache"
                echo "  --config FILE Fichier de configuration"
                echo "  --verbose     Mode verbeux"
                echo "  --help        Afficher cette aide"
                exit 0
                ;;
            *)
                config_file="$1"
                shift
                ;;
        esac
    done
    
    init_logging
    check_prerequisites
    
    info "Début de la découverte réseau"
    
    # Tentative de chargement depuis le cache
    local results=""
    if [ "$use_cache" = true ] && [ "$force_refresh" = false ]; then
        results=$(load_cached_results || echo "")
    fi
    
    # Si pas de cache ou force refresh
    if [ -z "$results" ]; then
        results=$(perform_network_discovery "$config_file")
        cache_discovery_results "$results"
    else
        info "Utilisation des résultats en cache"
    fi
    
    # Affichage des résultats
    display_discovery_results "$results"
    show_recommendations "$results" "$config_file"
    
    success "Découverte réseau terminée"
}

# Exécution si script appelé directement
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi