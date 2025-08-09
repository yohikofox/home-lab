#!/bin/bash

# Vaultwarden Health Check Script for N8N
# Usage: ./health_check.sh

set -e

VAULTWARDEN_URL=${VAULTWARDEN_URL:-"https://vault.yolo.yt"}
TIMEOUT=${TIMEOUT:-10}
LOG_FILE="/backups/logs/healthcheck_$(date +%Y%m%d).log"

# Create log directory
mkdir -p "/backups/logs"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Health check function
check_vaultwarden() {
    local url="$1"
    local response_code
    local response_time
    
    # Test the /alive endpoint
    if response=$(curl -s -w "%{http_code}:%{time_total}" --connect-timeout $TIMEOUT "$url/alive" 2>/dev/null); then
        response_code=$(echo "$response" | cut -d: -f1)
        response_time=$(echo "$response" | cut -d: -f2)
        
        if [ "$response_code" = "200" ]; then
            log "Health check PASSED - Response: $response_code, Time: ${response_time}s"
            return 0
        else
            log "Health check FAILED - Response code: $response_code"
            return 1
        fi
    else
        log "Health check FAILED - Cannot connect to $url"
        return 1
    fi
}

# Check container status
check_container() {
    if docker ps --format "table {{.Names}}" | grep -q "^vaultwarden$"; then
        local status=$(docker inspect --format='{{.State.Status}}' vaultwarden 2>/dev/null)
        log "Container status: $status"
        
        if [ "$status" = "running" ]; then
            return 0
        else
            log "Container is not running: $status"
            return 1
        fi
    else
        log "Vaultwarden container not found"
        return 1
    fi
}

# Main health check
log "Starting health check..."

CONTAINER_OK=false
HTTP_OK=false

# Check container
if check_container; then
    CONTAINER_OK=true
fi

# Check HTTP endpoint
if check_vaultwarden "$VAULTWARDEN_URL"; then
    HTTP_OK=true
fi

# Generate result
if $CONTAINER_OK && $HTTP_OK; then
    STATUS="healthy"
    SEVERITY="info"
    MESSAGE="Vaultwarden is running normally"
    EXIT_CODE=0
elif $CONTAINER_OK && ! $HTTP_OK; then
    STATUS="degraded"
    SEVERITY="warning"
    MESSAGE="Container running but HTTP endpoint not responding"
    EXIT_CODE=1
elif ! $CONTAINER_OK && $HTTP_OK; then
    STATUS="critical"
    SEVERITY="error" 
    MESSAGE="HTTP responding but container issues detected"
    EXIT_CODE=2
else
    STATUS="down"
    SEVERITY="critical"
    MESSAGE="Vaultwarden is completely down"
    EXIT_CODE=3
fi

log "Health check completed - Status: $STATUS"

# Return JSON for N8N
cat << EOF
{
  "status": "$STATUS",
  "severity": "$SEVERITY",
  "message": "$MESSAGE",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "checks": {
    "container": $CONTAINER_OK,
    "http": $HTTP_OK
  },
  "url": "$VAULTWARDEN_URL",
  "log_file": "$LOG_FILE"
}
EOF

exit $EXIT_CODE