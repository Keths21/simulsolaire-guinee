#!/bin/bash
# Script de mise à jour rapide — à lancer après chaque git push
APP_DIR="/var/www/simulsolaire"

echo "🔄 Mise à jour SimulSolaire..."
cd "$APP_DIR"
git pull origin main
chown -R www-data:www-data "$APP_DIR"
echo "✅ Mise à jour terminée — $(date '+%d/%m/%Y %H:%M')"
