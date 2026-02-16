#!/bin/sh
set -eu

log() {
  echo "[git-webhook-deploy] $*"
}

log "Installing runtime dependencies..."
apk add --no-cache git >/dev/null 2>&1

log "Preparing package manager runtime..."
corepack enable >/dev/null 2>&1 || true

case "${PACKAGE_MANAGER:-npm}" in
  pnpm)
    corepack prepare pnpm@latest --activate >/dev/null 2>&1 || true
    ;;
  yarn)
    corepack prepare yarn@stable --activate >/dev/null 2>&1 || true
    ;;
esac

if [ -z "${REPO_URL:-}" ]; then
  log "ERROR: REPO_URL is required."
  exit 1
fi

mkdir -p /home/site

if [ "${DEPLOY_ON_STARTUP:-true}" = "true" ]; then
  log "Running initial deploy..."
  /scripts/deploy.sh
else
  log "Skipping initial deploy."
fi

if [ -n "${WEBHOOK_SECRET:-}" ]; then
  log "Starting webhook server on 0.0.0.0:${WEBHOOK_PORT:-5000}${WEBHOOK_PATH:-/webhook}"
  exec node /scripts/webhook.mjs
fi

log "Webhook listener disabled (WEBHOOK_SECRET is empty)."
log "To redeploy without webhook, restart the container."

pid=""
if [ -f /home/site/app.pid ]; then
  pid="$(cat /home/site/app.pid 2>/dev/null || true)"
fi

if [ -n "${pid}" ] && kill -0 "${pid}" 2>/dev/null; then
  log "Running in no-webhook mode while app process is alive (pid=${pid})."
  while kill -0 "${pid}" 2>/dev/null; do
    sleep 5
  done
  log "App process exited."
  exit 1
fi

log "No running app process found. Keeping container alive in no-webhook mode."
exec tail -f /dev/null
