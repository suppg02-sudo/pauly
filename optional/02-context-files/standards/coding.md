# Coding Standards

## Shell Scripts

- Always `set -euo pipefail` at top
- Use `${VAR:-default}` for all env-driven values
- Read from `.env`: `source /opt/pauly/.env`
- No hardcoded ports or URLs — always `${PORT_*}` or `${SERVER_IP}`
- Functions with clear names: `check_health()`, `backup_db()`, `send_alert()`

## Docker Compose

- All ports via `${VAR:-default}` pattern
- Health checks on every service
- Logging: `json-file` driver with `max-size` and `max-file` limits
- Memory limits on all services
- `restart: unless-stopped` on all services

## Astro / TypeScript

- Env-driven config via `process.env` and `import.meta.env`
- No hardcoded URLs in `.ts` files
- Interfaces for all API responses

## Directus API

- Always set `date_published` on new items
- Use static token from `.env` (`${DIRECTUS_TOKEN}`)
- Filter by `status: published` on reads
- Verify after create with a GET request
