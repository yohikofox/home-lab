#!/bin/bash

# Vaultwarden Backup Script for N8N Integration
# Usage: ./vaultwarden_backup.sh [daily|weekly|monthly]

set -e

# Configuration
BACKUP_TYPE=${1:-"daily"}
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups/vaultwarden/${BACKUP_TYPE}"
CONTAINER_NAME="vaultwarden"
LOG_FILE="/backups/logs/backup_${DATE}.log"

# Create directories
mkdir -p "$BACKUP_DIR"
mkdir -p "/backups/logs"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "Starting $BACKUP_TYPE backup..."

# Check if Vaultwarden container is running
if ! docker ps --format "table {{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
    log "ERROR: Vaultwarden container not running"
    exit 1
fi

# SQLite backup
log "Creating SQLite backup..."
docker exec "$CONTAINER_NAME" sqlite3 /data/db.sqlite3 ".backup '/data/backup_${DATE}.sqlite3'"
docker cp "$CONTAINER_NAME:/data/backup_${DATE}.sqlite3" "$BACKUP_DIR/"

# Clean temporary file from container
docker exec "$CONTAINER_NAME" rm -f "/data/backup_${DATE}.sqlite3"

# Full data backup
log "Creating full backup archive..."
docker run --rm \
    -v vaultwarden_data:/data:ro \
    -v "$BACKUP_DIR:/backup" \
    alpine tar czf "/backup/vaultwarden_full_${DATE}.tar.gz" -C /data .

# Configuration backup
log "Backing up configuration..."
CONFIG_BACKUP_DIR="$BACKUP_DIR/configs"
mkdir -p "$CONFIG_BACKUP_DIR"

# Copy docker-compose and env files if they exist
if [ -f "/docker-compose/vaultwarden/docker-compose.yml" ]; then
    cp "/docker-compose/vaultwarden/docker-compose.yml" "$CONFIG_BACKUP_DIR/"
fi

if [ -f "/docker-compose/vaultwarden/.env" ]; then
    # Sanitize sensitive data
    sed 's/=.*/=***REDACTED***/' "/docker-compose/vaultwarden/.env" > "$CONFIG_BACKUP_DIR/env-template.txt"
fi

# Calculate backup sizes
SQLITE_SIZE=$(du -h "$BACKUP_DIR/backup_${DATE}.sqlite3" | cut -f1)
FULL_SIZE=$(du -h "$BACKUP_DIR/vaultwarden_full_${DATE}.tar.gz" | cut -f1)

log "Backup completed successfully"
log "SQLite backup size: $SQLITE_SIZE"
log "Full backup size: $FULL_SIZE"

# Return JSON for N8N processing
cat << EOF
{
  "success": true,
  "backup_type": "$BACKUP_TYPE",
  "timestamp": "$DATE",
  "sqlite_file": "$BACKUP_DIR/backup_${DATE}.sqlite3",
  "full_file": "$BACKUP_DIR/vaultwarden_full_${DATE}.tar.gz",
  "sqlite_size": "$SQLITE_SIZE",
  "full_size": "$FULL_SIZE",
  "log_file": "$LOG_FILE"
}
EOF