#!/bin/bash
cp /var/www/simulsolaire/deploy/nginx.conf /etc/nginx/sites-available/simulsolaire
nginx -t && systemctl reload nginx && echo "Nginx OK"
