# Netdata

Lightweight real-time monitoring with a built-in web dashboard for:

- CPU, RAM, disk and network metrics
- Docker container visibility
- Alert and health states
- Web-based historical charts

## Defaults

- Internal port: `19999`
- Host port: app port (default `19999`)
- Persistent paths:
  - `${APP_DATA_DIR}/config` -> `/etc/netdata`
  - `${APP_DATA_DIR}/lib` -> `/var/lib/netdata`
  - `${APP_DATA_DIR}/cache` -> `/var/cache/netdata`

## Notes

The container mounts `/var/run/docker.sock` read-only to show container metrics automatically.
