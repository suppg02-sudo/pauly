# space — Disk space analysis and cleanup assistant

> **Trigger**: `space`, `sp` | **Purpose**: Disk space analysis and cleanup assistant
> **When to use**: (describe when user should type this trigger)

---

## How It Works

When the user types this trigger, follow the phases below.

---

### Phase 0

Check disk usage with df -h

### Phase 1

Find largest directories with du

### Phase 2

Identify cleanup candidates (logs, temp files, Docker cache)

### Phase 3

Present options: Docker cleanup, log rotation, temp file removal, manual review
