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

When asked to "set up pauly" or "deploy the docs server", follow this sequence:

```
1. cp .env.example .env
2. bash scripts/detect-ports.sh        # auto-fill free ports
3. Edit .env — set SERVER_IP, DIRECTUS_SECRET, DIRECTUS_TOKEN
4. cd directus && docker compose up -d
5. Wait 10s, verify: curl http://localhost:${PORT_DIRECTUS}/server/health
6. Generate Directus static token, set it in .env as DIRECTUS_TOKEN
7. cd astro-docs && docker compose up -d
8. Verify: curl http://localhost:${PORT_ASTRO}/
```

Read `SETUP.md` for the full 7-phase guide.

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
├── SETUP.md                         ← Complete setup guide (7 phases)
├── README.md                        ← Human-readable overview
├── .env.example                     ← ALL config — single source of truth
│
├── scripts/
│   └── detect-ports.sh              ← Auto-detect free ports → .env
│
├── directus/
│   ├── docker-compose.yml           ← All ports via ${VAR}
│   ├── .env.example
│   └── redis-entrypoint.sh
│
├── astro-docs/
│   ├── Dockerfile
│   ├── docker-compose.yml           ← All ports via ${VAR}
│   ├── package.json
│   ├── astro.config.mjs             ← Reads ports from process.env
│   ├── tsconfig.json
│   ├── .env.example
│   ├── src/
│   │   ├── lib/directus.ts          ← Fully env-driven, no hardcoded URLs
│   │   ├── pages/docs/[slug].astro  ← Dynamic page renderer
│   │   ├── styles/custom.css
│   │   ├── content/docs/            ← Starlight static markdown
│   │   └── components/
│   └── public/
│
└── skills/                          ← OpenCode skills for management
    ├── directus-server/SKILL.md
    └── astro-starlight/SKILL.md
```

## Default Credentials (CHANGE IMMEDIATELY)

| Item | Default |
|------|---------|
| Admin Email | `${ADMIN_EMAIL}` → `admin@example.com` |
| Admin Password | `${ADMIN_PASSWORD}` → `admin123` |
| API Token | `${DIRECTUS_TOKEN}` → `docs-api-token-change-me` |
| DB Password | `${DB_PASSWORD}` → `directus123` |

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
