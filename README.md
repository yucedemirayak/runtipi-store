# yucedmryk Runtipi Store

Kisisel Runtipi app-store reposu.

## Yapi

- `apps/app-info-schema.json`
- `apps/dynamic-compose-schema.json`
- `apps/cloudbeaver/`
  - `config.json`
  - `docker-compose.json`
  - `docker-compose.yml`
  - `metadata/description.md`
  - `metadata/logo.jpg`

## App'ler

- `cloudbeaver`
- `git-webhook-deploy`
- `headless-chrome`
- `mariadb`
- `playit-agent`
- `postgres`
- `reactive-resume`
- `redis`
- `wordpress`
- `yuce-site`

## Runtipi'ye ekleme

1. Bu repoyu GitHub'a push et.
2. Runtipi panelinde App Store/Repositories kismina repo URL'ini ekle.
3. Sync/Refresh yap.
4. Yukaridaki uygulamalar listede gorunur.

## Not

Her app kendi `apps/<app-id>/` klasorunden okunur.
