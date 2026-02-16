#!/bin/sh
set -eu

log() {
  echo "[pterodactyl-wings] $*"
}

CONFIG_FILE="/etc/pterodactyl/config.yml"

if [ ! -f "${CONFIG_FILE}" ]; then
  log "Missing ${CONFIG_FILE}."
  log "Create a node in Pterodactyl Panel, copy the generated config.yml and place it in ${CONFIG_FILE}."
  log "Container will stay alive so you can add the file and restart the app."
  exec tail -f /dev/null
fi

if command -v wings >/dev/null 2>&1; then
  exec wings
fi

if [ -x /usr/local/bin/wings ]; then
  exec /usr/local/bin/wings
fi

log "Wings binary not found in container image."
exit 1
