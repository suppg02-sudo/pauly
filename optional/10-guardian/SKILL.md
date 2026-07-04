# Guardian — System + Container Health Monitoring

Installs a generalised watchdog that monitors **both host-level system health** and **pauly Docker containers** in a single self-contained script.

## What It Monitors

| Layer | Checks |
|-------|--------|
| **Host** | systemd services (earlyoom, memory-watchdog, psi-monitor), available RAM, swap usage, PSI pressure, log file sizes |
| **Containers** | Directus, Astro Starlight, PostgreSQL, Redis — health status, restart loops, CPU/memory |
| **Astro Blog** | HTTP health check (port from `PORT_ASTRO`), crash-loop detection, container state, restart count |
| **Tracking** | Restart history with 15-min backoff detection |

## Installation

```bash
# Option A: Script only
bash /opt/pauly/optional/10-guardian/scripts/install.sh

# Option B: Full systemd timer (recommended)
bash /opt/pauly/optional/10-guardian/scripts/install.sh --service

# Verify
bash /opt/pauly/optional/10-guardian/scripts/install.sh --verify
```

## Usage

```bash
# On-demand checks
pauly-guardian.sh status          # Full system snapshot
pauly-guardian.sh report          # Latest logs from all watchers
pauly-guardian.sh improvements    # Diagnostic recommendations
```

## Trigger (OpenCode)

Use `g` or `guardian` to present the menu.

## Configuration

Set these via `.env` or environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `CONTAINER_NAMES` | `directus astro-docs postgres redis` | Space-separated container list |
| `GUARDIAN_LOG_DIR` | `/var/log/pauly-guardian` | Log directory |
| `GUARDIAN_LOG_MAX_MB` | `10` | Log rotation threshold |
