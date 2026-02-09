PostgreSQL is a powerful open-source relational database.

This app has no web UI.

Connection defaults:
- Host: your Tipi host
- Port: `${APP_PORT}`
- User: `${POSTGRES_USER}`
- Password: `${POSTGRES_PASSWORD}`
- Database: `${POSTGRES_DB}`

Persistent data:
- Host: `${APP_DATA_DIR}/data`
- Container: `/var/lib/postgresql/data`
