# g — Present Guardian system health menu — reports, status, improvements

> **Trigger**: `g`, `guardian` | **Purpose**: Present Guardian system health menu — reports, status, improvements
> **When to use**: (describe when user should type this trigger)

---

## How It Works

When the user types this trigger, follow the phases below.

---

### Phase 0

Verify guardian script exists at ${GUARDIAN_SCRIPT:-/usr/local/bin/guardian-status.sh}

### Phase 1

Run guardian-status.sh with appropriate mode for each option

### Phase 2

Present menu: Read Report, Improvements, Check Status, Blog Post, Extend Guardian, Exit

## Data Source

The guardian script at `${GUARDIAN_SCRIPT:-/usr/local/bin/guardian-status.sh}` provides:
- `report` — latest logs from all watchers
- `status` — system health snapshot
- `improvements` — diagnostic recommendations

Set `GUARDIAN_SCRIPT` in `.env` to override the path.
