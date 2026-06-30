# React-Admin Demo

## What This Provides

The official [react-admin](https://github.com/marmelab/react-admin) v5 demo — a full admin panel UI with data grid, CRUD, filters, auth, and i18n. Runs in Docker. Optionally connects to Directus as a backend.

## Files

| File | Purpose |
|------|---------|
| `SKILL.md` | Skill for OpenCode (`react-admin`, `ra`, `admin-panel`) |
| `Dockerfile` | Builds the demo from source (multi-stage) |
| `docker-compose.yml` | Container config (env-driven port) |
| `scripts/run.sh` | Quick start script |
| `scripts/custom-directus-provider.js` | Maps Directus API to react-admin format |

## Installation

```bash
# Add to .env
echo "PORT_REACT_ADMIN=5200" >> /opt/pauly/.env

# Build and start
cd /opt/pauly/optional/07-react-admin
docker compose build --no-cache
docker compose up -d

# Verify
curl -s -o /dev/null -w "%{http_code}" http://localhost:5200/
```

## Install Skill

```bash
cp -r /opt/pauly/optional/07-react-admin ~/.config/opencode/skills/react-admin
```

## Directus Integration

The included `custom-directus-provider.js` maps Directus collections to react-admin resources:

| React-Admin Operation | Directus API |
|-----------------------|-------------|
| `getList` | `GET /items/{resource}?page=1&limit=25&sort=-id` |
| `getOne` | `GET /items/{resource}/{id}` |
| `create` | `POST /items/{resource}` |
| `update` | `PATCH /items/{resource}/{id}` |
| `delete` | `DELETE /items/{resource}/{id}` |

The `pages` collection created by `init.sh` becomes a `pages` resource automatically.

## Port

Default: `5200` (configurable via `${PORT_REACT_ADMIN}` in `.env`)
