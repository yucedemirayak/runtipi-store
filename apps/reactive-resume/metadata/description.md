# Reactive Resume

Reactive Resume (v5) configured to use external services.

## Expected external services

- PostgreSQL
- MinIO (S3 compatible storage)
- Headless Chrome (Browserless)

## Defaults in this app

Defaults are aligned with your current setup:

- PostgreSQL: `postgresql://postgres:postgres@postgres:5432/app`
- MinIO endpoint: `http://minio:9000`
- MinIO access: `minioadmin / minioadmin`
- MinIO bucket: `default`
- Printer endpoint: `ws://headless-chrome:3000?token=chrome_token`

## Important

If you access the app from a different hostname/port, set `Public URL` accordingly.
