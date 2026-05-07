#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  SimulSolaire — Setup VPS Hostinger                          ║
# ║  Domaine : simulateur.innoveagroup.tech                       ║
# ╚══════════════════════════════════════════════════════════════╝
set -e

DOMAIN="simulateur.innoveagroup.tech"
APP_DIR="/var/www/simulsolaire"
REPO="https://github.com/Keths21/simulsolaire-guinee.git"
EMAIL="admin@innoveagroup.tech"   # email pour Let's Encrypt

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  SimulSolaire — Setup VPS"
echo "  Domaine : $DOMAIN"
echo "  Répertoire : $APP_DIR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Mise à jour système
echo ""
echo "📦 [1/6] Mise à jour du système..."
apt-get update -qq && apt-get upgrade -y -qq

# 2. Installation des dépendances
echo "🔧 [2/6] Installation Nginx, Git, Certbot..."
apt-get install -y -qq nginx git certbot python3-certbot-nginx ufw

# 3. Firewall
echo "🛡️  [3/6] Configuration du firewall..."
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable

# 4. Cloner le dépôt
echo "📥 [4/6] Clonage du dépôt GitHub..."
mkdir -p "$APP_DIR"
if [ -d "$APP_DIR/.git" ]; then
    echo "  → Dépôt existant, mise à jour..."
    cd "$APP_DIR" && git pull origin main
else
    git clone "$REPO" "$APP_DIR"
fi
chown -R www-data:www-data "$APP_DIR"
chmod -R 755 "$APP_DIR"

# 5. Configuration Nginx
echo "⚙️  [5/6] Configuration Nginx..."
cp "$APP_DIR/deploy/nginx.conf" /etc/nginx/sites-available/simulsolaire

# Désactiver site par défaut, activer simulsolaire
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/simulsolaire /etc/nginx/sites-enabled/simulsolaire

# Créer une config HTTP temporaire pour Certbot (sans SSL d'abord)
cat > /etc/nginx/sites-available/simulsolaire-temp << 'TMPCONF'
server {
    listen 80;
    server_name simulateur.innoveagroup.tech;
    root /var/www/simulsolaire;
    location /.well-known/acme-challenge/ { root /var/www/html; }
    location / { try_files $uri $uri/ /index.html; }
}
TMPCONF

ln -sf /etc/nginx/sites-available/simulsolaire-temp /etc/nginx/sites-enabled/simulsolaire
rm -f /etc/nginx/sites-enabled/simulsolaire
nginx -t && systemctl restart nginx

# 6. Certificat SSL Let's Encrypt
echo "🔒 [6/6] Certificat SSL Let's Encrypt..."
certbot --nginx \
    -d "$DOMAIN" \
    --non-interactive \
    --agree-tos \
    -m "$EMAIL" \
    --redirect

# Activer la vraie config (avec SSL)
ln -sf /etc/nginx/sites-available/simulsolaire /etc/nginx/sites-enabled/simulsolaire
rm -f /etc/nginx/sites-enabled/simulsolaire-temp
rm -f /etc/nginx/sites-available/simulsolaire-temp

nginx -t && systemctl reload nginx

# Renouvellement automatique SSL
echo "🔁 Renouvellement SSL automatique (cron)..."
(crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet && systemctl reload nginx") | crontab -

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Déploiement terminé avec succès !"
echo ""
echo "  🌐 https://$DOMAIN"
echo "  📱 https://$DOMAIN/mobile.html"
echo "  🗺️  https://$DOMAIN/carte.html"
echo ""
echo "  Pour les mises à jour futures :"
echo "  bash /var/www/simulsolaire/deploy/update.sh"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
