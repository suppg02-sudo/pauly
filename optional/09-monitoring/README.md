# Monitoring & Proxy (Optional Phase 9)

## What This Provides

Optional Nginx Proxy Manager + Grafana stack. Uses `NPM_PASSWORD`, `GRAFANA_PASSWORD` from root `.env`.

## Services

| Service | Port | Purpose |
|---------|------|---------|
| Nginx Proxy Manager | `${PORT_NPM:-81}` | Reverse proxy, SSL, domain routing |
| Grafana | `${PORT_GRAFANA:-3004}` | Dashboard visualization |

## Usage

```bash
source /opt/pauly/.env
cd /opt/pauly/optional/09-monitoring
docker compose up -d
```

## Credentials

- NPM admin: `admin@example.com` / `changeme` (change on first login)
- Grafana admin: `admin` / `${GRAFANA_PASSWORD}` from `.env`
