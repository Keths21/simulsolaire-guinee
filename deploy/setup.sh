#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  SimulSolaire — Script de setup initial (VPS Ubuntu/Debian)  ║
# ║  Usage : bash setup.sh votredomaine.com                       ║
# ╚══════════════════════════════════════════════════════════════╝
set -e

DOMAIN=${1:-"votredomaine.com"}
APP_DIR="/var/www/simulsolaire"
REPO="https://github.com/Keths21/simulsolaire-guinee.git"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  SimulSolaire — Setup VPS"
echo "  Domaine : $DOMAIN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Mise à jour système
echo "📦 Mise à jour du système..."
apt-get update -qq && apt-get upgrade -y -qq

# 2. Installation Nginx + Git + Certbot
echo "🔧 Installation Nginx, Git, Certbot..."
apt-get install -y -qq nginx git certbot python3-certbot-nginx

# 3. Cloner le dépôt
echo "📥 Clonage du dépôt..."
mkdir -p "$APP_DIR"
if [ -d "$APP_DIR/.git" ]; then
    cd "$APP_DIR" && git pull origin main
else
    git clone "$REPO" "$APP_DIR"
fi
chown -R www-data:www-data "$APP_DIR"

# 4. Config Nginx
echo "⚙️  Configuration Nginx..."
sed "s/votredomaine.com/$DOMAIN/g" "$APP_DIR/deploy/nginx.conf" \
    > /etc/nginx/sites-available/simulsolaire

# Désactiver le site par défaut, activer le nôtre
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/simulsolaire /etc/nginx/sites-enabled/simulsolaire

# Test config Nginx
nginx -t

# 5. Démarrer / recharger Nginx
echo "🚀 Démarrage Nginx..."
systemctl enable nginx
systemctl restart nginx

# 6. Certificat SSL Let's Encrypt
echo "🔒 Génération du certificat SSL..."
certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" \
    --non-interactive --agree-tos -m "admin@$DOMAIN" \
    --redirect

# 7. Rechargement final
systemctl reload nginx

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Déploiement terminé !"
echo "  🌐 https://$DOMAIN"
echo "  📱 https://$DOMAIN/mobile.html"
echo "  🗺️  https://$DOMAIN/carte.html"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
