#!/bin/sh
set -e

# Auto-generate password if not set
if [ -z "$BASIC_AUTH_PASSWORD" ]; then
  BASIC_AUTH_PASSWORD=$(head -c 16 /dev/urandom | base64)
  echo "Generated BASIC_AUTH_PASSWORD: $BASIC_AUTH_PASSWORD"
fi

# Hash the password
HASHED_PASS=$(caddy hash-password --plaintext "$BASIC_AUTH_PASSWORD")

# Export for envsubst
export DOMAIN_NAME SSL_CONFIG BASIC_AUTH_USER HASHED_PASS

# Render Caddyfile from template
envsubst < /Caddyfile.template > /etc/caddy/Caddyfile

# Start Caddy
exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile