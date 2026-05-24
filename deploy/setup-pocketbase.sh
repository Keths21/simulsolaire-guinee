#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  INNOVEA GROUP — Installation PocketBase                     ║
# ║  simulateur.innoveagroup.tech / VPS Hostinger                ║
# ╚══════════════════════════════════════════════════════════════╝
set -e

PB_DIR="/opt/pocketbase"
PB_VERSION=$(curl -s https://api.github.com/repos/pocketbase/pocketbase/releases/latest \
  | grep '"tag_name"' | head -1 | cut -d'"' -f4)

echo "==> Version PocketBase détectée : $PB_VERSION"

# ── 1. Répertoire et téléchargement ──────────────────────────────
mkdir -p "$PB_DIR/pb_data"

ARCH="linux_amd64"
URL="https://github.com/pocketbase/pocketbase/releases/download/${PB_VERSION}/pocketbase_${PB_VERSION#v}_${ARCH}.zip"

echo "==> Téléchargement depuis $URL"
curl -L "$URL" -o /tmp/pocketbase.zip
unzip -o /tmp/pocketbase.zip -d "$PB_DIR"
chmod +x "$PB_DIR/pocketbase"
rm /tmp/pocketbase.zip

echo "==> PocketBase installé dans $PB_DIR"

# ── 2. Service systemd ────────────────────────────────────────────
cat > /etc/systemd/system/pocketbase.service << 'EOF'
[Unit]
Description=PocketBase — INNOVEA GROUP backend
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/pocketbase
ExecStart=/opt/pocketbase/pocketbase serve --http=0.0.0.0:8090
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# ── 3. Permissions ────────────────────────────────────────────────
chown -R www-data:www-data "$PB_DIR"

# ── 4. Firewall : bloquer accès direct port 8090 depuis internet ──
if command -v ufw &>/dev/null; then
  ufw deny 8090/tcp 2>/dev/null || true
  echo "==> UFW : port 8090 bloqué pour l'extérieur"
fi

# ── 5. Démarrage ─────────────────────────────────────────────────
systemctl daemon-reload
systemctl enable pocketbase
systemctl start pocketbase

echo ""
echo "✓ PocketBase démarré sur 0.0.0.0:8090 (accès Docker + localhost)"
echo ""
echo "══════════════════════════════════════════════"
echo "  Admin UI : https://simulateur.innoveagroup.tech/_pb/"
echo ""
echo "  → Créer un compte admin au premier accès"
echo "  → Puis créer la collection 'leads' (voir README)"
echo "══════════════════════════════════════════════"
