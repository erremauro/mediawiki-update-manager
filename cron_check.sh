#!/bin/bash

# Carica variabili da .env
ENV_FILE=/opt/mediawiki_backup/.env
source $ENV_FILE

# Ottieni ultima versione disponibile
LATEST_BRANCH=$(curl -s https://releases.wikimedia.org/mediawiki/ | \
  grep -Eo 'href="[0-9]+\.[0-9]+/' | \
  sed 's/href="//;s|/||' | sort -V | tail -1)

LATEST_VERSION=$(curl -s "https://releases.wikimedia.org/mediawiki/$LATEST_BRANCH/" | \
  grep -Eo 'mediawiki-[0-9]+\.[0-9]+(\.[0-9]+)?\.tar\.gz' | \
  grep -vE '(rc|alpha|beta)' | sort -V | tail -1 | sed 's/mediawiki-//;s/\.tar\.gz//')

# Ottieni versione installata
INSTALLED_VERSION=$(grep -oP "define\(\s*'MW_VERSION'\s*,\s*'\K[^']+" "$MEDIAWIKI_PATH/includes/Defines.php")

# Confronta
if [ "$LATEST_VERSION" != "$INSTALLED_VERSION" ]; then
  SUBJECT="[!] MediaWiki update disponibile: $LATEST_VERSION (installata: $INSTALLED_VERSION)"
  TO="$NOTIFY_EMAIL"

  (
    echo "To: $TO"
    echo "Subject: $SUBJECT"
    echo "Content-Type: text/plain; charset=utf-8"
    echo
    echo "È disponibile una nuova versione di MediaWiki: $LATEST_VERSION"
    echo "Attualmente è installata la versione: $INSTALLED_VERSION"
    echo ""
    echo "Puoi aggiornare eseguendo: ./update_mediawiki.sh"
  ) | /usr/sbin/sendmail -t
fi
