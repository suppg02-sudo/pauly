---
name: pa
version: 1.1.0
description: Personal Assistant dashboard — interactive HTML architecture overview with env-driven links
trigger: pa, personal-assistant, dashboard, personal-dashboard
maturity: L2
created: 2026-06-30
dependencies: []
tags: [dashboard, html, architecture, navigation]
---

# PA (Personal Assistant) Dashboard

## Overview

Interactive HTML dashboard representing the server's architecture: **Publish / Learn / Manage** pillars with **AI / Application / Infrastructure** layers. Served as a static HTML file on a configurable port via systemd.

All links are **env-driven** — edit `.env` to change where everything points.

## Trigger Commands

- `pa` — Load this skill
- `personal-assistant` — Alias
- `dashboard` — Alias
- `personal-dashboard` — Alias

---

## Architecture

### 3 Pillars (click to toggle)

| Pillar | Colour | Contents |
|--------|--------|----------|
| **Publish** | Blue `#3b82f6` | Blogs, Websites, Media (Diagrams, Gallery) |
| **Learn** | Teal `#14b8a6` | Research, Study, Read |
| **Manage** | Purple `#8b5cf6` | Projects, Schedule, Content |

### 3 Layers (click to toggle)

| Layer | Colour | Contents |
|-------|--------|----------|
| **AI** | Blue | Agents, Skills, Memory, MCP, LLM |
| **Application** | Purple | Astro, OpenCode, Tailscale |
| **Infrastructure** | Lime | Directus, Docker, Postgres, Nginx, Ubuntu |

### Interactivity

- Click pillars → toggle badge display
- Click layers → toggle icon display
- Expand All / Collapse All button
- Badge hover → scale animation
- Theme toggle (System / Light / Dark / Artifacts mode)
- Artifacts mode → every element gets `#aN [type]` tags for referencing in chat

---

## Configuration

All values read from `/opt/pauly/.env`:

| Variable | Default | Purpose |
|----------|---------|---------|
| `PORT_PA` | `8901` | Port the dashboard is served on |
| `SERVER_IP` | `localhost` | Hostname for all dashboard links |
| `PORT_DIRECTUS` | `8056` | Directus link target |
| `PORT_ASTRO` | `3003` | Astro/blog link target |

---

## Deployment

### Option A: Systemd (Recommended)

```bash
source /opt/pauly/.env

# Create service
cat > /etc/systemd/system/pa-dashboard.service << EOF
[Unit]
Description=PA Dashboard Static Server
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/pauly
ExecStart=/usr/bin/python3 -m http.server ${PORT_PA:-8901} --directory /opt/pauly
Restart=unless-stopped

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now pa-dashboard
```

### Option B: Docker

```bash
# Add to a docker-compose.yml
services:
  pa-dashboard:
    image: nginx:alpine
    ports:
      - "${PORT_PA:-8901}:80"
    volumes:
      - ./personal-assistant.html:/usr/share/nginx/html/index.html
    restart: unless-stopped
    networks:
      - ${DOCKER_NETWORK:-directus_default}
```

---

## Customizing the Dashboard

### Change Links

All links in the HTML use `data-href` attributes that get resolved from `.env` at runtime. Edit the `<script>` section:

```javascript
// Links resolved from env at page load
const LINKS = {
  blog: `http://${SERVER_IP}:${PORT_ASTRO}/posts/`,
  directus: `http://${SERVER_IP}:${PORT_DIRECTUS}/`,
  docs: `http://${SERVER_IP}:${PORT_ASTRO}/docs/`,
  // Add your own...
};
```

### Add a Badge

Inside the relevant pillar's `<div class="tools">`:

```html
<a href="#" data-link="blog" class="tool">Blog</a>
```

### Add an Icon

Inside the relevant layer's icon section:

```html
<a href="#" data-link="directus" class="app-icon">
  <img src="https://cdn.simpleicons.org/directus/263238" alt="Directus" />
</a>
```

### Change Colours

Edit the CSS `.pillar.*` and `.layer.*` blocks for border, box-shadow, and badge colours.

---

## Quick Commands

```bash
# Always source .env first
source /opt/pauly/.env

# Check dashboard is serving
curl -s -o /dev/null -w "%{http_code}" http://localhost:${PORT_PA:-8901}/

# Restart systemd service
systemctl restart pa-dashboard

# View logs
journalctl -u pa-dashboard -f --tail 20
```

---

## Menu Configuration

**Trigger**: `pa`

```json
{
  "questions": [
    {
      "question": "PA Dashboard — What would you like to do?",
      "header": "PA Dashboard",
      "options": [
        { "label": "Status", "description": "Check if dashboard is serving" },
        { "label": "Edit links", "description": "Update dashboard link targets" },
        { "label": "Add badge", "description": "Add a new badge to a pillar" },
        { "label": "Add icon", "description": "Add a new icon to a layer" },
        { "label": "Restart", "description": "Restart the dashboard service" },
        { "label": "View", "description": "Open dashboard URL" }
      ],
      "multiple": false
    }
  ]
}
```

---

## Related Skills

| Skill | Relationship |
|-------|-------------|
| `directus-server` | Directus management (dashboard links here) |
| `astro-starlight` | Astro docs (dashboard links here) |

---

Base directory: ~/.config/opencode/skills/pa
