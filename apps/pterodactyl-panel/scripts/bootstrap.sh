#!/bin/sh
set -eu

log() {
  echo "[pterodactyl-panel] $*"
}

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

exec /bin/ash /app/.github/docker/entrypoint.sh "$@"
