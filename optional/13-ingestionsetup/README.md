# Optional Phase 13: Ingestion API Client Setup

## What This Provides

A two-file setup that makes any IDE on the LAN/VPN automatically send pasted URLs to the ingestion router API on the main server. No manual steps — paste a URL, get a blog post + podcast back.

| File | Purpose |
|------|---------|
| `agents-md-addition.md` | 4-line amendment to append to the IDE's global `AGENTS.md` — just the trigger rule |
| `SKILL.md` | Full API reference — endpoints, params, response handling, queue operations. Loaded only when a URL is pasted. |

## How It Works

```
User pastes URL into chat
        ↓
AGENTS.md trigger fires → loads SKILL.md
        ↓
SKILL.md tells agent to POST to /quick on the ingestion server
        ↓
Server runs: detect type → apply defaults → blog post → podcast narration
        ↓
Agent reports: blog URL + audio URL
```

## Installation

### 1. Install the Skill File

```bash
# Create skill directory
mkdir -p ~/.config/opencode/skills/ingestion-api

# Copy the skill file
cp optional/13-ingestionsetup/SKILL.md ~/.config/opencode/skills/ingestion-api/SKILL.md
```

### 2. Amend Global AGENTS.md

```bash
# Append the trigger rule
cat optional/13-ingestionsetup/agents-md-addition.md >> ~/.config/opencode/AGENTS.md
```

### 3. Set the Server Hostname

Edit `~/.config/opencode/skills/ingestion-api/SKILL.md` and replace `INGESTION_HOST` with your server's hostname or IP.

```bash
# Example: if your server is 192.168.1.48
sed -i 's/INGESTION_HOST/192.168.1.48/g' ~/.config/opencode/skills/ingestion-api/SKILL.md
```

### 4. Verify

```bash
# Test connectivity from the client machine
curl -s http://INGESTION_HOST:8913/health
# Should return: {"status":"ok","service":"ingestion-router-api"}
```

Restart your IDE session after install — the skill system caches at startup.

## Requirements

- The ingestion router API must be running on the main server (port 8913)
- The client machine must be able to reach the server over LAN or VPN
- `curl` available on the client

## IDE Compatibility

| IDE | AGENTS.md Location | Skill Location |
|-----|-------------------|----------------|
| OpenCode | `~/.config/opencode/AGENTS.md` | `~/.config/opencode/skills/` |
| Claude Code | `~/.claude/CLAUDE.md` | `~/.claude/skills/` |
| Cursor | `~/.cursorrules` | `~/.cursor/skills/` |
| Cline | `~/.cline/cline_rules.md` | `~/.cline/skills/` |

For non-OpenCode IDEs: adjust paths in `agents-md-addition.md` to match the tool's config location.
