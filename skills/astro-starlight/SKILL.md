# Skill: astro-starlight

# Astro Starlight — Directus-Powered Documentation Site

<!-- last_verified: 2026-06-30 -->

## Overview
Astro Starlight documentation site with **Directus CMS** as backend content source. All ports and URLs are **env-driven** — nothing is hardcoded.

## Trigger Commands
- `astro-starlight` - Astro management menu
- `starlight` - Alias
- `docs` - Quick status
- `publish-doc` - Publish markdown to Directus

---

## CRITICAL: Ports Are Env-Driven

**All ports are defined in `/opt/pauly/.env`.** Always `source` it first:

```bash
source /opt/pauly/.env
```

| Variable | Default | Purpose |
|----------|---------|---------|
| `PORT_ASTRO` | `3003` | Astro docs site (external) |
| `PORT_DIRECTUS` | `8056` | Directus API (external) |
| `ASTRO_INTERNAL_PORT` | `4321` | Astro inside Docker |
| `DIRECTUS_INTERNAL_PORT` | `8055` | Directus inside Docker |
| `DIRECTUS_TOKEN` | `docs-api-token-change-me` | Static API token |
| `DOCKER_NETWORK` | `directus_default` | Shared Docker network |

---

## Infrastructure

| Item | Value |
|------|-------|
| **Astro URL** | `http://${SERVER_IP}:${PORT_ASTRO}` |
| **Directus URL** | `http://${SERVER_IP}:${PORT_DIRECTUS}` |
| **Project root** | `/opt/pauly/astro-docs/` |
| **Container** | `astro-docs` |

---

## Architecture

```
┌─────────────────┐      REST API       ┌──────────────────┐
│   Astro         │◄───────────────────►│  Directus CMS    │
│   (Starlight)   │  /items/pages       │  (${PORT_DIRECTUS})│
│   ${PORT_ASTRO} │                     │  PostgreSQL      │
│                 │                     │  Redis cache     │
└─────────────────┘                     └──────────────────┘
        │                                        │
        │ Docker network: ${DOCKER_NETWORK}      │
        └────────────────────────────────────────┘
```

---

## Publishing

### Quick Publish (Direct API)

```bash
source /opt/pauly/.env

curl -s -X POST http://localhost:${PORT_DIRECTUS}/items/pages \
  -H "Authorization: Bearer ${DIRECTUS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Page Title",
    "slug": "page-title",
    "status": "published",
    "order": 1,
    "date_published": "2026-06-30T12:00:00Z",
    "excerpt": "Short description",
    "content": "# Page Title\n\nContent here..."
  }'

# Verify
curl -s -o /dev/null -w "%{http_code}" http://localhost:${PORT_ASTRO}/docs/page-title
```

### Publish via Script

```bash
source /opt/pauly/.env
python3 ~/.config/opencode/skills/astro-starlight/scripts/publish_page.py /path/to/page.md
```

### Slug Rules

1. Never start slugs with a digit — Astro routing rejects them
2. Keep under 50 characters
3. Use kebab-case
4. Always verify after publish

### date_published (CRITICAL)

Pages without `date_published` are filtered out. Always include it.

---

## Container Management

```bash
# ALWAYS source .env first
source /opt/pauly/.env

# Start
cd /opt/pauly/astro-docs && docker compose up -d

# Rebuild after code changes (REQUIRED for new files)
cd /opt/pauly/astro-docs && docker compose build --no-cache && docker compose up -d

# Check health
curl -s -o /dev/null -w "%{http_code}" http://localhost:${PORT_ASTRO}/

# Check Directus connectivity from container
docker exec astro-docs wget -qO- http://directus:${DIRECTUS_INTERNAL_PORT}/server/health

# View logs
docker logs astro-docs --tail 50 -f
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| **500 on all pages** | Check Directus: `source /opt/pauly/.env && curl ${PORT_DIRECTUS}/server/health`. Rebuild: `docker compose build --no-cache && up -d` |
| **Port conflict** | Run `bash /opt/pauly/scripts/detect-ports.sh` |
| **Directus connection refused** | Check network: `docker network inspect ${DOCKER_NETWORK}` |
| **Page 404** | Check `date_published` is set and `status: published` |
| **Changes not reflecting** | Rebuild: `docker compose build --no-cache && up -d` |

---

## Menu Configuration

**Trigger**: `astro-starlight` or `starlight`

```json
{
  "questions": [
    {
      "question": "Astro Starlight - What would you like to do?",
      "header": "Starlight",
      "options": [
        { "label": "Status", "description": "Check Astro + Directus health" },
        { "label": "List pages", "description": "Show all Directus pages" },
        { "label": "Publish page", "description": "Publish markdown to Directus" },
        { "label": "Rebuild", "description": "Rebuild Astro container" },
        { "label": "Logs", "description": "View Astro container logs" },
        { "label": "Detect ports", "description": "Check/update ports in .env" }
      ],
      "multiple": false
    }
  ]
}
```

---

Base directory: /root/.config/opencode/skills/astro-starlight
