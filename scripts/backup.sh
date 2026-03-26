#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# backup.sh — Backup diario del homelab
# Programar con cron: 0 3 * * * /path/to/backup.sh
# ══════════════════════════════════════════════════════════════════

HOMELAB_DIR="${HOMELAB_DIR:-$HOME/homelab}"
BACKUP_DIR="${BACKUP_DIR:-/opt/homelab-backups}"
MAX_BACKUPS="${MAX_BACKUPS:-7}"
DATE=$(date +%Y%m%d-%H%M)
BACKUP_FILE="$BACKUP_DIR/homelab-$DATE.tar.gz"

mkdir -p "$BACKUP_DIR"

echo "$(date '+%Y-%m-%d %H:%M:%S') — Iniciando backup de $HOMELAB_DIR..."

if tar -czf "$BACKUP_FILE" "$HOMELAB_DIR/" 2>/dev/null; then
    SIZE=$(du -sh "$BACKUP_FILE" | cut -f1)
    echo "$(date '+%Y-%m-%d %H:%M:%S') — Backup creado: $(basename $BACKUP_FILE) ($SIZE)"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') — ERROR: Falló la creación del backup"
    exit 1
fi

# Eliminar backups más antiguos que MAX_BACKUPS
TOTAL=$(ls "$BACKUP_DIR"/*.tar.gz 2>/dev/null | wc -l)
if [[ $TOTAL -gt $MAX_BACKUPS ]]; then
    ls -t "$BACKUP_DIR"/*.tar.gz | tail -n +$((MAX_BACKUPS + 1)) | xargs -r rm
    echo "$(date '+%Y-%m-%d %H:%M:%S') — Backups antiguos eliminados. Total actual: $MAX_BACKUPS"
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') — Backup completado."
