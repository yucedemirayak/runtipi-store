#!/bin/sh
set -eu

log() {
  echo "[git-webhook-deploy] $*"
}

LOCK_DIR="/tmp/git-webhook-deploy.lock"
if ! mkdir "${LOCK_DIR}" 2>/dev/null; then
  log "Deploy already in progress, skipping trigger."
  exit 0
fi

cleanup() {
  rmdir "${LOCK_DIR}" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

PROJECT_DIR="/home/site/repo"
PID_FILE="/home/site/app.pid"
APP_LOG_FILE="/home/site/app.log"

REPO_URL="${REPO_URL:-}"
REPO_BRANCH="${REPO_BRANCH:-main}"
GIT_TOKEN="${GIT_TOKEN:-}"
FRAMEWORK="${FRAMEWORK:-nextjs}"
PACKAGE_MANAGER="${PACKAGE_MANAGER:-npm}"
INSTALL_CMD="${INSTALL_CMD:-}"
BUILD_CMD="${BUILD_CMD:-}"
START_CMD="${START_CMD:-}"
SITE_PORT="${SITE_PORT:-3000}"

if [ -z "${REPO_URL}" ]; then
  log "REPO_URL is required."
  exit 1
fi

case "${PACKAGE_MANAGER}" in
  npm|pnpm|yarn)
    ;;
  *)
    log "Unsupported PACKAGE_MANAGER: ${PACKAGE_MANAGER}"
    exit 1
    ;;
esac

case "${FRAMEWORK}" in
  nextjs|react-vite|react-cra|static-html|custom)
    ;;
  *)
    log "Unsupported FRAMEWORK: ${FRAMEWORK}"
    exit 1
    ;;
esac

if [ "${FRAMEWORK}" = "custom" ] && [ -z "${START_CMD}" ]; then
  log "START_CMD is required when FRAMEWORK=custom."
  exit 1
fi

is_github_https_repo() {
  case "${REPO_URL}" in
    https://github.com/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

log_auth_hint() {
  if [ -z "${GIT_TOKEN}" ] && is_github_https_repo; then
    log "Auth failed. If the repo is private, set Git Token with read access."
  fi
}

auth_repo_url() {
  if [ -n "${GIT_TOKEN}" ] && is_github_https_repo; then
    printf '%s' "${REPO_URL}" | sed "s#^https://github.com/#https://x-access-token:${GIT_TOKEN}@github.com/#"
  else
    printf '%s' "${REPO_URL}"
  fi
}

git_fetch_branch() {
  if [ -n "${GIT_TOKEN}" ] && is_github_https_repo; then
    git -C "${PROJECT_DIR}" -c "http.extraHeader=Authorization: Bearer ${GIT_TOKEN}" fetch --prune origin "${REPO_BRANCH}"
  else
    git -C "${PROJECT_DIR}" fetch --prune origin "${REPO_BRANCH}"
  fi
}

pm_install() {
  case "${PACKAGE_MANAGER}" in
    npm)
      if [ -f package-lock.json ]; then
        npm ci || npm install
      else
        npm install
      fi
      ;;
    pnpm)
      pnpm install --frozen-lockfile || pnpm install
      ;;
    yarn)
      yarn install --frozen-lockfile || yarn install
      ;;
  esac
}

pm_run() {
  script_name="$1"
  shift

  case "${PACKAGE_MANAGER}" in
    npm)
      npm run "${script_name}" -- "$@"
      ;;
    pnpm)
      pnpm run "${script_name}" -- "$@"
      ;;
    yarn)
      yarn "${script_name}" "$@"
      ;;
  esac
}

run_install() {
  if [ -n "${INSTALL_CMD}" ]; then
    log "Running install override command..."
    sh -lc "${INSTALL_CMD}"
    return
  fi

  if [ -f package.json ]; then
    log "Running default install command (${PACKAGE_MANAGER})..."
    pm_install
  else
    log "No package.json found, skipping install."
  fi
}

run_build() {
  if [ -n "${BUILD_CMD}" ]; then
    log "Running build override command..."
    sh -lc "${BUILD_CMD}"
    return
  fi

  case "${FRAMEWORK}" in
    nextjs|react-vite|react-cra)
      if [ -f package.json ]; then
        log "Running default build command (${FRAMEWORK})..."
        pm_run build
      else
        log "No package.json found, cannot run default build."
        exit 1
      fi
      ;;
    static-html|custom)
      log "No default build step for framework: ${FRAMEWORK}."
      ;;
  esac
}

stop_running_app() {
  if [ -f "${PID_FILE}" ]; then
    old_pid="$(cat "${PID_FILE}" 2>/dev/null || true)"
    if [ -n "${old_pid}" ] && kill -0 "${old_pid}" 2>/dev/null; then
      log "Stopping previous app process (pid=${old_pid})..."
      kill "${old_pid}" 2>/dev/null || true
      sleep 1
      if kill -0 "${old_pid}" 2>/dev/null; then
        kill -9 "${old_pid}" 2>/dev/null || true
      fi
    fi
  fi
}

start_app() {
  if [ -n "${START_CMD}" ]; then
    log "Starting app using start override command..."
    sh -lc "${START_CMD}" >>"${APP_LOG_FILE}" 2>&1 &
    new_pid="$!"
    echo "${new_pid}" > "${PID_FILE}"
    return
  fi

  case "${FRAMEWORK}" in
    nextjs)
      log "Starting Next.js app on port ${SITE_PORT}..."
      (pm_run start -H 0.0.0.0 -p "${SITE_PORT}") >>"${APP_LOG_FILE}" 2>&1 &
      ;;
    react-vite)
      log "Serving Vite dist/ on port ${SITE_PORT}..."
      (npx --yes serve -s dist -l "tcp://0.0.0.0:${SITE_PORT}") >>"${APP_LOG_FILE}" 2>&1 &
      ;;
    react-cra)
      log "Serving CRA build/ on port ${SITE_PORT}..."
      (npx --yes serve -s build -l "tcp://0.0.0.0:${SITE_PORT}") >>"${APP_LOG_FILE}" 2>&1 &
      ;;
    static-html)
      log "Serving repository root as static files on port ${SITE_PORT}..."
      (npx --yes serve -s . -l "tcp://0.0.0.0:${SITE_PORT}") >>"${APP_LOG_FILE}" 2>&1 &
      ;;
    custom)
      log "FRAMEWORK=custom requires START_CMD."
      exit 1
      ;;
  esac

  new_pid="$!"
  echo "${new_pid}" > "${PID_FILE}"

  sleep 2
  if ! kill -0 "${new_pid}" 2>/dev/null; then
    log "App process exited immediately after startup. Check app log output below."
    tail -n 80 "${APP_LOG_FILE}" 2>/dev/null || true
    exit 1
  fi
}

log "Deploy started (branch=${REPO_BRANCH}, framework=${FRAMEWORK}, pm=${PACKAGE_MANAGER})"

mkdir -p /home/site

if [ ! -d "${PROJECT_DIR}/.git" ]; then
  log "Cloning repository..."
  if ! git clone --depth=1 -b "${REPO_BRANCH}" "$(auth_repo_url)" "${PROJECT_DIR}"; then
    log_auth_hint
    exit 1
  fi
  git -C "${PROJECT_DIR}" remote set-url origin "${REPO_URL}"
else
  # Ensure origin matches current settings before any fetch.
  git -C "${PROJECT_DIR}" remote set-url origin "${REPO_URL}"
  log "Fetching latest changes..."
  if ! git_fetch_branch; then
    log "Fetch failed. Trying clean repository clone..."
    log_auth_hint
    rm -rf "${PROJECT_DIR}"
    if ! git clone --depth=1 -b "${REPO_BRANCH}" "$(auth_repo_url)" "${PROJECT_DIR}"; then
      log_auth_hint
      exit 1
    fi
  else
    git -C "${PROJECT_DIR}" checkout -B "${REPO_BRANCH}" "origin/${REPO_BRANCH}"
  fi
  git -C "${PROJECT_DIR}" remote set-url origin "${REPO_URL}"
fi

cd "${PROJECT_DIR}"

run_install
run_build

stop_running_app
start_app

log "Deploy completed successfully."
