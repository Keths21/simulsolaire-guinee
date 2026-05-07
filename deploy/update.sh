#!/bin/bash
# Mise à jour SimulSolaire depuis GitHub
APP_DIR="/var/www/simulsolaire"

echo "🔄 Mise à jour SimulSolaire..."
cd "$APP_DIR"

# Force la synchronisation avec GitHub (écrase les modifs locales)
git fetch origin
git reset --hard origin/main

chown -R www-data:www-data "$APP_DIR"
echo "✅ Mise à jour terminée — $(date '+%d/%m/%Y %H:%M')"
