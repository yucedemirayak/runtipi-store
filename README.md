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
- `postgres`
- `mariadb`

## Runtipi'ye ekleme

1. Bu repoyu GitHub'a push et.
2. Runtipi panelinde App Store/Repositories kismina repo URL'ini ekle.
3. Sync/Refresh yap.
4. `cloudbeaver` uygulamasi listede gorunecek.

## Not

CloudBeaver verisi asagidaki path'te kalicidir:
- Host: `${APP_DATA_DIR}/data`
- Container: `/opt/cloudbeaver/workspace`
