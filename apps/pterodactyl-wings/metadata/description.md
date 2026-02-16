# Pterodactyl Wings

Wings is the node daemon used by Pterodactyl Panel to run game server containers.

## Setup flow

1. Install `pterodactyl-panel` first.
2. In Panel, create a node and generate its `config.yml`.
3. Place the file at `${APP_DATA_DIR}/etc/config.yml` for this app.
4. Restart Wings app.

## Ports

- API/daemon: `${APP_PORT}` -> `8080`
- SFTP: `${TIPI_PTERODACTYL_WINGS_SFTP_PORT}` -> `2022`

## Required host mounts

- Docker socket and Docker containers are mounted so Wings can manage game server containers.
