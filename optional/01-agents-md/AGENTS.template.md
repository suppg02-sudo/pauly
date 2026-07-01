# AGENTS.md Template — Genericized for New Server

> Copy this to the server's `~/.config/opencode/AGENTS.md`. It defines how the AI agent behaves. All host-specific values use `${VAR}` — replace with your `.env` values or leave as-is for localhost.

---

## Behavioral Rules

- **use question tool**: every menu or choice uses the question tool
- **load skills first**: before acting, load every skill that might apply
- **reuse existing infra**: prefer Docker, local services, or MCP tools over ad-hoc commands
- **be creative**: propose better paths, don't just execute
- **test fixes**: verify after changes; do not report done without evidence (curl, lint, build, container logs)
- **prevent recurrence**: after fixing any issue, proactively suggest improvements — configs, monitoring, health checks
- **context over memory**: persistent rules belong in AGENTS.md, skills, or context files; memory is not persistent
- **shell mode**: no interactive editors without pty; use Python/heredoc instead of cat/sed

## Safety and Verification

- **deletions**: need explicit confirmation, current target verification, and auth before running
- **dangerous commands** (`rm -rf`, `dd`, `mkfs`, `chmod 777`, `iptables -F`): need an audit checklist before running
- **docker cleanup**: limited to cache/dangling/stopped containers only; must be treated as dev-only

## Session Wrap-up Protocol

On "done" or session end:
1. Verify all services healthy: `source .env && curl http://localhost:${PORT_DIRECTUS}/server/health && curl -o /dev/null -w "%{http_code}" http://localhost:${PORT_ASTRO}/`
2. Confirm no orphaned processes or broken containers
3. Summarize what changed (files modified, containers restarted)
4. Suggest next steps or improvements

## Menu Presentation

- Always use the question tool with clear options
- Lead with `(Recommended)` on the best option
- Always include an exit option
- Numbered options so users can select by typing the number

## Trigger Commands

Register these in your OpenCode config:

| Trigger | Action |
|---------|--------|
| `pa` / `personal-assistant` | Load PA skill — manage dashboard |
| `nginx` / `npm` / `proxy` | Manage Nginx Proxy Manager |
| `updates` / `uc` | Check for available updates (apt, Docker images, npm) |
| `cron` / `cr` | View, edit, and monitor cron jobs |
| `setuprefine` / `sr` | Analyse repo + propose improvements |

## Infrastructure

| Service | Port (from `.env`) | Container |
|---------|---------------------|-----------|
| Directus | `${PORT_DIRECTUS}` | `directus` |
| Astro | `${PORT_ASTRO}` | `astro-docs` |
| PostgreSQL | `${PORT_POSTGRES}` | `directus-postgres` |
| Redis | `${PORT_REDIS}` | `directus-redis` |
| NPM (optional) | `${PORT_NPM}` | `nginxproxy` |
| Grafana (optional) | `${PORT_GRAFANA}` | `grafana` |
| PA Dashboard (optional) | `${PORT_PA}` | systemd |

## Rules for This Server

1. **Read `.env` first**: `source /opt/pauly/.env` before any command that touches ports or credentials
2. **No hardcoded ports**: Every port is a variable defined in `.env`
3. **API-first**: Never use a browser for Directus tasks the API handles
4. **Rebuild after new files**: `docker compose build --no-cache && docker compose up -d`
5. **Shared Docker network**: Both services must be on `${DOCKER_NETWORK}`
