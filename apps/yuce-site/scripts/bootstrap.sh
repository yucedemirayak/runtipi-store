#!/bin/sh
set -eu

echo "[yuce-site] Preparing runtime packages..."
apk add --no-cache git python3 py3-pip py3-flask py3-psutil >/dev/null 2>&1

echo "[yuce-site] Preparing pnpm..."
corepack enable >/dev/null 2>&1 || true
corepack prepare pnpm@latest --activate >/dev/null 2>&1 || true

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "[yuce-site] ERROR: GITHUB_TOKEN is not set."
  exit 1
fi

if [ -z "${WEBHOOK_SECRET:-}" ]; then
  echo "[yuce-site] ERROR: WEBHOOK_SECRET is not set."
  exit 1
fi

PROJECT_DIR="/home/site"
REPO_URL="${REPO_URL:-https://github.com/yucedemirayak/yucedemirayak.com-next.git}"
REPO_BRANCH="${REPO_BRANCH:-master}"
APP_START_CMD="${APP_START_CMD:-pnpm start}"

AUTH_REPO_URL="${REPO_URL}"
case "${REPO_URL}" in
  https://github.com/*)
    # Use PAT over HTTPS for git clone/fetch on GitHub.
    AUTH_REPO_URL="$(printf '%s' "${REPO_URL}" | sed "s#^https://github.com/#https://x-access-token:${GITHUB_TOKEN}@github.com/#")"
    ;;
esac

mkdir -p "${PROJECT_DIR}"

if [ ! -d "${PROJECT_DIR}/.git" ]; then
  echo "[yuce-site] Cloning repository..."
  git clone --depth=1 -b "${REPO_BRANCH}" "${AUTH_REPO_URL}" "${PROJECT_DIR}"
  git -C "${PROJECT_DIR}" remote set-url origin "${REPO_URL}"
else
  echo "[yuce-site] Pulling repository..."
  git -C "${PROJECT_DIR}" remote set-url origin "${AUTH_REPO_URL}"
  git -C "${PROJECT_DIR}" fetch --prune origin "${REPO_BRANCH}"
  git -C "${PROJECT_DIR}" checkout -B "${REPO_BRANCH}" "origin/${REPO_BRANCH}"
  git -C "${PROJECT_DIR}" remote set-url origin "${REPO_URL}"
fi

cd "${PROJECT_DIR}"

echo "[yuce-site] Installing dependencies..."
pnpm install

echo "[yuce-site] Building app..."
pnpm build

echo "[yuce-site] Starting app command: ${APP_START_CMD}"
sh -lc "${APP_START_CMD}" &

echo "[yuce-site] Starting webhook server..."
exec python3 /scripts/webhook.py
