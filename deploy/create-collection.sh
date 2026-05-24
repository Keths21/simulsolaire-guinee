#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  INNOVEA GROUP — Création collection PocketBase "leads"      ║
# ║  À exécuter sur le VPS APRÈS setup-pocketbase.sh             ║
# ╚══════════════════════════════════════════════════════════════╝
set -e

PB="http://127.0.0.1:8090"

echo ""
echo "Création de la collection 'leads' dans PocketBase"
echo "─────────────────────────────────────────────────"
echo "Entrez les credentials du compte admin PocketBase"
echo "(ceux créés lors du premier accès à l'admin UI)"
echo ""
read -rp "Email admin : " ADMIN_EMAIL
read -rsp "Mot de passe : " ADMIN_PASS
echo ""

# ── 1. Authentification (PB v0.22+ et fallback v0.21) ────────────
AUTH_RESPONSE=$(curl -s -X POST "$PB/api/superusers/auth-with-password" \
  -H "Content-Type: application/json" \
  -d "{\"identity\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASS\"}" 2>/dev/null)

TOKEN=$(echo "$AUTH_RESPONSE" | grep -o '"token":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  # Fallback ancienne version PocketBase
  AUTH_RESPONSE=$(curl -s -X POST "$PB/api/admins/auth-with-password" \
    -H "Content-Type: application/json" \
    -d "{\"identity\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASS\"}")
  TOKEN=$(echo "$AUTH_RESPONSE" | grep -o '"token":"[^"]*"' | head -1 | cut -d'"' -f4)
fi

if [ -z "$TOKEN" ]; then
  echo "ERREUR : Authentification échouée. Vérifiez vos credentials."
  exit 1
fi

echo "==> Authentifié avec succès"

# ── 2. Création de la collection ─────────────────────────────────
HTTP_CODE=$(curl -s -o /tmp/pb_response.json -w "%{http_code}" \
  -X POST "$PB/api/collections" \
  -H "Authorization: $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "leads",
    "type": "base",
    "createRule": "",
    "listRule": null,
    "viewRule": null,
    "updateRule": null,
    "deleteRule": null,
    "fields": [
      {"name": "nom",       "type": "text",   "required": false},
      {"name": "telephone", "type": "text",   "required": false},
      {"name": "ville",     "type": "text",   "required": false},
      {"name": "rappel",    "type": "text",   "required": false},
      {"name": "pack",      "type": "text",   "required": true},
      {"name": "kwh",       "type": "number", "required": true, "min": 0},
      {"name": "batiment",  "type": "text",   "required": false},
      {"name": "objectif",  "type": "text",   "required": false},
      {"name": "appareils", "type": "json",   "required": false},
      {"name": "source",    "type": "text",   "required": false}
    ]
  }')

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
  echo ""
  echo "✓ Collection 'leads' créée avec succès !"
  echo ""
  echo "═══════════════════════════════════════════════════"
  echo "  Champs créés :"
  echo "    nom, telephone, ville, rappel"
  echo "    pack, kwh, batiment, objectif"
  echo "    appareils (JSON), source (desktop/mobile)"
  echo ""
  echo "  Règle d'accès :"
  echo "    CREATE → public (tout le monde peut soumettre)"
  echo "    LIST / VIEW / UPDATE / DELETE → admin seulement"
  echo ""
  echo "  Admin UI : https://simulateur.innoveagroup.tech/_pb/_/"
  echo "═══════════════════════════════════════════════════"
else
  echo "ERREUR (HTTP $HTTP_CODE) :"
  cat /tmp/pb_response.json
  echo ""
  echo "Si la collection existe déjà, c'est normal."
fi
