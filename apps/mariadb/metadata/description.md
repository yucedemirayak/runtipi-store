MariaDB is an open-source relational database system compatible with MySQL.

This app has no web UI.

Connection defaults:
- Host: your Tipi host
- Port: `${APP_PORT}`
- Root Password: `${TIPI_MARIADB_ROOT_PASSWORD}`
- Database: `${TIPI_MARIADB_DATABASE}`
- User: `${TIPI_MARIADB_USER}`
- Password: `${TIPI_MARIADB_PASSWORD}`

Persistent data:
- Host: `${APP_DATA_DIR}/data`
- Container: `/var/lib/mysql`
