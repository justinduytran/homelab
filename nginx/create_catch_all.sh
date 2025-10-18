#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <domain-for-ssl-cert>"
    exit 1
fi

DOMAIN="$1"

SITES_AVAILABLE="${SITES_AVAILABLE:?SITES_AVAILABLE not set}"
SITES_ENABLED="${SITES_ENABLED:?SITES_ENABLED not set}"

OUTFILE="${SITES_AVAILABLE}/zzz-catch-all.conf"
ENABLED_LINK="${SITES_ENABLED}/zzz-catch-all.conf"

cat > "$OUTFILE" << EOF
# Default catch-all HTTPS server

server {
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;
    server_name _;

    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;

    return 444;
}

# Default catch-all HTTP server

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    return 444;
}
EOF

ln -sfn "$OUTFILE" "$ENABLED_LINK"

echo "✅ Catch-all config created: $OUTFILE"
