# AGENTS.md — Pauly (Directus + Astro Starlight Docs Server)

> **Point your IDE at this repo.** This file tells the agent everything it needs to set up and manage a Directus CMS + Astro Starlight documentation site on a fresh Ubuntu server.

## What This Repo Does

Sets up two integrated services on a new Ubuntu server:

| Service | Stack | Port (configurable) | Container |
|---------|-------|---------------------|-----------|
| **Directus** (CMS backend) | Directus 11 + PostgreSQL (pgvector) + Redis | `${PORT_DIRECTUS}` (default 8056) | `directus` |
| **Astro** (docs frontend) | Astro + Starlight + @directus/sdk | `${PORT_ASTRO}` (default 3003) | `astro-docs` |

Astro fetches documentation pages from Directus via REST API at request time (SSR mode).

## CRITICAL: No Hardcoded Ports

**All ports, URLs, and credentials are defined in `.env` at the repo root.** Nothing is hardcoded in any compose file, config, or script.

Before starting:
1. Copy `.env.example` to `.env`
2. Run `bash scripts/detect-ports.sh` — auto-detects free ports and fills `.env`
3. Generate secrets: `openssl rand -hex 24` for `DIRECTUS_SECRET`
4. All `${VAR}` references in compose/config files are resolved from `.env`

## Quick Start (For Agents)

**Fastest path** — use the bootstrap script:

```
1. git clone https://github.com/suppg02-sudo/pauly.git /opt/pauly
2. cd /opt/pauly && cp .env.example .env
3. bash optional/05-init-script/init.sh    # does everything
```

**Manual path** — step by step:

```
1. cp .env.example .env
2. bash scripts/detect-ports.sh
3. Edit .env — review SERVER_IP, secrets
4. cd directus && docker compose up -d
5. Wait 10s, verify: curl http://localhost:${PORT_DIRECTUS}/server/health
6. Generate Directus static token, set it in .env as DIRECTUS_TOKEN
7. cd astro-docs && docker compose up -d
8. Verify: curl http://localhost:${PORT_ASTRO}/
9. (optional) bash optional/05-init-script/init.sh --skills
```

## Port Variables (all in `.env`)

| Variable | Default | Purpose |
|----------|---------|---------|
| `PORT_DIRECTUS` | `8056` | Directus admin + API (external) |
| `PORT_ASTRO` | `3003` | Astro docs site (external) |
| `PORT_POSTGRES` | `5433` | PostgreSQL (external) |
| `PORT_REDIS` | `6380` | Redis (external) |
| `DIRECTUS_INTERNAL_PORT` | `8055` | Directus inside Docker network |
| `POSTGRES_INTERNAL_PORT` | `5432` | PostgreSQL inside Docker network |
| `REDIS_INTERNAL_PORT` | `6379` | Redis inside Docker network |
| `ASTRO_INTERNAL_PORT` | `4321` | Astro inside Docker network |
| `SERVER_IP` | `localhost` | Server IP or hostname |
| `DOCKER_NETWORK` | `directus_default` | Shared Docker network |

## Repo Structure

```
pauly/
├── AGENTS.md                        ← YOU ARE HERE
├── SETUP.md                         ← Complete setup guide
├── README.md                        ← Human-readable overview
├── .env.example                     ← ALL config — single source of truth (fresh passwords)
│
├── scripts/
│   └── detect-ports.sh              ← Auto-detect free ports → .env
│
├── directus/                        ← Phase 3: Directus deployment
│   ├── docker-compose.yml
│   ├── .env.example
│   └── redis-entrypoint.sh
│
├── astro-docs/                      ← Phase 4: Astro Starlight
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── package.json
│   ├── astro.config.mjs
│   ├── tsconfig.json
│   ├── .env.example
│   └── src/
│
├── skills/                          ← Core skills (always included)
│   ├── directus-server/SKILL.md
│   └── astro-starlight/SKILL.md
│
└── optional/                        ← Optional phases (pick what you need)
    ├── 01-agents-md/                ← AGENTS.md template (behavioral rules + triggers)
    ├── 02-context-files/            ← Coding standards + workflows
    ├── 03-skills/                   ← Skills installation guide
    ├── 04-mcp-config/               ← MCP server config (context7, github, browser, search)
    ├── 05-init-script/              ← Full bootstrap: init.sh (zero to running)
    ├── 06-pa-skill/                 ← PA dashboard (HTML + systemd service)
    └── 07-react-admin/              ← React-Admin demo panel (optional backend for Directus)
    └── 08-setuprefine/              ← Repo self-analysis + improvement proposals (trigger: setuprefine)
```

## Optional Phases

| Phase | What | When to Use |
|-------|------|-------------|
| `optional/01-agents-md` | AGENTS.md with behavioral rules, safety rules, triggers | Always — gives the agent instructions |
| `optional/02-context-files` | Coding standards + workflow templates | When you want consistent conventions |
| `optional/03-skills` | Installation guide for repo skills | When installing skills on the server |
| `optional/04-mcp-config` | MCP servers (context7, github, browser, brave-search) | When using OpenCode IDE features |
| `optional/05-init-script` | One-command bootstrap (`init.sh`) | Fresh server — does everything |
| `optional/06-pa-skill` | PA dashboard HTML + systemd service | When you want a visual architecture overview |
| `optional/07-react-admin` | React-Admin demo panel | When you need a full admin UI (optional Directus backend) |
| `optional/08-setuprefine` | Repo self-analysis + improvement proposals | Run after changes to catch issues — trigger: `setuprefine` |

## Credentials (freshly generated in .env.example)

| Item | Value |
|------|-------|
| Admin Email | `${ADMIN_EMAIL}` |
| Admin Password | `${ADMIN_PASSWORD}` |
| API Token | `${DIRECTUS_TOKEN}` |
| DB Password | `${DB_PASSWORD}` |
| Directus Secret | `${DIRECTUS_SECRET}` |
| Redis Password | `${REDIS_PASSWORD}` |
| NPM Password | `${NPM_PASSWORD}` |
| Grafana Password | `${GRAFANA_PASSWORD}` |
| Webhook Secret | `${WEBHOOK_SECRET}` |

## Agent Rules

1. **API-first**: Never use a browser for tasks the API handles (see skills)
2. **Always set `date_published`**: Pages without it are filtered out
3. **Rebuild after new files**: `docker compose build --no-cache && docker compose up -d`
4. **Shared Docker network**: Both services must be on `${DOCKER_NETWORK}`
5. **Read `.env` for ports**: Never assume port numbers — always check `.env`
6. **Run detect-ports.sh** before first deploy to avoid conflicts

## Dependencies

- Docker 24+ with Docker Compose v2
- Ubuntu 22.04 or 24.04 LTS
