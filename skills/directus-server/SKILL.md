# Skill: directus-server

# Directus CMS — Ubuntu Server Edition

## Overview
Directus CMS operations for the new Ubuntu server. Docker-based Directus 11.x with PostgreSQL (pgvector) + Redis. API-first approach — never use the browser for tasks the API handles.

## Trigger Commands
- `directus-server` - Directus management menu
- `ds` - Quick status check

---

## CRITICAL: Ports Are Env-Driven

**All ports are defined in `/opt/pauly/.env`.** Never hardcode port numbers. Always read from env:

```bash
# Load config
source /opt/pauly/.env

# Use variables in all commands
curl http://localhost:${PORT_DIRECTUS}/server/health
```

| Variable | Default | Purpose |
|----------|---------|---------|
| `PORT_DIRECTUS` | `8056` | Directus admin + API |
| `PORT_POSTGRES` | `5433` | PostgreSQL |
| `PORT_REDIS` | `6380` | Redis |
| `DIRECTUS_TOKEN` | `docs-api-token-change-me` | Static API token |
| `ADMIN_EMAIL` | `admin@example.com` | Admin login |
| `ADMIN_PASSWORD` | `admin123` | Admin password |

---

## Infrastructure

| Service | Container | External Port (from .env) | Internal |
|---------|-----------|---------------------------|----------|
| **Directus** | `directus` | `${PORT_DIRECTUS}` | `${DIRECTUS_INTERNAL_PORT}` |
| **PostgreSQL** | `directus-postgres` | `${PORT_POSTGRES}` | `${POSTGRES_INTERNAL_PORT}` |
| **Redis** | `directus-redis` | `${PORT_REDIS}` | `${REDIS_INTERNAL_PORT}` |

### Paths

| Item | Path |
|------|------|
| **Project root** | `/opt/pauly/` |
| **Docker compose** | `/opt/pauly/directus/docker-compose.yml` |
| **Env file** | `/opt/pauly/.env` |

---

## API-Only Rule (NO BROWSER)

| Task | Wrong | Right |
|------|-------|-------|
| Browse content | Browser → admin | `source /opt/pauly/.env && curl -s http://localhost:${PORT_DIRECTUS}/items/pages -H "Authorization: Bearer ${DIRECTUS_TOKEN}"` |
| Create/update | Browser form | `curl -X POST/PATCH http://localhost:${PORT_DIRECTUS}/items/pages` |
| Check health | Browser | `curl -s http://localhost:${PORT_DIRECTUS}/server/health` |
| Delete | Browser click | `curl -X DELETE http://localhost:${PORT_DIRECTUS}/items/pages/{ID}` |

---

## Quick Commands

```bash
# ALWAYS source .env first
source /opt/pauly/.env

# Health check
curl -s http://localhost:${PORT_DIRECTUS}/server/health

# Container status
docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}" | grep -E 'directus|postgres|redis'

# View logs
docker logs directus --tail 50

# Restart Directus
docker restart directus

# Access database
docker exec -it directus-postgres psql -U directus -d directus

# List pages
curl -s "http://localhost:${PORT_DIRECTUS}/items/pages?limit=10&sort=-date_published" \
  -H "Authorization: Bearer ${DIRECTUS_TOKEN}" | jq '.data[] | {id, title, slug, status}'
```

---

## Backup & Restore

```bash
source /opt/pauly/.env

# Backup database
docker exec directus-postgres pg_dump -U directus directus > /opt/pauly/backups/directus-$(date +%Y%m%d).sql

# Restore database
cat /opt/pauly/backups/directus-20260630.sql | docker exec -i directus-postgres psql -U directus -d directus
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| **502/Connection refused** | `source /opt/pauly/.env && docker compose -f /opt/pauly/directus/docker-compose.yml restart` |
| **Port conflict** | Run `bash /opt/pauly/scripts/detect-ports.sh` to find free ports |
| **Token not working** | Regenerate: `curl -X PATCH http://localhost:${PORT_DIRECTUS}/users/me -H "Authorization: Bearer $(curl ... login ...)" -d '{"token":"new-token"}'` |
| **Can't reach Astro** | Check shared network: `docker network inspect ${DOCKER_NETWORK}` |

---

## Menu Configuration

**Trigger**: `directus-server`

```json
{
  "questions": [
    {
      "question": "Directus Server - What would you like to do?",
      "header": "Directus",
      "options": [
        { "label": "Status", "description": "Check health and container status" },
        { "label": "List pages", "description": "Show all documentation pages" },
        { "label": "Create page", "description": "Create a new page via API" },
        { "label": "Backup", "description": "Backup database" },
        { "label": "Restart", "description": "Restart all Directus containers" },
        { "label": "Detect ports", "description": "Check/update ports in .env" }
      ],
      "multiple": false
    }
  ]
}
```

---

Base directory: /root/.config/opencode/skills/directus-server
