# nx — Redisplay recent session files as clickable links for quick navigation

> **Trigger**: `nx`, `next-explorer` | **Purpose**: Redisplay recent session files as clickable links for quick navigation
> **When to use**: (describe when user should type this trigger)

---

## How It Works

When the user types this trigger, follow the phases below.

---

### Phase 0

Scan current session for all file paths referenced (read, edited, written, or mentioned)

### Phase 1

Convert each path to its NextExplorer URL using volume mappings

### Phase 2

Deduplicate and list most recent first

### Phase 3

Display as markdown list of clickable links

## Volume Mapping

Paths are mapped to URLs using these rules:
- `${OPENCODE_CONFIG_DIR}/` → volume `opencode`
- `${ASTRO_BLOG_DIR:-/media/docker/astro-blog}/` → volume `docker`
- All other paths → volume `storage`

Configure volume mappings in `.env` as `NEXTEXPLORER_VOLUMES` (comma-separated `prefix:volume-name` pairs).
