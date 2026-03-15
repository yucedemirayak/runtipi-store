#!/bin/sh
set -eu

log() {
  echo "[pterodactyl] $*"
}

# Auto-generate APP_KEY if not set, persist across restarts
KEY_FILE="/app/var/.app_key"
if [ -z "${APP_KEY:-}" ]; then
  if [ -f "$KEY_FILE" ]; then
    export APP_KEY=$(cat "$KEY_FILE")
    log "Loaded APP_KEY from persistent storage."
  else
    export APP_KEY="base64:$(openssl rand -base64 32)"
    mkdir -p /app/var
    echo "$APP_KEY" > "$KEY_FILE"
    log "Generated new APP_KEY and saved to persistent storage."
  fi
fi

if ! command -v mysql >/dev/null 2>&1; then
  log "mysql client missing, installing mariadb-client..."

  if command -v apk >/dev/null 2>&1; then
    apk add --no-cache mariadb-client
  elif command -v apt-get >/dev/null 2>&1; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends default-mysql-client
    rm -rf /var/lib/apt/lists/*
  else
    log "No supported package manager found, cannot install mysql client."
    exit 1
  fi
fi

if [ ! -f /app/.github/docker/entrypoint.sh ]; then
  log "Original panel entrypoint not found at /app/.github/docker/entrypoint.sh."
  exit 1
fi

# Create a post-setup script that creates admin user then starts supervisord.
# The original entrypoint runs migrations and execs its $@ at the end,
# so we pass this script as the command instead of supervisord directly.
cat > /tmp/post-setup.sh << 'POSTEOF'
#!/bin/sh
set -eu

log() {
  echo "[pterodactyl] $*"
}

if [ -n "${PTERODACTYL_ADMIN_EMAIL:-}" ] && \
   [ -n "${PTERODACTYL_ADMIN_USERNAME:-}" ] && \
   [ -n "${PTERODACTYL_ADMIN_PASSWORD:-}" ]; then

  # Check if any admin user already exists
  admin_count=$(php artisan tinker --execute="echo \Pterodactyl\Models\User::where('root_admin', 1)->count();" 2>/dev/null || echo "")

  if [ "$admin_count" = "0" ]; then
    log "Creating admin user: ${PTERODACTYL_ADMIN_USERNAME} (${PTERODACTYL_ADMIN_EMAIL})"
    php artisan p:user:make \
      --email="${PTERODACTYL_ADMIN_EMAIL}" \
      --username="${PTERODACTYL_ADMIN_USERNAME}" \
      --name-first="Admin" \
      --name-last="User" \
      --password="${PTERODACTYL_ADMIN_PASSWORD}" \
      --admin=1 \
      --no-interaction
    log "Admin user created successfully."
  else
    log "Admin user already exists, skipping creation."
  fi
else
  log "Admin credentials not set, skipping admin user creation."
fi

# Auto-create default node and write Wings config.yml
if [ -f /scripts/setup-node.php ]; then
  log "Running node auto-setup..."
  php /app/artisan tinker --execute="require('/scripts/setup-node.php');" 2>&1 || \
    log "Node auto-setup failed (non-fatal). You can configure manually via Panel UI."
else
  log "setup-node.php not found, skipping node auto-setup."
fi

exec supervisord -n -c /etc/supervisord.conf
POSTEOF

chmod +x /tmp/post-setup.sh

exec /bin/ash /app/.github/docker/entrypoint.sh /bin/sh /tmp/post-setup.sh
