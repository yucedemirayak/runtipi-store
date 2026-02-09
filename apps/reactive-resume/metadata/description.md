# Reactive Resume

Reactive Resume with external dependencies.

## Expected external services (already installed)

- PostgreSQL
- Redis
- MinIO
- Headless Chrome (Browserless)

## Defaults in this app

Defaults are aligned with your existing app defaults:

- PostgreSQL: `postgresql://postgres:postgres@postgres:5432/app`
- Redis: `redis://default:redispass@redis:6379`
- MinIO access: `minioadmin / minioadmin`
- Chrome token: `chrome_token`

## Important

If you access the app from a different hostname/port, set `Public URL` and `Storage URL` accordingly.
