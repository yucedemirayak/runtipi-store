# Git Webhook Deploy

Deploy web projects from signed GitHub webhooks.

## Supported presets

- Next.js
- React (Vite)
- React (CRA)
- Static HTML
- Custom commands

## How it works

- Clones the configured repository and branch
- Runs install/build/start commands (preset or overrides)
- Serves the app on container port `3000`
- Listens for GitHub webhook `push` events and redeploys target branch

If `Webhook Secret` is left empty:

- The app does an initial deploy on container start (if enabled)
- Webhook listener is disabled
- Redeploy is triggered by restarting the container

## Ports

- App: `${APP_PORT}` -> container `${TIPI_GIT_WEBHOOK_DEPLOY_SITE_PORT}`
- Webhook: configurable host port -> container `5000`

## Notes

- Set a strong `Webhook Secret` to enable auto-deploy on pushes.
- For private GitHub repositories, provide `Git Token`.
- Default webhook path is `/webhook`.
- Runtime logs and PID file are stored under `${APP_DATA_DIR}/site`.
