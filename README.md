# Pauly — Directus + Astro Starlight Docs Server

A self-contained documentation platform: **Directus CMS** as the content backend, **Astro Starlight** as the docs frontend, integrated via REST API.

## What You Get

- **Directus** on `${PORT_DIRECTUS}` — headless CMS with admin UI, REST API, PostgreSQL + pgvector, Redis cache
- **Astro Starlight** on `${PORT_ASTRO}` — docs site with sidebar, search, dark mode, dynamic pages from Directus
- **Port auto-detection** — no hardcoded ports; `detect-ports.sh` finds free ports
- Two **OpenCode skills** for CLI management

## Quick Start

```bash
# 1. Clone
git clone https://github.com/suppg02-sudo/pauly.git
cd pauly

# 2. Configure
cp .env.example .env
bash scripts/detect-ports.sh    # auto-fill free ports + detect server IP

# 3. Deploy
cd directus && docker compose up -d && cd ..
sleep 10
cd astro-docs && docker compose up -d && cd ..

# 4. Verify
source .env
curl http://localhost:${PORT_DIRECTUS}/server/health
curl http://localhost:${PORT_ASTRO}/
```

## Configuration

All config lives in `.env`. Key variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT_DIRECTUS` | `8056` | Directus admin + API |
| `PORT_ASTRO` | `3003` | Astro docs site |
| `PORT_POSTGRES` | `5433` | PostgreSQL |
| `PORT_REDIS` | `6380` | Redis |
| `SERVER_IP` | auto | Server IP (auto-detected) |

Run `bash scripts/detect-ports.sh --check` to verify ports are free without modifying `.env`.

## Docs

- [SETUP.md](./SETUP.md) — Full 7-phase installation guide
- [AGENTS.md](./AGENTS.md) — Instructions for AI agents
- [scripts/detect-ports.sh](./scripts/detect-ports.sh) — Port auto-detection

## License

MIT
