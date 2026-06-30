# PA (Personal Assistant) Dashboard Skill

## What This Provides

A genericized version of the PA dashboard skill — an interactive HTML page showing your server's architecture (Publish/Learn/Manage pillars + AI/Application/Infrastructure layers). All links are env-driven.

## Files

| File | Purpose |
|------|---------|
| `SKILL.md` | Skill instructions (genericized) |
| `personal-assistant.html` | The dashboard HTML (env-driven links) |
| `scripts/deploy.sh` | Deploys HTML with env values replaced |

## Installation

```bash
# Copy skill to OpenCode
cp -r optional/06-pa-skill ~/.config/opencode/skills/pa

# Deploy the dashboard HTML
source /opt/pauly/.env
bash optional/06-pa-skill/scripts/deploy.sh

# Create systemd service
source /opt/pauly/.env
cat > /etc/systemd/system/pa-dashboard.service << EOF
[Unit]
Description=PA Dashboard
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/pauly
ExecStart=/usr/bin/python3 -m http.server ${PORT_PA:-8901} --directory /opt/pauly
Restart=unless-stopped

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now pa-dashboard
```

## Verify

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:${PORT_PA:-8901}/personal-assistant.html
# Expected: 200
```

## Customization

Edit `personal-assistant.html` to add/remove pillars, layers, badges, and icons. The `LINKS` object in the `<script>` section defines all URLs — all read from `.env` values.

## What's Different from Production

| Production | This Version |
|------------|--------------|
| `ubuntu4` hostname | `${SERVER_IP}` from `.env` |
| Port `8901` hardcoded | `${PORT_PA}` from `.env` |
| Links to ~20 services | Links to 3 core services (Directus, Astro, OpenCode) |
| 2268 lines | ~180 lines (clean slate to build on) |
| `fileserver-8901` service | `pa-dashboard.service` (generic) |
