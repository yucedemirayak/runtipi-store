PostgreSQL is a powerful open-source relational database.

This app has no web UI.

Connection defaults:
- Host: your Tipi host
- Port: `${APP_PORT}`
- User: `${TIPI_POSTGRES_USER}`
- Password: `${TIPI_POSTGRES_PASSWORD}`
- Database: `${TIPI_POSTGRES_DB}`

Persistent data:
- Host: `${APP_DATA_DIR}/data`
- Container: `/var/lib/postgresql/data`
