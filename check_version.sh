#!/bin/bash

source .env

# Trova l'ultimo ramo (es. 1.44)
latest_branch=$(curl -s https://releases.wikimedia.org/mediawiki/ | \
  grep -Eo 'href="[0-9]+\.[0-9]+/' | \
  sed 's/href="//;s|/||' | sort -V | tail -1)

# Trova il file tar.gz stabile (esclude patch, rc e sig)
LATEST_VERSION=$(curl -s "https://releases.wikimedia.org/mediawiki/$latest_branch/" | \
  grep -Eo "mediawiki-$latest_branch\.[0-9]+\.tar\.gz" | \
  grep -vE 'patch|rc|sig' | \
  sort -V | tail -1 | \
  sed 's/mediawiki-//' | sed 's/\.tar\.gz//')

echo "Ultima versione stabile disponibile: $LATEST_VERSION"

# Ottieni versione installata
INSTALLED_VERSION=$(grep -oP "define\(\s*'MW_VERSION'\s*,\s*'\K[^']+" "$MEDIAWIKI_PATH/includes/Defines.php")

echo "Versione installata: $INSTALLED_VERSION"
if [[ "$INSTALLED_VERSION" != "$LATEST_VERSION" ]]; then
  echo "[!]  È disponibile una nuova versione di MediaWiki!"
else
  echo "[✓]  MediaWiki è aggiornato."
fi
