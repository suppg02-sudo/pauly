---
name: react-admin
version: 1.0.0
description: React-Admin demo — admin panel UI running on configurable port, optional Directus backend
trigger: react-admin, ra, admin-panel
maturity: L2
created: 2026-06-30
dependencies: [directus-server]
tags: [react, admin, ui, dashboard]
---

# React-Admin Demo

## Overview

The official [react-admin](https://github.com/marmelab/react-admin) demo app — a full-featured admin panel with CRUD, data grid, filters, authentication, and i18n. Runs in Docker on a configurable port.

Optionally connects to Directus as a data provider via `ra-data-simple-rest`.

## Trigger Commands

- `react-admin` — Load this skill
- `ra` — Alias
- `admin-panel` — Alias

---

## Configuration

All values read from `/opt/pauly/.env`:

| Variable | Default | Purpose |
|----------|---------|---------|
| `PORT_REACT_ADMIN` | `5200` | External port for the admin panel |
| `DIRECTUS_TOKEN` | from `.env` | Used if connecting to Directus as backend |

---

## Quick Commands

```bash
source /opt/pauly/.env

# Check status
curl -s -o /dev/null -w "%{http_code}" http://localhost:${PORT_REACT_ADMIN:-5200}/

# View logs
docker logs react-admin --tail 50

# Restart
docker restart react-admin

# Rebuild after changes
cd /opt/pauly/optional/07-react-admin && docker compose build --no-cache && docker compose up -d
```

---

## Connecting to Directus

React-Admin can use Directus as a REST backend via `ra-data-simple-rest`:

```javascript
import simpleRestProvider from 'ra-data-simple-rest';

const directusUrl = import.meta.env.VITE_DIRECTUS_URL || 'http://localhost:8056';
const token = import.meta.env.VITE_DIRECTUS_TOKEN || '';

const dataProvider = simpleRestProvider(`${directusUrl}/items`, {
  headers: { Authorization: `Bearer ${token}` }
});
```

Collections in Directus (like `pages`) become resources in react-admin:
- `GET /items/pages` → List
- `POST /items/pages` → Create
- `PATCH /items/pages/:id` → Update
- `DELETE /items/pages/:id` → Delete

> **Note**: Directus field names differ from react-admin's expected `id` field. You may need a custom data provider for full compatibility. See `scripts/custom-directus-provider.js` for a starting point.

---

## Menu Configuration

**Trigger**: `react-admin`

```json
{
  "questions": [
    {
      "question": "React-Admin — What would you like to do?",
      "header": "React-Admin",
      "options": [
        { "label": "Status", "description": "Check if admin panel is running" },
        { "label": "Logs", "description": "View container logs" },
        { "label": "Restart", "description": "Restart the container" },
        { "label": "Rebuild", "description": "Rebuild after code changes" },
        { "label": "Connect Directus", "description": "Configure Directus as data provider" }
      ],
      "multiple": false
    }
  ]
}
```

---

Base directory: ~/.config/opencode/skills/react-admin
