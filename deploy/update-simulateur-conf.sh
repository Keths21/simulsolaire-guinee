#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  INNOVEA GROUP — Mise à jour simulateur.conf (Docker Nginx)  ║
# ║  PocketBase gateway : 172.23.0.1:8090                        ║
# ╚══════════════════════════════════════════════════════════════╝
set -e

CONF="/opt/pbp-guinee/nginx/conf.d/simulateur.conf"

cat > "$CONF" << 'NGINX'
# simulateur.innoveagroup.tech — INNOVEA GROUP Simulateur + PocketBase

server {
    listen 80;
    server_name simulateur.innoveagroup.tech;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name simulateur.innoveagroup.tech;

    ssl_certificate     /etc/letsencrypt/live/simulateur.innoveagroup.tech/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/simulateur.innoveagroup.tech/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_session_cache shared:SSL:10m;
    add_header Strict-Transport-Security "max-age=31536000" always;

    root /var/www/simulsolaire;
    index index.html;

    # ── PocketBase admin UI (^~ bloque la regex static files) ───────
    location ^~ /_/ {
        proxy_pass         http://172.23.0.1:8090/_/;
        proxy_http_version 1.1;
        proxy_set_header   Host $host;
        proxy_set_header   X-Real-IP $remote_addr;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
        proxy_read_timeout 360s;
    }

    # ── PocketBase REST API (appelé par le frontend JS) ───────────
    location ^~ /_pb/ {
        rewrite ^/_pb/(.*)$ /$1 break;
        proxy_pass         http://172.23.0.1:8090;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade $http_upgrade;
        proxy_set_header   Connection "upgrade";
        proxy_set_header   Host $host;
        proxy_set_header   X-Real-IP $remote_addr;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
        proxy_read_timeout 360s;
    }

    location / {
        try_files $uri $uri/ /index.html;
        add_header Cache-Control "no-cache";
    }

    location ~* \.(js|css|png|jpg|ico|svg|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
}
NGINX

echo "==> simulateur.conf écrit"

# Test config et reload nginx dans le conteneur Docker
docker exec pbp_nginx nginx -t && docker exec pbp_nginx nginx -s reload

echo "==> Nginx Docker rechargé avec succès"
echo "==> PocketBase Admin UI : https://simulateur.innoveagroup.tech/_/"
echo "==> PocketBase API      : https://simulateur.innoveagroup.tech/_pb/api/"
