# Pterodactyl Panel

Pterodactyl Panel is the web interface used to manage nodes and game servers.

## Requirements

- `mariadb` app running
- `redis` app running
- A dedicated MariaDB database/user for Pterodactyl

## First setup

1. Create a database and user in MariaDB, then grant privileges.
2. Generate an app key (example: `base64:$(openssl rand -base64 32)`).
3. Fill panel form fields with app key, DB, and Redis values.
4. Open the panel URL and complete setup.
5. Create the first admin account:
   - `docker exec -it pterodactyl-panel php artisan p:user:make`

## Persistent data

- `${APP_DATA_DIR}/var` -> `/app/var`
- `${APP_DATA_DIR}/logs` -> `/app/storage/logs`
- `${APP_DATA_DIR}/nginx` -> `/etc/nginx/http.d`
- `${APP_DATA_DIR}/certs` -> `/etc/letsencrypt`
