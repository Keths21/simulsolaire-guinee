#!/bin/bash
# Correctif SSL — à lancer si certbot n'a pas pu installer le cert dans Nginx
set -e

DOMAIN="simulateur.innoveagroup.tech"
APP_DIR="/var/www/simulsolaire"

echo "🔧 Correction de la config Nginx + SSL..."

# 1. Supprimer toutes les configs temporaires
rm -f /etc/nginx/sites-enabled/simulsolaire-temp
rm -f /etc/nginx/sites-available/simulsolaire-temp
rm -f /etc/nginx/sites-enabled/simulsolaire

# 2. Vérifier que le certificat existe bien
echo "📋 Certificats disponibles :"
ls /etc/letsencrypt/live/$DOMAIN/

# 3. Générer ssl-dhparams.pem si absent (peut prendre 1-2 min)
if [ ! -f /etc/letsencrypt/ssl-dhparams.pem ]; then
    echo "⏳ Génération ssl-dhparams.pem..."
    openssl dhparam -out /etc/letsencrypt/ssl-dhparams.pem 2048
fi

# 4. Écrire la config Nginx finale propre
cat > /etc/nginx/sites-available/simulsolaire << NGINXCONF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $DOMAIN;

    root $APP_DIR;
    index index.html;

    ssl_certificate     /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache   shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_dhparam         /etc/letsencrypt/ssl-dhparams.pem;

    # Headers sécurité + PWA
    add_header Service-Worker-Allowed   "/"                               always;
    add_header X-Content-Type-Options   "nosniff"                         always;
    add_header X-Frame-Options          "SAMEORIGIN"                      always;
    add_header Referrer-Policy          "strict-origin-when-cross-origin" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Gzip
    gzip on;
    gzip_vary on;
    gzip_comp_level 6;
    gzip_types text/html text/css application/javascript application/json image/svg+xml;

    # Types MIME
    types { application/manifest+json json; image/svg+xml svg svgz; }

    # Cache assets
    location ~* \.(js|css|svg|ico|woff2?)$ {
        expires 1M;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    # Service Worker + Manifest : cache court
    location ~* (manifest\.json|sw\.js)$ {
        expires 1h;
        add_header Cache-Control "public, no-cache";
        add_header Service-Worker-Allowed "/";
    }

    # HTML
    location ~* \.html$ {
        expires 1h;
        add_header Cache-Control "public";
    }

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    error_page 404 /index.html;

    access_log /var/log/nginx/simulsolaire_access.log;
    error_log  /var/log/nginx/simulsolaire_error.log warn;
}
NGINXCONF

# 5. Activer la config
ln -sf /etc/nginx/sites-available/simulsolaire /etc/nginx/sites-enabled/simulsolaire

# 6. Tester la config
echo "🧪 Test de la configuration Nginx..."
nginx -t

# 7. Recharger Nginx
echo "🚀 Rechargement Nginx..."
systemctl reload nginx

# 8. Renouvellement automatique SSL (cron si pas déjà fait)
(crontab -l 2>/dev/null | grep -q certbot) || \
    (crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet && systemctl reload nginx") | crontab -

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ SSL + Nginx configurés avec succès !"
echo "  🌐 https://$DOMAIN"
echo "  📱 https://$DOMAIN/mobile.html"
echo "  🗺️  https://$DOMAIN/carte.html"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
