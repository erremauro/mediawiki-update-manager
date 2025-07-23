#!/bin/bash

set -e

# === Determina il path assoluto ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE_PATH="$SCRIPT_DIR/.env"
CRON_CHECK_FILE="$SCRIPT_DIR/cron_check.sh"

# === Controlli iniziali ===
if [ ! -f "$ENV_FILE_PATH" ]; then
  echo "[!] File .env non trovato: $ENV_FILE_PATH"
  exit 1
fi

if [ ! -f "$CRON_CHECK_FILE" ]; then
  echo "[!] File cron_check.sh non trovato: $CRON_CHECK_FILE"
  exit 1
fi

# === Imposta ENV_FILE nel cron_check.sh ===
sed -i.bak "s|^ENV_FILE=.*|ENV_FILE=$ENV_FILE_PATH|" "$CRON_CHECK_FILE"
rm -f "$CRON_CHECK_FILE.bak"

echo "[✓] Percorso .env impostato correttamente in cron_check.sh:"
echo "     ENV_FILE=$ENV_FILE_PATH"

# === Gestione crontab ===
CRON_JOB="30 6 * * 1 $CRON_CHECK_FILE"
CRON_EXISTS=$(crontab -l 2>/dev/null | grep -F "$CRON_CHECK_FILE" || true)

if [ -n "$CRON_EXISTS" ]; then
  # Entry esiste: aggiorna
  (crontab -l 2>/dev/null | grep -vF "$CRON_CHECK_FILE"; echo "$CRON_JOB") | crontab -
  echo "[✓] Entry cron aggiornata:"
else
  # Entry non esiste: aggiungi
  (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
  echo "[✓] Entry cron aggiunta:"
fi

echo "     $CRON_JOB"
