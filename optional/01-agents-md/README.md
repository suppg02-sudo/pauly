# Optional Phase 01: AGENTS.md Template

## What This Provides

A genericized `AGENTS.md` — the file OpenCode reads first to learn how to behave on the new server. Includes:

- Behavioral rules (question tool, skill loading, test fixes, shell mode)
- Safety rules (deletion confirmation, dangerous command audit, docker cleanup limits)
- Session wrap-up protocol
- Trigger command registration (pa, nginx, updates, cron)
- Infrastructure table (all ports env-driven)

## Installation

```bash
# Copy to OpenCode config
cp optional/01-agents-md/AGENTS.template.md ~/.config/opencode/AGENTS.md

# Edit to match your server
nano ~/.config/opencode/AGENTS.md
```

## What's Included

| Section | Source |
|---------|--------|
| Behavioral rules | Selected from production AGENTS.md |
| Safety rules | All 3 (deletion, dangerous commands, docker cleanup) |
| Session wrap-up | Protocol for verifying work on "done" |
| Trigger commands | pa, nginx/npm, updates/uc, cron/cr |
| Infrastructure table | All services with `${PORT_VAR}` references |

## What's NOT Included (intentionally)

- Host-specific paths (e.g. `/media/docker/`)
- Production credentials
- Hostnames (e.g. `ubuntu4`)
- VPN/host infrastructure references
- Revenue/income directives (personal to original setup)
