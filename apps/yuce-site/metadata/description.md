# Yuce Site

Container that runs `git pull`, `pnpm install`, `pnpm build` and your start command when a signed webhook arrives.

## Requirements

- GitHub token with read access to repository.
- Webhook secret must match GitHub webhook secret.
- `Webhook Port` must be reachable from GitHub.

## Ports

- App: `${APP_PORT}` -> container `3000`
- Webhook: `${TIPI_YUCE_SITE_WEBHOOK_PORT}` -> container `5000`

## Notes

- Persistent data: `${APP_DATA_DIR}/site`
- Webhook endpoint: `/webhook`
- Startup script lives under app `./scripts` and is mounted read-only.
