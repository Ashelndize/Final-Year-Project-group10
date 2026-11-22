#!/usr/bin/env bash
# =============================================================================
# restore.sh — Smart Livestock Health and Farm Management System
# =============================================================================
# Restores livestock_db from a mysqldump .sql.gz backup file.
#
# Usage:
#   chmod +x restore.sh
#   ./restore.sh /path/to/livestock_db_20261121_020000.sql.gz
#
# IMPORTANT:
#   This script drops and recreates the target database.
#   Always confirm that the correct backup file is specified.
#   Always run against a scratch/test database first.
#
# Options:
#   --target-db NAME   Override the target database name (default: from .env)
#   --dry-run          Print commands without executing the restore
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

if [[ -f "$ENV_FILE" ]]; then
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

DRY_RUN=false
TARGET_DB=""

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
BACKUP_FILE=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --target-db) TARGET_DB="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        --*) echo "Unknown option: $1"; exit 1 ;;
        *)
            if [[ -z "$BACKUP_FILE" ]]; then
                BACKUP_FILE="$1"
            else
                echo "Unexpected argument: $1"; exit 1
            fi
            shift
            ;;
    esac
done

if [[ -z "$BACKUP_FILE" ]]; then
    echo "Usage: $0 <backup_file.sql.gz> [--target-db NAME] [--dry-run]"
    exit 1
fi

if [[ ! -f "$BACKUP_FILE" ]]; then
    echo "Error: backup file not found: $BACKUP_FILE"
    exit 1
fi

TARGET_DB="${TARGET_DB:-$DB_NAME}"

# ---------------------------------------------------------------------------
# Safety confirmation
# ---------------------------------------------------------------------------
echo ""
echo "========================================================="
echo "  RESTORE CONFIGURATION"
echo "========================================================="
echo "  Source  : $BACKUP_FILE ($(du -sh "$BACKUP_FILE" | cut -f1))"
echo "  Target  : $TARGET_DB @ $DB_HOST:$DB_PORT"
echo "  User    : $DB_USER"
if [[ "$DRY_RUN" == "true" ]]; then
    echo "  Mode    : DRY RUN — no changes will be made"
fi
echo "========================================================="
echo ""
read -r -p "Type 'yes' to proceed: " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    echo "Restore cancelled."
    exit 0
fi

# ---------------------------------------------------------------------------
# Execute restore
# ---------------------------------------------------------------------------
if [[ "$DRY_RUN" == "true" ]]; then
    echo "[DRY RUN] Would execute: gunzip -c $BACKUP_FILE | mysql --host=$DB_HOST ..."
    echo "[DRY RUN] No changes made."
    exit 0
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting restore from $BACKUP_FILE → $TARGET_DB"

MYSQL_PWD="$DB_PASSWORD" gunzip -c "$BACKUP_FILE" | mysql \
    --host="$DB_HOST" \
    --port="$DB_PORT" \
    --user="$DB_USER"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Restore complete."

# ---------------------------------------------------------------------------
# Verification — print table row counts
# ---------------------------------------------------------------------------
echo ""
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Row counts in $TARGET_DB:"
MYSQL_PWD="$DB_PASSWORD" mysql \
    --host="$DB_HOST" \
    --port="$DB_PORT" \
    --user="$DB_USER" \
    --batch \
    --skip-column-names \
    -e "
SELECT
    table_name,
    table_rows
FROM information_schema.tables
WHERE table_schema = '$TARGET_DB'
ORDER BY table_name;" 2>/dev/null | column -t

echo ""
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Restore verification complete."
echo "Next step: run 'python manage.py migrate --run-syncdb' if any migrations are missing."
