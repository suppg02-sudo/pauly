# Context Files Pack

## What This Provides

Genericized context files stripped of host specifics. Copy these to `~/.config/opencode/context/` on the new server.

## Files

| File | Purpose |
|------|---------|
| `standards/coding.md` | Coding conventions for shell, Docker, Astro, Directus |
| `workflows/workflows.md` | Standard procedures: deploy, publish, update, backup, troubleshoot |

## Installation

```bash
# Create context directory
mkdir -p ~/.config/opencode/context/standards
mkdir -p ~/.config/opencode/context/workflows

# Copy
cp optional/02-context-files/standards/coding.md ~/.config/opencode/context/standards/
cp optional/02-context-files/workflows/workflows.md ~/.config/opencode/context/workflows/
```

## Customization

All files use `${VAR}` references. Replace with your `.env` values:

```bash
# Example: customize workflows for your server
source /opt/pauly/.env
sed -i "s/\${PORT_DIRECTUS}/${PORT_DIRECTUS}/g" ~/.config/opencode/context/workflows/workflows.md
```

Or keep them as-is — the agent reads `.env` at runtime.
