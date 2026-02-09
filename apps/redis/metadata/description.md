# Redis

Redis is an in-memory key-value data store used for caching, message brokering, and fast data access.

## Default settings

- Port: `6379`
- Data path: `${APP_DATA_DIR}/data`
- Persistence: AOF enabled (`appendonly yes`)
- Authentication: Password required via `TIPI_REDIS_PASSWORD`

## Connect examples

- Host: `redis`
- Port: `6379`
- Password: value set in the app form
