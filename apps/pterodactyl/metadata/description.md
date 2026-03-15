# Pterodactyl (Panel + Wings)

This app bundles Pterodactyl Panel and Wings daemon into a single deployment for single-node setups. Everything is pre-configured — just fill in admin credentials and you're ready to go.

- **Panel** — Web interface for managing game servers
- **Wings** — Node daemon that runs game server containers
- **MariaDB** — Dedicated database (built-in)
- **Redis** — Cache and queue backend (built-in)

## Setup

1. Fill in admin email, username, and password in the form.
2. Install the app — everything else is automatic:
   - APP_KEY is generated on first boot
   - Database and Redis are pre-configured
   - A default node and Wings config are created automatically
3. Open the Panel and log in with your admin credentials.

## Creating a game server

1. Go to **Admin → Nodes → Default Node → Allocation**
2. Add an allocation: IP `0.0.0.0`, port as needed (e.g. `25565` for Minecraft)
3. Go to **Admin → Servers → Create Server** and select the allocation
4. Connect to your game server via `<your-ip>:<port>`

## Ports

| Service | Host Port | Container Port |
|---------|-----------|---------------|
| Panel | 8800 | 80 |
| Wings API | 8081 | 8080 |
| SFTP | 2022 | 2022 |
