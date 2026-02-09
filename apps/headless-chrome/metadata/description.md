# Headless Chrome

Browserless Chrome container for automation workloads such as PDF generation, screenshotting and rendering.

## Defaults

- Internal port: `3000`
- Host port: app port (default `3001`)
- Token env: `TIPI_HEADLESS_CHROME_TOKEN`

## Reactive Resume integration

Use these values in Reactive Resume:

- `CHROME_URL`: `ws://headless-chrome:3000`
- `CHROME_TOKEN`: same token value from this app
