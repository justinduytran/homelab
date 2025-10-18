#!/usr/bin/env bash
set -euo pipefail

INPUT_FILE="services.csv"
ADD_SERVICE_SCRIPT="./create_service.sh"
WILDCARD_SCRIPT="./create_wildcard.sh"
CATCHALL_SCRIPT="./create_catch_all.sh"

# Set nginx directories
export SITES_AVAILABLE="/etc/nginx/sites-available"
export SITES_ENABLED="/etc/nginx/sites-enabled"

# Delete old config files
echo ""
echo "🧹 Cleaning up old configs in $SITES_AVAILABLE and $SITES_ENABLED..."
rm -f "${SITES_AVAILABLE}"/*.conf
rm -f "${SITES_ENABLED}"/*.conf

declare -A seen_domains
# Read CSV and avoid subshell by using redirection instead of a pipe
{
    read -r _ # skip header
    while IFS=',' read -r service domain port target_host optional_flag proxy_subpath; do
        echo ""
        echo "🔧  Processing service: $service.$domain"

        "$ADD_SERVICE_SCRIPT" "$service" "$domain" "$port" "$target_host" "$optional_flag" "$proxy_subpath"

        # Store domain in associative array
        seen_domains["$domain"]=1
    done
} < "$INPUT_FILE"

echo ""
echo "🌐 Generating wildcard configs for unique domains..."

for domain in "${!seen_domains[@]}"; do
    echo ""
    echo "🔧 Creating wildcard config for: *.$domain"
    "$WILDCARD_SCRIPT" "$domain"
done

# Add catch-all using the https cert for an arbitrary (first) domain
FIRST_DOMAIN=""
for domain in "${!seen_domains[@]}"; do
    FIRST_DOMAIN="$domain"
    break
done

if [[ -n "$FIRST_DOMAIN" ]]; then
    echo ""
    echo "🛡  Creating catch-all config using cert for: $FIRST_DOMAIN"
    "$CATCHALL_SCRIPT" "$FIRST_DOMAIN"
else
    echo "⚠️  No domains found to use for catch-all SSL cert. Skipping."
fi

# Test and restart nginx
echo ""
echo "🔁 Testing Nginx configuration..."
if nginx -t; then
    echo "✅ Nginx configuration is valid. Reloading..."
    systemctl reload nginx
    echo "🚀 Nginx reloaded successfully."
else
    echo "❌ Nginx configuration test failed! Fix the issues above and try again."
    exit 1
fi
