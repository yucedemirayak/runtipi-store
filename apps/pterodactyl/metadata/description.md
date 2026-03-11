# Pterodactyl (Panel + Wings)

This app bundles Pterodactyl Panel and Wings daemon into a single deployment for single-node setups.

- **Panel** — Web interface for managing game servers
- **Wings** — Node daemon that runs game server containers
- **MariaDB** — Dedicated database (built-in)
- **Redis** — Cache and queue backend (built-in)

## First setup

1. Generate an app key: `base64:$(openssl rand -base64 32)`
2. Fill form fields with app key and other values. Database and Redis are pre-configured.
4. Open the panel URL and complete setup.
5. Create the first admin account:
   ```
   docker exec -it pterodactyl php artisan p:user:make
   ```

## Wings configuration

1. In Panel, create a node and generate its `config.yml`.
2. Place the file at `${APP_DATA_DIR}/wings-etc/config.yml`.
3. Restart the app.
4. Panel reaches Wings internally at `http://pterodactyl-wings:8080`.

## Ports

| Service | Host Port | Container Port |
|---------|-----------|---------------|
| Panel | `${APP_PORT}` (default 8800) | 80 |
| Wings API | 8081 | 8080 |
| SFTP | `${TIPI_PTERODACTYL_SFTP_PORT}` (default 2022) | 2022 |

## Persistent data

| Host Path | Container Path | Service |
|-----------|---------------|---------|
| `${APP_DATA_DIR}/panel-var` | `/app/var` | Panel |
| `${APP_DATA_DIR}/panel-logs` | `/app/storage/logs` | Panel |
| `${APP_DATA_DIR}/panel-nginx` | `/etc/nginx/http.d` | Panel |
| `${APP_DATA_DIR}/panel-certs` | `/etc/letsencrypt` | Panel |
| `${APP_DATA_DIR}/wings-etc` | `/etc/pterodactyl` | Wings |
| `${APP_DATA_DIR}/wings-logs` | `/var/log/pterodactyl` | Wings |
| `/var/lib/pterodactyl` | `/var/lib/pterodactyl` | Wings (game data) |
| `${APP_DATA_DIR}/db-data` | `/var/lib/mysql` | MariaDB |
| `${APP_DATA_DIR}/redis-data` | `/data` | Redis |
