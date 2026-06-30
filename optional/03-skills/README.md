# Skills

## What's Included

The repo already contains two skills in `skills/`:

| Skill | Triggers | Purpose |
|-------|----------|---------|
| `directus-server` | `directus-server`, `ds` | Directus CMS CRUD, health, backup |
| `astro-starlight` | `astro-starlight`, `starlight`, `docs`, `publish-doc` | Docs publishing, rebuild, config |
| `pa` (optional/06-pa-skill) | `pa`, `personal-assistant`, `dashboard` | PA dashboard management |

## Installation

```bash
# Copy skills to OpenCode
cp -r skills/directus-server ~/.config/opencode/skills/
cp -r skills/astro-starlight ~/.config/opencode/skills/

# Optional: PA skill
cp -r optional/06-pa-skill ~/.config/opencode/skills/pa
```

## Key Design Principles

1. **Env-driven**: All scripts `source /opt/pauly/.env` first
2. **API-first**: Never use browser when API works
3. **No hardcoded ports**: Everything reads `${PORT_*}` variables
4. **Status scripts**: Each skill has `scripts/status.sh` for quick health checks
