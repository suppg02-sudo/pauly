# Skill: guardian

# Guardian

Pauly system health monitoring — both host-level and container-level watchdog.

## Status

Run health checks, view logs, and get improvement recommendations. Monitors host services (systemd, memory, swap, PSI) and pauly containers (Directus, Astro, Postgres, Redis).

## Usage

Trigger via `g` or `guardian` to present the menu.

## Menu Options

- **Status** — Full system snapshot: services, containers, memory, swap, PSI, restarts, log sizes
- **Report** — Latest logs from all watchers (containers + host services)
- **Improvements** — Diagnostic recommendations with severity ratings (HIGH/MED/LOW/WARN)
- **Install** — Set up guardian as a systemd timer (every 15 min)
- **Verify** — Check installation status

## Trigger Commands

- `g` / `guardian` — Present Guardian menu.

## Script

- `scripts/guardian.sh` — Self-contained watchdog (host + Docker)
- `optional/10-guardian/scripts/install.sh` — System installer with systemd support

## Integration

- Config via `.env`: `CONTAINER_NAMES`, `GUARDIAN_LOG_DIR`, `GUARDIAN_LOG_MAX_MB`
- Systemd timer: `pauly-guardian.timer` runs every 15 minutes
- Log dir: `/var/log/pauly-guardian/`
