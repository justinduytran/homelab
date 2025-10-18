#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <domain>"
    exit 1
fi

DOMAIN="$1"

SITES_AVAILABLE="${SITES_AVAILABLE:?SITES_AVAILABLE not set}"
SITES_ENABLED="${SITES_ENABLED:?SITES_ENABLED not set}"

OUTFILE="${SITES_AVAILABLE}/zz-wildcard.${DOMAIN}.conf"
ENABLED_LINK="${SITES_ENABLED}/zz-wildcard.${DOMAIN}.conf"

cat > "$OUTFILE" << EOF
# Wildcard catcher for $DOMAIN

server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name *.${DOMAIN};

    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    location / {
        return 404;
    }
}

server {
    listen 80;
    listen [::]:80;
    server_name *.${DOMAIN};

    return 301 https://\$host\$request_uri;
}
EOF

ln -sfn "$OUTFILE" "$ENABLED_LINK"

echo "✅ Wildcard config created: $OUTFILE"
