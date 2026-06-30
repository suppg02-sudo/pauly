#!/bin/bash
# PA Dashboard — deploy script
# Copies HTML to /opt/pauly and replaces env placeholders with .env values

set -euo pipefail

source /opt/pauly/.env 2>/dev/null || { echo "ERROR: /opt/pauly/.env not found"; exit 1; }

SRC="$(dirname "$0")/../personal-assistant.html"
DEST="/opt/pauly/personal-assistant.html"

cp "$SRC" "$DEST"

# Replace placeholders
sed -i "s|%%SERVER_IP%%|${SERVER_IP:-localhost}|g" "$DEST"
sed -i "s|%%PORT_DIRECTUS%%|${PORT_DIRECTUS:-8056}|g" "$DEST"
sed -i "s|%%PORT_ASTRO%%|${PORT_ASTRO:-3003}|g" "$DEST"

echo "[pa] Dashboard deployed to $DEST"
echo "[pa] URL: http://${SERVER_IP:-localhost}:${PORT_PA:-8901}/personal-assistant.html"
