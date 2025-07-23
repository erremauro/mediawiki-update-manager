#!/bin/bash

# Carica variabili
source .env

echo "[*] Ripristino backup disponibile in:"
ls -1 "$BACKUP_PATH"

read -p "Inserisci il nome della directory di backup da ripristinare (es. backup_20250723_120000): " restore_folder

FULL_RESTORE_PATH="$BACKUP_PATH/$restore_folder"

if [ ! -d "$FULL_RESTORE_PATH" ]; then
  echo "[!] Directory non trovata."
  exit 1
fi

# Ferma Apache
echo "[*] Fermando Apache..."
sudo systemctl stop "$APACHE_SERVICE"

# Ripristina file
rm -rf "$MEDIAWIKI_PATH"
cp -r "$FULL_RESTORE_PATH/mediawiki_files" "$MEDIAWIKI_PATH"

# Ripristina DB
mysql -u "$DB_USER" -p "$DB_NAME" < "$FULL_RESTORE_PATH/db_backup.sql"

# Riavvia Apache
echo "[*] Riavvio Apache..."
sudo systemctl start "$APACHE_SERVICE"

echo "[✓] Ripristino completato."
