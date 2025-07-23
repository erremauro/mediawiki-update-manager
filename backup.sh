#!/bin/bash

set -e

# === Variabili ===
source .env

# Crea il file di log se non esiste
touch "$UPDATE_LOG_FILE"
chmod 644 "$UPDATE_LOG_FILE"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$UPDATE_LOG_FILE"
}

# === Estrazione parametri ===
LOCALSETTINGS="$MEDIAWIKI_PATH/LocalSettings.php"

get_php_var() {
  grep -oP "\\\$$1\s*=\s*['\"]\K[^'\"]+" "$LOCALSETTINGS"
}

DB_NAME=$(get_php_var "wgDBname")
DB_USER=$(get_php_var "wgDBuser")
DB_PASSWORD=$(get_php_var "wgDBpassword")

# === Crea cartella backup ===
timestamp=$(date +%Y%m%d_%H%M%S)
backup_dir="$BACKUP_PATH/backup_$timestamp"
mkdir -p "$backup_dir"

log "Avvio del backup in: $backup_dir"

# Copia intera installazione MediaWiki
cp -r "$MEDIAWIKI_PATH" "$backup_dir/mediawiki"

# Dump SQL
MYSQL_PWD="$DB_PASSWORD" mysqldump -u "$DB_USER" "$DB_NAME" > "$backup_dir/db.sql"

log "[✓] Backup completato correttamente."
