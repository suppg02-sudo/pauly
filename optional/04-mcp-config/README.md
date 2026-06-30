# MCP Server Configuration Template

## What This Provides

A template `opencode.json` MCP section for the new server. These are MCP servers commonly used with OpenCode for IDE integration.

## Template

Copy this into your `~/.config/opencode/opencode.json` under the `mcp` key:

```json
{
  "mcp": {
    "context7": {
      "type": "remote",
      "url": "http://127.0.0.1:8801/sse",
      "enabled": true
    },
    "agent-browser": {
      "type": "remote",
      "url": "http://127.0.0.1:8803/sse",
      "enabled": true
    },
    "github": {
      "type": "remote",
      "url": "http://127.0.0.1:8804/sse",
      "enabled": true
    },
    "brave-search": {
      "type": "remote",
      "url": "http://127.0.0.1:8802/sse",
      "enabled": true
    }
  }
}
```

## MCP Server Setup

Each MCP server runs as a separate process. To start them:

### context7 (documentation lookup)
```bash
npx -y @upstash/context7-mcp --port 8801
```

### agent-browser (Playwright automation)
```bash
npx -y agent-browser-mcp --port 8803
```

### github (GitHub API)
```bash
npx -y @modelcontextprotocol/server-github --port 8804
```

### brave-search (web search)
```bash
npx -y @brave/brave-search-mcp-server --port 8802
```

## Systemd Services (Recommended)

For persistent MCP servers, create systemd services:

```bash
# Example: context7
cat > /etc/systemd/system/mcp-context7.service << EOF
[Unit]
Description=MCP Context7 Server
After=network.target

[Service]
Type=simple
ExecStart=/root/.npm-global/bin/npx -y @upstash/context7-mcp --port 8801
Restart=unless-stopped
Environment=HOME=/root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now mcp-context7
```

## Port Configuration

MCP server ports (8801-8804) are NOT in the main `.env` — they're internal to OpenCode. Change them in the `opencode.json` template if needed.

## Installation

```bash
# Merge MCP config into your opencode.json
python3 -c "
import json
with open('/root/.config/opencode/opencode.json') as f:
    cfg = json.load(f)
with open('optional/04-mcp-config/mcp-template.json') as f:
    mcp = json.load(f)
cfg.setdefault('mcp', {}).update(mcp['mcp'])
with open('/root/.config/opencode/opencode.json', 'w') as f:
    json.dump(cfg, f, indent=2)
print('MCP config merged')
"
```
