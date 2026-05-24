#!/bin/bash
# Mise à jour INNOVEA GROUP Simulateur depuis GitHub
APP_DIR="/var/www/simulsolaire"

echo "==> Mise à jour INNOVEA Simulateur..."
cd "$APP_DIR"

git fetch origin
git reset --hard origin/main

chown -R www-data:www-data "$APP_DIR"

# Recharger Nginx si la config a changé
if nginx -t -c /etc/nginx/nginx.conf 2>/dev/null; then
  nginx -s reload
  echo "==> Nginx rechargé"
fi

echo "==> Mise à jour terminée — $(date '+%d/%m/%Y %H:%M')"
