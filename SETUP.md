# Directus + Astro Starlight — Complete Setup Guide

> Based on the production setup, adapted for a **new Ubuntu server** with **Starlight** documentation theme. **All ports and URLs are env-driven — nothing is hardcoded.**

---

## How Port Configuration Works

Every port, URL, and credential is defined in **`.env`** at the repo root. No compose file, config, or script contains hardcoded port numbers.

```
.env (root)
  ├── PORT_DIRECTUS=8056       → directus/docker-compose.yml ports
  ├── PORT_ASTRO=3003          → astro-docs/docker-compose.yml ports
  ├── PORT_POSTGRES=5433       → directus/docker-compose.yml ports
  ├── PORT_REDIS=6380          → directus/docker-compose.yml ports
  ├── DIRECTUS_INTERNAL_PORT   → container-internal (don't change)
  ├── ASTRO_INTERNAL_PORT      → container-internal (don't change)
  └── SERVER_IP                → PUBLIC_URL, CORS, astro.config.mjs site
```

Docker Compose automatically reads `.env` from the directory it runs in. The root `.env` covers both subdirectories when you `cd` into them and symlink or copy it.

---

## Phase 1: Server Prep

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker + Docker Compose
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
newgrp docker

# Install Node.js 22 (for local Astro dev/testing)
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs git

# Create project directories
sudo mkdir -p /opt/pauly
```

---

## Phase 2: Clone & Configure

```bash
cd /opt/pauly
git clone https://github.com/suppg02-sudo/pauly.git .

# Create .env from template
cp .env.example .env

# Auto-detect free ports and server IP
bash scripts/detect-ports.sh

# Generate secrets
SECRET=$(openssl rand -hex 24)
sed -i "s|^DIRECTUS_SECRET=.*|DIRECTUS_SECRET=${SECRET}|" .env

# Generate a secure API token
TOKEN=$(openssl rand -hex 16)
sed -i "s|^DIRECTUS_TOKEN=.*|DIRECTUS_TOKEN=${TOKEN}|" .env

# Review the final config
cat .env
```

---

## Phase 3: Start Directus

```bash
cd /opt/pauly/directus

# Copy root .env if not auto-loaded
cp /opt/pauly/.env ./.env

# Start all Directus services
docker compose up -d

# Wait for bootstrap (~10s)
sleep 10

# Health check (reads PORT_DIRECTUS from .env)
source /opt/pauly/.env
curl -s http://localhost:${PORT_DIRECTUS}/server/health
# Expected: {"status":"ok"}
```

### Generate API Token

```bash
# Login as admin
ADMIN_TOKEN=$(curl -s -X POST http://localhost:${PORT_DIRECTUS}/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"${ADMIN_EMAIL}\",\"password\":\"${ADMIN_PASSWORD}\"}" \
  | jq -r '.data.access_token')

# Set static token on admin user (uses the token from .env)
curl -s -X PATCH http://localhost:${PORT_DIRECTUS}/users/me \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"token\":\"${DIRECTUS_TOKEN}\"}"
```

### Create `pages` Collection

```bash
curl -s -X POST http://localhost:${PORT_DIRECTUS}/collections \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "collection": "pages",
    "meta": { "icon": "article", "note": "Starlight documentation pages" },
    "schema": { "name": "pages" },
    "fields": [
      { "field": "id", "type": "integer", "schema": { "is_primary_key": true, "has_auto_increment": true }, "meta": { "hidden": true } },
      { "field": "title", "type": "string", "schema": { "is_nullable": false }, "meta": { "interface": "input", "width": "full" } },
      { "field": "slug", "type": "string", "schema": { "is_unique": true }, "meta": { "interface": "input", "width": "half" } },
      { "field": "status", "type": "string", "schema": { "default_value": "published" },
        "meta": { "interface": "select-dropdown", "display": "labels", "options": { "choices": [
          {"text":"Draft","value":"draft"}, {"text":"Published","value":"published"}
        ]}}},
      { "field": "content", "type": "text", "meta": { "interface": "input-code", "language": "markdown", "width": "full" } },
      { "field": "excerpt", "type": "string", "meta": { "interface": "input", "width": "full" } },
      { "field": "order", "type": "integer", "schema": { "default_value": 0 }, "meta": { "interface": "input", "width": "half" } },
      { "field": "category", "type": "string", "meta": { "interface": "input", "width": "half" } },
      { "field": "tags", "type": "json", "meta": { "interface": "tags", "width": "full" } },
      { "field": "date_published", "type": "timestamp", "meta": { "interface": "datetime", "width": "half" } },
      { "field": "date_updated", "type": "timestamp", "meta": { "interface": "datetime", "width": "half", "special": ["current-update"] } },
      { "field": "featured_image", "type": "uuid", "meta": { "interface": "file-image", "width": "half" } }
    ]
  }'

# Give public role read access
curl -s -X POST http://localhost:${PORT_DIRECTUS}/permissions \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "role": null, "collection": "pages", "action": "read", "fields": ["*"] }'

# Create test page
curl -s -X POST http://localhost:${PORT_DIRECTUS}/items/pages \
  -H "Authorization: Bearer ${DIRECTUS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"title":"Getting Started","slug":"getting-started","status":"published","order":1,"date_published":"2026-06-30T12:00:00Z","excerpt":"Welcome","content":"# Getting Started\n\nWelcome!"}'
```

---

## Phase 4: Start Astro Starlight

```bash
cd /opt/pauly/astro-docs

# Copy root .env
cp /opt/pauly/.env ./.env

# Ensure Docker network exists
source /opt/pauly/.env
docker network create ${DOCKER_NETWORK} 2>/dev/null || true

# Build and start
docker compose build --no-cache
docker compose up -d

# Wait for boot
sleep 5

# Verify
curl -s -o /dev/null -w "%{http_code}" http://localhost:${PORT_ASTRO}/
# Expected: 200
```

---

## Phase 5: Verify Integration

```bash
source /opt/pauly/.env

# 1. Directus healthy
curl -s http://localhost:${PORT_DIRECTUS}/server/health

# 2. Directus serves pages
curl -s http://localhost:${PORT_DIRECTUS}/items/pages \
  -H "Authorization: Bearer ${DIRECTUS_TOKEN}" | jq '.data | length'

# 3. Astro running
curl -s -o /dev/null -w "%{http_code}" http://localhost:${PORT_ASTRO}/

# 4. Astro can reach Directus (internal Docker network)
docker exec astro-docs wget -qO- http://directus:${DIRECTUS_INTERNAL_PORT}/server/health

# 5. Dynamic page from Directus renders
curl -s -o /dev/null -w "%{http_code}" http://localhost:${PORT_ASTRO}/docs/getting-started
```

---

## Phase 6: Firewall

```bash
source /opt/pauly/.env
sudo ufw allow ${PORT_DIRECTUS}/tcp
sudo ufw allow ${PORT_ASTRO}/tcp
sudo ufw allow 22/tcp
sudo ufw enable
```

---

## Phase 7: Optional Setup (pick what you need)

Each item is independent — install only what you want.

### 7a. One-Command Bootstrap (does Phases 1-6 automatically)

```bash
bash /opt/pauly/optional/05-init-script/init.sh
```

### 7b. Agent Config (AGENTS.md + context files)

```bash
cp /opt/pauly/optional/01-agents-md/AGENTS.template.md ~/.config/opencode/AGENTS.md
cp -r /opt/pauly/optional/02-context-files/standards ~/.config/opencode/context/
cp -r /opt/pauly/optional/02-context-files/workflows ~/.config/opencode/context/
```

### 7c. MCP Servers (context7, github, browser, brave-search)

```bash
# See optional/04-mcp-config/README.md for full setup
# Quick merge into opencode.json:
python3 -c "
import json
with open('/root/.config/opencode/opencode.json') as f: cfg=json.load(f)
with open('/opt/pauly/optional/04-mcp-config/mcp-template.json') as f: mcp=json.load(f)
cfg.setdefault('mcp',{}).update(mcp['mcp'])
json.dump(cfg, open('/root/.config/opencode/opencode.json','w'), indent=2)
"
```

### 7d. PA Dashboard

```bash
source /opt/pauly/.env
bash /opt/pauly/optional/06-pa-skill/scripts/deploy.sh

cat > /etc/systemd/system/pa-dashboard.service << EOF
[Unit]
Description=PA Dashboard
After=network.target
[Service]
Type=simple
ExecStart=/usr/bin/python3 -m http.server ${PORT_PA} --directory /opt/pauly
Restart=unless-stopped
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload && systemctl enable --now pa-dashboard
```

### 7e. Skills Installation

```bash
cp -r /opt/pauly/skills/directus-server ~/.config/opencode/skills/
cp -r /opt/pauly/skills/astro-starlight ~/.config/opencode/skills/
cp -r /opt/pauly/optional/06-pa-skill ~/.config/opencode/skills/pa
cp -r /opt/pauly/optional/07-react-admin ~/.config/opencode/skills/react-admin
```

### 7f. React-Admin Demo Panel

```bash
cd /opt/pauly/optional/07-react-admin
docker compose build --no-cache && docker compose up -d
# URL: http://${SERVER_IP}:5200/
```

### 7g. Setup Refine (repo self-analysis)

```bash
# Install skill
cp -r /opt/pauly/optional/08-setuprefine ~/.config/opencode/skills/setuprefine

# Quick non-interactive check
bash /opt/pauly/optional/08-setuprefine/scripts/analyse.sh

# Full interactive analysis (trigger in OpenCode)
# setuprefine
```

---

## Quick Reference

```bash
# All commands assume: source /opt/pauly/.env

# Start everything
cd /opt/pauly/directus && docker compose up -d
cd /opt/pauly/astro-docs && docker compose up -d

# Stop everything
cd /opt/pauly/astro-docs && docker compose down
cd /opt/pauly/directus && docker compose down

# Directus admin URL
echo "http://${SERVER_IP}:${PORT_DIRECTUS}"

# Astro URL
echo "http://${SERVER_IP}:${PORT_ASTRO}"

# Create a page via API
curl -s -X POST http://localhost:${PORT_DIRECTUS}/items/pages \
  -H "Authorization: Bearer ${DIRECTUS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"title":"New Page","slug":"new-page","status":"published","order":1,"date_published":"2026-06-30T12:00:00Z","content":"# New Page"}'

# Rebuild Astro after code changes
cd /opt/pauly/astro-docs && docker compose build --no-cache && docker compose up -d
```

---

## Directory Structure

```
/opt/pauly/
├── .env                           ← SINGLE SOURCE OF TRUTH
├── scripts/detect-ports.sh        ← Auto-detect free ports
├── directus/
│   ├── docker-compose.yml         ← ${PORT_DIRECTUS}, ${PORT_POSTGRES}, etc.
│   └── redis-entrypoint.sh
├── astro-docs/
│   ├── Dockerfile                 ← ENV PORT (runtime override)
│   ├── docker-compose.yml         ← ${PORT_ASTRO}, ${DOCKER_NETWORK}
│   ├── astro.config.mjs           ← process.env.PORT_ASTRO, SERVER_IP
│   └── src/lib/directus.ts        ← import.meta.env.DIRECTUS_URL (env-driven)
├── skills/                        ← directus-server, astro-starlight
└── optional/                      ← Pick what you need
    ├── 01-agents-md/              ← AGENTS.md template
    ├── 02-context-files/          ← Standards + workflows
    ├── 03-skills/                 ← Installation guide
    ├── 04-mcp-config/             ← MCP servers
    ├── 05-init-script/            ← init.sh bootstrap
    └── 06-pa-skill/              ← PA dashboard
```
