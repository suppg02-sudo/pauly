# AGENTS.md Template — Genericized for New Server

> Copy this to the server's `~/.config/opencode/AGENTS.md`. It defines how the AI agent behaves. All host-specific values use `${VAR}` — replace with your `.env` values or leave as-is for localhost.

---

## Behavioral Rules

### Process
- **Rules first, commands second**: This file defines behavior; command details live in dedicated files. AGENTS.md is for rules, not implementation.
- **Load skills first**: Before acting, load every skill that might apply (even 1% chance).
- **Reuse existing infra**: Prefer Docker, local services, or MCP tools over ad-hoc commands.
- **Be creative**: Propose better paths — don't just execute blindly.
- **Context over memory**: Persistent rules belong in AGENTS.md, skills, or context files; memory is not persistent.
- **Use NextExplorer**: After completing any session task, run the `nx` trigger to display clickable links for modified files.

### Quality
- **Test fixes**: Verify after changes. Don't report done without evidence. Check via `curl`, container logs, or lint/build as appropriate.
- **Prevent recurrence**: After fixing any issue, proactively suggest improvements — configs, monitoring, host tuning, health checks.
- **No interactive editors**: Never use interactive editors without PTY. Use Python, here-docs, or other non-interactive constructs.
- **Double-check webservers**: After any deployment, `curl` the actual endpoint and confirm a 200 OK status and expected content. Never assume a connection means success.

### Safety and Verification
- **Deletion safety**: Deletions need explicit confirmation, current target verification, and auth before executing.
- **Dangerous commands** (`rm -rf`, `dd`, `mkfs`, `chmod 777`, `iptables -F`): Need an audit checklist before running.
- **Docker cleanup**: Limited to cache/dangling/stopped containers only. Must be treated as dev-only. Never prune volumes or systems.
- **Unique port picking**: Before any deployment, explicitly verify that the chosen ports in `.env` are not already in use using `ss -tuln` or `lsof -i`. Don't rely solely on `detect-ports.sh`.

### Presentation
- **Menu presentation**: Always use the question tool with clear options. Lead with `(Recommended)`. Always include an exit option. Numbered options so users can select by typing the number.
- **Never hand-craft question JSON**: Use the proper tool or skill to generate menu payloads.

### Anti-Patterns
- Don't auto-load skills unless triggered by user intent
- Don't use `fetch` when `web_search`/`browser`/`mcp` is available
- Don't ignore local or MCP-available tools in favour of remote alternatives

## Session Wrap-up Protocol

On "done" or session end:
1. Verify all services healthy: `source .env && curl http://localhost:${PORT_DIRECTUS}/server/health && curl -o /dev/null -w "%{http_code}" http://localhost:${PORT_ASTRO}/`
2. Confirm no orphaned processes or broken containers
3. Summarize what changed (files modified, containers restarted)
4. Suggest next steps or improvements

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
