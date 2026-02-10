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

mkdir -p "${PROJECT_DIR}"

if [ ! -d "${PROJECT_DIR}/.git" ]; then
  echo "[yuce-site] Cloning repository..."
  git -c "http.extraHeader=Authorization: Bearer ${GITHUB_TOKEN}" \
    clone --depth=1 -b "${REPO_BRANCH}" "${REPO_URL}" "${PROJECT_DIR}"
else
  echo "[yuce-site] Pulling repository..."
  git -C "${PROJECT_DIR}" fetch --all --prune
  git -C "${PROJECT_DIR}" checkout "${REPO_BRANCH}"
  git -C "${PROJECT_DIR}" -c "http.extraHeader=Authorization: Bearer ${GITHUB_TOKEN}" pull --ff-only
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
