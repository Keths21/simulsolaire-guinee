#!/bin/bash
echo "==> Test v0.22+ endpoint"
curl -s \
  -X POST http://127.0.0.1:8090/api/collections/_superusers/auth-with-password \
  -H "Content-Type: application/json" \
  -d '{"identity":"keita.elhadj@gmail.com","password":"1985keita"}'
echo ""
