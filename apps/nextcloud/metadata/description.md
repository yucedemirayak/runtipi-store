# Nextcloud

Nextcloud is a private cloud suite for file sync, calendar, contacts and collaboration.

## Defaults (with existing Runtipi Postgres)

- Port: `8080`
- Data path: `${APP_DATA_DIR}/data`
- PostgreSQL host: `${TIPI_NEXTCLOUD_DB_HOST}` (default `postgres`)
- PostgreSQL DB: `${TIPI_NEXTCLOUD_DB_NAME}` (default `app`)
- PostgreSQL user: `${TIPI_NEXTCLOUD_DB_USER}` (default `postgres`)
- PostgreSQL password: `${TIPI_NEXTCLOUD_DB_PASSWORD}`

## Notes

- This app connects to the existing `postgres` service in your Runtipi stack.
- Postgres must be running before Nextcloud migration completes.
