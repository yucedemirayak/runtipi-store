# Playit Agent

Playit creates secure outbound tunnels so you can expose local services without opening router ports.

## First Start

- Install the app and open **Logs**.
- If no secret is configured, the container runs `playit setup`.
- Follow the claim URL shown in logs and approve the agent in your Playit account.

## Optional Secret Key

You can also set `TIPI_PLAYIT_AGENT_SECRET_KEY` in app settings. If provided, the agent starts directly with that key.

## Persistent Data

- Secret/config path inside container: `/root/.config/playit_gg`
- Stored on host: `${APP_DATA_DIR}/data`
