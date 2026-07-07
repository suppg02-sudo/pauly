# NextExplorer Setup — New Server Runbook

Install NextExplorer (`nxzai/explorer`) on a fresh host and surface the correct
local volumes so that internal files become linkable as web URLs, e.g.
`http://<hostname>:8080/editor/<mount>/<path>`.

This pairs with the global rule in `AGENTS.md` ("Internal File Links") which tells
agents to render internal file references as these URLs instead of bare paths.

---

## 1. Determine the volumes to surface

NextExplorer exposes whatever you bind-mount under its `/mnt` directory. Each mount
becomes a URL segment: host path `X` mounted at `/mnt/<name>` is reachable at
`/editor/<name>/...`. Decide mounts **per host** by discovering what matters.

### Always mount the host root (catch-all)
Mount `/` → `/mnt/storage` so *every* file is reachable. Use `ro` unless writes are
needed; if RW, set propagation `rslave`.
```
/  →  /mnt/storage   ⇒  http://<host>:8080/editor/storage/...
```
This produces URLs like `editor/storage/root/...` for host `/root/...`.

### Discover the opencode config dir
```
echo "${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
```
If present, mount it read-only at `/mnt/opencode`:
```
/root/.config/opencode  →  /mnt/opencode (ro)   ⇒  editor/opencode/...
```

### Discover the Docker compose root
Check the active docker context and the usual locations, then pick the one that
holds your `docker-compose.yml` files:
```
docker context inspect --format '{{.Endpoints.docker.Host}}' 2>/dev/null
ls -d /media/docker /opt/docker /srv/docker /var/lib/docker/compose 2>/dev/null
find / -maxdepth 4 -name docker-compose.yml 2>/dev/null | head
```
Mount it at `/mnt/docker`:
```
/media/docker  →  /mnt/docker   ⇒  editor/docker/...
```

### Discover other data dirs worth surfacing
List every bind source currently used by running containers — these are the
host paths your stack actually cares about:
```
docker inspect $(docker ps -q) --format '{{range .Mounts}}{{if eq .Type "bind"}}{{.Source}}{{"\n"}}{{end}}{{end}}' | sort -u
```
Mount any meaningful ones (backups, media, project repos) at `/mnt/<shortname>`.

### Optional convenience mounts (short, friendly URLs)
Any extra path the user frequently opens, e.g. `$HOME/freshstart` → `/mnt/freshstart`.

---

## 2. Deploy (docker compose)

`/media/docker/nextexplorer/docker-compose.yml` (adapt paths per host):

```yaml
services:
  nextexplorer:
    image: nxzai/explorer:latest
    container_name: nextexplorer
    restart: unless-stopped
    mem_limit: 256m
    memswap_limit: 512m
    ports:
      - "8080:3000"
    environment:
      - TZ=UTC
      - APP_URL=http://<hostname>:8080
      - AUTH_MODE=disabled          # set to "password" / "oidc" if exposed beyond LAN
    volumes:
      - nextexplorer-config:/config
      - nextexplorer-cache:/cache
      - /:/mnt/storage:rw           # catch-all (use :ro on untrusted hosts)
      - /root/.config/opencode:/mnt/opencode:ro
      - /media/docker:/mnt/docker:rw
      # add discovered mounts here, e.g.:
      # - /root/freshstart:/mnt/freshstart:rw
    labels:
      - "com.opencode.managed=true"
      - "com.opencode.description=Modern self-hosted file explorer"
    logging:
      driver: json-file
      options: { max-size: "10m", max-file: "3" }
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://127.0.0.1:3000/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  nextexplorer-config:
    name: nextexplorer_config
  nextexplorer-cache:
    name: nextexplorer_cache
```

Bring up:
```bash
cd /media/docker/nextexplorer && docker compose up -d
```

---

## 3. URL mapping (the rule agents follow)

For any internal file, build the URL as:

```
http://<hostname>:8080/editor/<mount>/<path-under-that-mount>
```

- `<hostname>` = the server's hostname (e.g. `ubuntu4`) or LAN IP.
- `<mount>` = the name used in the `/mnt/<name>` mount (or `storage` for the root mount).

Default mapping table (ubuntu4 reference; regenerate per host in `environment-awareness.md`):

| Host path | Mount | URL prefix |
|-----------|-------|------------|
| `/root/...` | `storage` (root mount) | `editor/storage/root/...` |
| `~/.config/opencode/...` | `opencode` | `editor/opencode/...` |
| `/media/docker/...` | `docker` | `editor/docker/...` |
| `/root/freshstart/...` | `freshstart` | `editor/freshstart/...` |

Note: because `/` is mounted at `/mnt/storage`, `~/.config/opencode/AGENTS.md` is
*also* reachable as `editor/storage/root/.config/opencode/AGENTS.md` — but prefer
the short dedicated-mount URL (`editor/opencode/AGENTS.md`) when available.

---

## 4. Verify

```bash
curl -sI http://<hostname>:8080/healthz        # expect HTTP/1.1 200
curl -s -o /dev/null -w "%{http_code}\n" \
  http://<hostname>:8080/editor/opencode/AGENTS.md   # expect 200
```

If healthz is 200 and a sample editor URL returns 200, the server is ready and the
global "Internal File Links" rule applies.
