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
3. bash optional/06-init-script/init.sh    # does everything
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
9. (optional) bash optional/06-init-script/init.sh --skills
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
    ├── 03-triggers/                 ← Word-activated command protocols (16 triggers)
    ├── 04-skills/                   ← Skills installation guide
    ├── 05-mcp-config/               ← MCP server config (context7, github, browser, search)
    ├── 06-init-script/              ← Full bootstrap: init.sh (zero to running)
    ├── 07-pa-skill/                 ← PA dashboard (HTML + systemd service)
    ├── 08-react-admin/              ← React-Admin demo panel (optional backend for Directus)
    ├── 09-setuprefine/              ← Repo self-analysis + improvement proposals (trigger: setuprefine)
    ├── 10-guardian/                 ← System + container health watchdog (trigger: guardian)
    ├── 11-monitoring/               ← Monitoring stack
    ├── 12-skill-factory/            ← Meta-skill for creating secure, mature skills
    └── 13-ingestionsetup/           ← Remote ingestion API client (URL → blog post + podcast)
```

## Triggers
- `?` / `what next` : Analyse state, surface priorities, recommend next step.
- `co` : Resume most recent task with full context recovery.
- `u` / `update` : Review session work, propose skill/context updates.
- `improve` : Improve ANY component — skills, prompts, menus, config.
- `bs` / `brainstorm` : Structured ideation and design sessions.
- `session` : Session recovery after compaction — diagnose and fix.
- `d` / `deferred` : Parked task management — review, resume, archive.
- `flow` : Trace and analyse how tasks execute.
- `smooth` : Identify and fix friction in workflows.
- `g` / `guardian` : Present the Guardian menu (system health).
- `nx` / `next-explorer` : Redisplay recent session files as clickable links.
- `menu` : Central menu hub for all commands and skills.
- `vc` / `visual-companion` : Browser-based diagram generation (requires skill).
- `cron` : View, edit, monitor scheduled tasks.
- `space` / `sp` : Disk space analysis and cleanup.
- `svg` / `diagram` : Publication-ready SVG diagrams (requires skill).
- `setuprefine` : Run repository self-analysis.

## Optional Phases

| Phase | What | When to Use |
|-------|------|-------------|
| `optional/01-agents-md` | AGENTS.md with behavioral rules, safety rules, triggers | Always — gives the agent instructions |
| `optional/02-context-files` | Coding standards + workflow templates | When you want consistent conventions |
| `optional/03-triggers` | Word-activated command protocols (16 triggers: `co`, `?`, `u`, `bs`, `g`, etc.) | When you want quick-command workflows |
| `optional/04-skills` | Installation guide for repo skills | When installing skills on the server |
| `optional/05-mcp-config` | MCP servers (context7, github, browser, brave-search) | When using OpenCode IDE features |
| `optional/06-init-script` | One-command bootstrap (`init.sh`) | Fresh server — does everything |
| `optional/07-pa-skill` | PA dashboard HTML + systemd service | When you want a visual architecture overview |
| `optional/08-react-admin` | React-Admin demo panel | When you need a full admin UI (optional Directus backend) |
| `optional/09-setuprefine` | Repo self-analysis + improvement proposals | Run after changes to catch issues — trigger: `setuprefine` |
| `optional/10-guardian` | System + container health watchdog | Full host + Docker monitoring — trigger: `guardian` |
| `optional/11-monitoring` | Monitoring stack | When you want Prometheus/Grafana observability |
| `optional/12-skill-factory` | Meta-skill for creating secure, mature skills | When creating new skills on the server |
| `optional/13-ingestionsetup` | Remote ingestion API client setup | When other machines on LAN/VPN should auto-ingest URLs |

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

## Behavioral Rules

These rules define how the agent should behave when working on this repo:

### Process
- **Rules first, commands second**: This file defines behavior; command/tool details live in dedicated context files under `optional/03-triggers/templates/`.
- **Load skills first**: Before acting, load every skill that might apply (even 1% chance). Skills define how to approach tasks correctly.
- **Be creative**: Don't just execute — propose better paths if you see one.
- **Context over memory**: Persistent rules belong here, in skills, or in context files. Never rely on session memory for repeatable behavior.
- **Use NextExplorer**: After completing any session task, run the `nx` trigger to display clickable links for modified files.

### Quality
- **Test fixes**: Verify after changes. Don't report done without evidence. Check via `curl`, container logs, or lint/build as appropriate.
- **Prevent recurrence**: After fixing any issue, proactively suggest improvements to avoid the same or similar issues — configs, monitoring, host tuning, health checks.
- **No interactive editors**: Never use interactive editors (nano, vim). Use Python, here-docs, or other non-interactive constructs.
- **Double-check webservers**: After any deployment, `curl` the actual endpoint and confirm a 200 OK status and expected content. Never assume a connection means success.

### Safety
- **Deletion safety**: Deletions need explicit confirmation, current target verification, and auth check before executing.
- **Dangerous commands**: Run an audit checklist before executing destructive commands (rm -rf, docker system prune, dd, etc.).
- **Docker cleanup**: Limited to cache/dangling/stopped containers only. Never prune volumes or systems.
- **Unique port picking**: Before any deployment, explicitly verify that the chosen ports in `.env` are not already in use using `ss -tuln` or `lsof -i`. Don't rely solely on `detect-ports.sh`.

### Presentation
- **Menu presentation**: Always use the question tool with clear options. Lead with `(Recommended)`. Always include an exit option. Never hand-craft question JSON.

### Anti-Patterns
- Don't auto-load skills unless triggered by user intent
- Don't use `fetch` when `web_search`/`browser`/`mcp` is available
- Don't ignore local or MCP-available tools in favour of remote alternatives

## Project Rules

1. **API-first**: Never use a browser for tasks the API handles (see skills)
2. **Always set `date_published`**: Pages without it are filtered out
3. **Rebuild after new files**: `docker compose build --no-cache && docker compose up -d`
4. **Shared Docker network**: Both services must be on `${DOCKER_NETWORK}`
5. **Read `.env` for ports**: Never assume port numbers — always check `.env`
6. **Run detect-ports.sh** before first deploy to avoid conflicts

## Smart Setup Workflow

When setting up Pauly on a new or partially-configured server, use this workflow to avoid redundant work:

1. **Detect state**: `bash scripts/check-setup.sh` — returns JSON of all 16 phases with `done`/`pending` status
2. **Parse remaining**: Filter `pending` phases from the JSON output
3. **Present via question tool**: Show only remaining phases as options with `(Recommended)` on the most impactful next step. Always include "Run all remaining" as the first option.
4. **Execute**: Run `bash optional/06-init-script/init.sh --smart` for auto-execution of remaining phases, or use a specific flag (`--directus`, `--astro`, `--skills`, etc.) for individual phases.

**Check script output example:**
```json
{"phases":[
  {"id":"deps","label":"Install system dependencies","status":"done"},
  {"id":"directus","label":"Start Directus container","status":"pending"},
  {"id":"astro","label":"Start Astro Starlight container","status":"pending"}
],"summary":{"total":16,"done":14,"pending":2}}
```

**Menu example:**
```
2 phases remaining — which to run?

1. Start Directus container (Recommended)
2. Start Astro Starlight container
3. Exit
```

This prevents the "already-installed" problem: the user never sees options for things already completed.

## Progress Tracking

Every setup run creates/appends to `progress.md` at the repo root. This is a historical record of all phases, bugs, fixes, diversions, improvements, and errors.

**Format** (markdown table):
```
| Timestamp | Phase | Type | Message |
|-----------|-------|------|---------|
| 2026-07-04T12:00:00Z | directus | INFO | Healthy on port 8056 |
| 2026-07-04T12:01:00Z | collection | ERROR | Admin login failed |
| 2026-07-04T12:02:00Z | astro | DIVERSION | Not responding after 40s |
```

**Types**: `INFO`, `BUG`, `FIX`, `DIVERSION`, `IMPROVEMENT`, `ERROR`

**Agent rules**:
- **Always check `progress.md`** at the start of any setup task — it shows what's already been done and what went wrong
- **Log everything**: When you encounter a bug, fix, diversion, or improvement during setup, append a row to `progress.md`
- **Never delete history**: Only append. The file is a cumulative log across all setup runs
- **Use the helper functions**: `init.sh` provides `log_info`, `log_bug`, `log_fix`, `log_diversion`, `log_improvement`, `log_error` for bash-level logging

## Dependencies

- Docker 24+ with Docker Compose v2
- Ubuntu 22.04 or 24.04 LTS
