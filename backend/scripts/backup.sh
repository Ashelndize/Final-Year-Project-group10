#!/usr/bin/env bash
# =============================================================================
# backup.sh — Smart Livestock Health and Farm Management System
# =============================================================================
# Creates a timestamped mysqldump of livestock_db and places it in the
# BACKUP_DIR directory (default: ~/livestock_backups).
#
# Usage:
#   chmod +x backup.sh
#   ./backup.sh
#   ./backup.sh --dir /mnt/external/backups
#
# Environment:
#   The script reads database credentials from the ../.env file (python-decouple
#   format) if present, or falls back to the variables below.
#   Override any variable by exporting it before running:
#     export DB_PASSWORD=mysecret ./backup.sh
#
# Retention:
#   By default the script keeps the 14 most recent backup files and deletes
#   older ones.  Set BACKUP_KEEP=N to override.
#
# Schedule (cron example — daily at 02:00):
#   0 2 * * * /path/to/backend/scripts/backup.sh >> /var/log/livestock_backup.log 2>&1
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration defaults (override via env or .env file)
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

# Load from .env if it exists
if [[ -f "$ENV_FILE" ]]; then
    # Extract only the DB_* lines to avoid sourcing arbitrary shell code
    while IFS='=' read -r key value; do
        case "$key" in
            DB_NAME|DB_USER|DB_PASSWORD|DB_HOST|DB_PORT)
                export "$key"="$value"
                ;;
        esac
    done < <(grep -E '^(DB_NAME|DB_USER|DB_PASSWORD|DB_HOST|DB_PORT)=' "$ENV_FILE")
fi

DB_NAME="${DB_NAME:-livestock_db}"
DB_USER="${DB_USER:-livestock_user}"
DB_PASSWORD="${DB_PASSWORD:-}"
DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-3306}"

BACKUP_DIR="${BACKUP_DIR:-$HOME/livestock_backups}"
BACKUP_KEEP="${BACKUP_KEEP:-14}"

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dir) BACKUP_DIR="$2"; shift 2 ;;
        --keep) BACKUP_KEEP="$2"; shift 2 ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

# ---------------------------------------------------------------------------
# Prepare output directory
# ---------------------------------------------------------------------------
mkdir -p "$BACKUP_DIR"

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_FILE="$BACKUP_DIR/livestock_db_${TIMESTAMP}.sql.gz"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting backup of $DB_NAME → $BACKUP_FILE"

# ---------------------------------------------------------------------------
# Dump and compress
# ---------------------------------------------------------------------------
MYSQL_PWD="$DB_PASSWORD" mysqldump \
    --host="$DB_HOST" \
    --port="$DB_PORT" \
    --user="$DB_USER" \
    --single-transaction \
    --routines \
    --triggers \
    --add-drop-table \
    --databases "$DB_NAME" \
    | gzip -9 > "$BACKUP_FILE"

BACKUP_SIZE="$(du -sh "$BACKUP_FILE" | cut -f1)"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup complete — $BACKUP_SIZE written to $BACKUP_FILE"

# ---------------------------------------------------------------------------
# Rotate old backups
# ---------------------------------------------------------------------------
BACKUP_COUNT="$(ls -1 "$BACKUP_DIR"/livestock_db_*.sql.gz 2>/dev/null | wc -l)"
if [[ "$BACKUP_COUNT" -gt "$BACKUP_KEEP" ]]; then
    DELETE_COUNT=$(( BACKUP_COUNT - BACKUP_KEEP ))
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Rotating — removing $DELETE_COUNT old backup(s)"
    ls -1t "$BACKUP_DIR"/livestock_db_*.sql.gz | tail -n "$DELETE_COUNT" | xargs rm -f
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Done. Backups retained: $(ls -1 "$BACKUP_DIR"/livestock_db_*.sql.gz 2>/dev/null | wc -l)"
