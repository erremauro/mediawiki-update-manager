#!/bin/bash

set -e
trap rollback ERR

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

# Usa MW_VERSION da Defines.php per precisione (es. 1.44.0)
INSTALLED_VERSION=$(grep -oP "define\(\s*'MW_VERSION'\s*,\s*'\K[^']+" "$MEDIAWIKI_PATH/includes/Defines.php")

# === Ultima versione disponibile ===
latest_branch=$(curl -s https://releases.wikimedia.org/mediawiki/ | \
  grep -Eo 'href="[0-9]+\.[0-9]+/' | sed 's/href="//;s|/||' | sort -V | tail -1)

latest_tar=$(curl -s "https://releases.wikimedia.org/mediawiki/$latest_branch/" | \
  grep -Eo "mediawiki-$latest_branch\.[0-9]+\.tar\.gz" | grep -vE 'patch|rc|sig' | sort -V | tail -1)

LATEST_VERSION=$(echo "$latest_tar" | sed 's/mediawiki-//' | sed 's/\.tar\.gz//')

log "Versione installata: $INSTALLED_VERSION"
log "Ultima versione stabile disponibile: $LATEST_VERSION"

if [[ "$INSTALLED_VERSION" == "$LATEST_VERSION" ]]; then
  log "MediaWiki è già aggiornato."
  exit 0
fi

log "È disponibile una nuova versione: $LATEST_VERSION"

# === Conferma backup ===
read -r -p "Vuoi procedere con il backup? [Y/n]: " confirm_backup
confirm_backup=${confirm_backup:-Y}

if [[ ! "$confirm_backup" =~ ^[Yy]$ ]]; then
  log "Backup annullato dall’utente."
  exit 1
fi

# === Backup ===
timestamp=$(date +%Y%m%d_%H%M%S)
backup_dir="$BACKUP_PATH/backup_$timestamp"
mkdir -p "$backup_dir"

log "Backup in corso..."

# Copia l'intera installazione MediaWiki
cp -r "$MEDIAWIKI_PATH" "$backup_dir/mediawiki"

# Dump SQL
MYSQL_PWD="$DB_PASSWORD" mysqldump -u "$DB_USER" "$DB_NAME" > "$backup_dir/db.sql"

log "Backup completato in: $backup_dir"

# === Conferma aggiornamento ===
read -r -p "Vuoi procedere con l'aggiornamento a MediaWiki $LATEST_VERSION? [Y/n]: " confirm_update
confirm_update=${confirm_update:-Y}

if [[ ! "$confirm_update" =~ ^[Yy]$ ]]; then
  log "Aggiornamento annullato dall’utente."
  exit 1
fi

# === Scaricamento e decompressione ===
tar_file="$latest_tar"
log "Scaricamento $tar_file..."
wget "https://releases.wikimedia.org/mediawiki/$latest_branch/$tar_file" -O "$tar_file"
tar -xzf "$tar_file"
new_dir=$(tar -tzf "$tar_file" | head -1 | cut -f1 -d"/")
rm -f "$tar_file"
log "Scaricamento ed estrazione completati."

# === Copia configurazioni ===
cp "$MEDIAWIKI_PATH/LocalSettings.php" "$new_dir/"
cp -r "$MEDIAWIKI_PATH/images" "$new_dir/"
cp -r "$MEDIAWIKI_PATH/extensions" "$new_dir/"
log "Configurazioni copiate."

# === Fermare Apache ===
log "Fermando Apache..."
sudo systemctl stop "$HTTP_SERVICE"

# === Attivazione nuova versione ===
OLD_MEDIAWIKI="${MEDIAWIKI_PATH}_old_$timestamp"
mv "$MEDIAWIKI_PATH" "$OLD_MEDIAWIKI"
mv "$new_dir" "$MEDIAWIKI_PATH"

# === Ripristina file .htaccess e logo ===
cp "$backup_dir/.htaccess" "$MEDIAWIKI_PATH/"
cp "$backup_dir/mediawiki-logo.svg" "$MEDIAWIKI_PATH/resources/assets/"
log "Ripristinati .htaccess e mediawiki-logo.svg"

# === Riavvio Apache ===
log "Riavvio Apache..."
sudo systemctl start "$HTTP_SERVICE"

# === Esecuzione update.php ===
read -r -p "Vuoi eseguire ora 'php maintenance/update.php'? [Y/n]: " confirm_updatephp
confirm_updatephp=${confirm_updatephp:-Y}

if [[ "$confirm_updatephp" =~ ^[Yy]$ ]]; then
  log "Esecuzione update.php..."
  php "$MEDIAWIKI_PATH/maintenance/update.php"
  log "update.php eseguito con successo."
else
  log "update.php non eseguito. Ricorda di farlo manualmente."
fi

log "[✓] Aggiornamento completato senza errori."
exit 0

# === Funzione rollback ===
rollback() {
  log "[!] Errore durante l’aggiornamento. Avvio del ripristino..."

  sudo systemctl stop "$HTTP_SERVICE"
  rm -rf "$MEDIAWIKI_PATH"
  cp -r "$backup_dir/mediawiki" "$MEDIAWIKI_PATH"
  MYSQL_PWD="$DB_PASSWORD" mysql -u "$DB_USER" "$DB_NAME" < "$backup_dir/db.sql"
  sudo systemctl start "$HTTP_SERVICE"

  log "[✓] Ripristino completato da backup: $backup_dir"
  exit 1
}
