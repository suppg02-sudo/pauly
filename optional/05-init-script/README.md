# Init/Bootstrap Script

## What This Provides

A single `init.sh` script that bootstraps the entire server from zero to running.

## Usage

```bash
# Full setup (everything)
bash optional/05-init-script/init.sh

# Directus only
bash optional/05-init-script/init.sh --directus

# Astro only
bash optional/05-init-script/init.sh --astro

# Skills + agent config only (skip Docker)
bash optional/05-init-script/init.sh --skills

# Health check only
bash optional/05-init-script/init.sh --check
```

## What It Does (full mode)

1. **Installs** Docker, Node.js 22, Python 3, jq, git
2. **Detects** free ports → fills `.env`
3. **Detects** server IP → fills `SERVER_IP`
4. **Starts** Directus + PostgreSQL + Redis
5. **Creates** the `pages` collection + sets API token + creates test page
6. **Builds** and starts Astro Starlight
7. **Configures** UFW firewall (SSH + your ports only)
8. **Installs** OpenCode skills, AGENTS.md, context files, MCP config
9. **Verifies** all services are healthy

## Prerequisites

- Fresh Ubuntu 22.04 or 24.04 LTS
- Root or sudo access
- Internet access
