# WordPress

WordPress running as a standalone app with an external MariaDB/MySQL database.

## Defaults

- Port: `8088`
- Data path: `${APP_DATA_DIR}/data`
- DB host: `mariadb:3306`
- DB name: `app`
- DB user: `mariadb`
- DB password: `mariadbpass`

## Notes

- Ensure your MariaDB app is running before installing WordPress.
- For multiple WordPress instances on one Runtipi, duplicate this app with another id (for example `wordpress-2`) and different port/database.
