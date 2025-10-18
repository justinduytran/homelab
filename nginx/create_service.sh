#!/usr/bin/env bash
set -euo pipefail

# === USAGE ===
# ./add-service.sh <service> <domain> <port> <target_host> [--websockets] [proxy_subpath]

SERVICE="$1"
DOMAIN="$2"
PORT="$3"
TARGET_HOST="$4"
OPTIONAL="${5:-}"
PROXY_SUBPATH="${6:-}"

SITES_AVAILABLE="${SITES_AVAILABLE:?SITES_AVAILABLE not set}"
SITES_ENABLED="${SITES_ENABLED:?SITES_ENABLED not set}"

OUTFILE="${SITES_AVAILABLE}/${SERVICE}.${DOMAIN}.conf"
ENABLED_LINK="${SITES_ENABLED}/${SERVICE}.${DOMAIN}.conf"

# Optional: WebSockets flag
WEBSOCKET_HEADERS=""
if [[ "$OPTIONAL" == "--websockets" ]]; then
    WEBSOCKET_HEADERS=$(cat << 'EOF'
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
EOF
    )
fi

# Optional: proxy_redirect logic
PROXY_REDIRECT_LINE=""
if [[ -n "$PROXY_SUBPATH" ]]; then
    PROXY_REDIRECT_LINE="proxy_redirect /${PROXY_SUBPATH}/ /;"
fi

# Write config
cat > "$OUTFILE" << EOF
# Nginx config for $SERVICE.$DOMAIN

server {
    listen 80;
    listen [::]:80;
    server_name ${SERVICE}.${DOMAIN};

    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name ${SERVICE}.${DOMAIN};

    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    location / {
        proxy_pass http://${TARGET_HOST}:${PORT};

        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-Host \$server_name;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Ssl on;
        proxy_read_timeout 600s;
        proxy_send_timeout 600s;

${WEBSOCKET_HEADERS}

        ${PROXY_REDIRECT_LINE}
    }
}
EOF

# Enable the config
ln -sfn "$OUTFILE" "$ENABLED_LINK"

echo "✅ Created config: $OUTFILE"
echo "✅ Enabled: $ENABLED_LINK"