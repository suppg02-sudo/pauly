#!/bin/bash
###############################################################################
# init.sh — Full server bootstrap for Pauly (Directus + Astro Starlight)
#
# Usage:
#   bash optional/05-init-script/init.sh              # Full setup
#   bash optional/05-init-script/init.sh --directus   # Directus only
#   bash optional/05-init-script/init.sh --astro      # Astro only
#   bash optional/05-init-script/init.sh --skills     # Skills + agent config only
#   bash optional/05-init-script/init.sh --check      # Health check only
#
# This script:
#   1. Installs Docker, Node.js, dependencies
#   2. Detects free ports and fills .env
#   3. Starts Directus + Astro
#   4. Creates the Directus 'pages' collection
#   5. Installs OpenCode skills + agent config
#   6. Verifies everything is healthy
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="$REPO_ROOT/.env"

# ── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
fail()  { echo -e "${RED}[FAIL]${NC}  $*"; exit 1; }

# ── Parse Args ───────────────────────────────────────────────────────────────
MODE="full"
for arg in "$@"; do
  case $arg in
    --directus)  MODE="directus" ;;
    --astro)     MODE="astro" ;;
    --skills)    MODE="skills" ;;
    --check)     MODE="check" ;;
    --full)      MODE="full" ;;
  esac
done

# ── Load .env ────────────────────────────────────────────────────────────────
load_env() {
  if [ ! -f "$ENV_FILE" ]; then
    warn ".env not found, creating from .env.example"
    cp "$REPO_ROOT/.env.example" "$ENV_FILE"
  fi
  set -a
  source "$ENV_FILE"
  set +a
}

# ── Phase 1: Install Dependencies ───────────────────────────────────────────
install_deps() {
  info "Installing system dependencies..."

  if ! command -v docker &>/dev/null; then
    info "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    usermod -aG docker "$USER" 2>/dev/null || true
    ok "Docker installed"
  else
    ok "Docker already installed"
  fi

  if ! command -v node &>/dev/null; then
    info "Installing Node.js 22..."
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
    apt-get install -y nodejs
    ok "Node.js installed"
  else
    ok "Node.js $(node -v) already installed"
  fi

  apt-get install -y python3 python3-pip git jq curl > /dev/null 2>&1 || true
  ok "Dependencies ready"
}

# ── Phase 2: Detect Ports ───────────────────────────────────────────────────
detect_ports() {
  info "Detecting free ports..."
  bash "$REPO_ROOT/scripts/detect-ports.sh"
  load_env

  # Auto-detect SERVER_IP if localhost
  if [ "${SERVER_IP:-}" = "localhost" ] || [ -z "${SERVER_IP:-}" ]; then
    DETECTED_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "")
    if [ -n "$DETECTED_IP" ] && [ "$DETECTED_IP" != "127.0.0.1" ]; then
      sed -i "s|^SERVER_IP=.*|SERVER_IP=${DETECTED_IP}|" "$ENV_FILE"
      load_env
      ok "SERVER_IP detected: $SERVER_IP"
    fi
  fi
}

# ── Phase 3: Start Directus ─────────────────────────────────────────────────
start_directus() {
  info "Starting Directus..."
  cp "$ENV_FILE" "$REPO_ROOT/directus/.env"
  docker compose -f "$REPO_ROOT/directus/docker-compose.yml" up -d

  info "Waiting for Directus to bootstrap..."
  for i in $(seq 1 30); do
    if curl -sf "http://localhost:${PORT_DIRECTUS:-8056}/server/health" | grep -q "ok"; then
      ok "Directus healthy on port ${PORT_DIRECTUS}"
      break
    fi
    sleep 2
    [ $i -eq 30 ] && fail "Directus failed to start"
  done
}

# ── Phase 4: Create Directus Collection ─────────────────────────────────────
setup_collection() {
  info "Setting up Directus collections and token..."

  # Login as admin
  ADMIN_TOKEN=$(curl -sf -X POST "http://localhost:${PORT_DIRECTUS}/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"${ADMIN_EMAIL}\",\"password\":\"${ADMIN_PASSWORD}\"}" \
    | jq -r '.data.access_token') || fail "Admin login failed"

  # Set static token
  curl -sf -X PATCH "http://localhost:${PORT_DIRECTUS}/users/me" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"token\":\"${DIRECTUS_TOKEN}\"}" > /dev/null

  # Create pages collection
  curl -sf -X POST "http://localhost:${PORT_DIRECTUS}/collections" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "collection": "pages",
      "meta": { "icon": "article" },
      "schema": { "name": "pages" },
      "fields": [
        { "field": "id", "type": "integer", "schema": { "is_primary_key": true, "has_auto_increment": true }, "meta": { "hidden": true } },
        { "field": "title", "type": "string", "schema": { "is_nullable": false }, "meta": { "interface": "input", "width": "full" } },
        { "field": "slug", "type": "string", "schema": { "is_unique": true }, "meta": { "interface": "input", "width": "half" } },
        { "field": "status", "type": "string", "schema": { "default_value": "published" },
          "meta": { "interface": "select-dropdown", "options": { "choices": [{"text":"Draft","value":"draft"},{"text":"Published","value":"published"}] } } },
        { "field": "content", "type": "text", "meta": { "interface": "input-code", "language": "markdown", "width": "full" } },
        { "field": "excerpt", "type": "string", "meta": { "interface": "input", "width": "full" } },
        { "field": "order", "type": "integer", "schema": { "default_value": 0 }, "meta": { "interface": "input", "width": "half" } },
        { "field": "category", "type": "string", "meta": { "interface": "input", "width": "half" } },
        { "field": "tags", "type": "json", "meta": { "interface": "tags", "width": "full" } },
        { "field": "date_published", "type": "timestamp", "meta": { "interface": "datetime", "width": "half" } },
        { "field": "date_updated", "type": "timestamp", "meta": { "interface": "datetime", "width": "half", "special": ["current-update"] } },
        { "field": "featured_image", "type": "uuid", "meta": { "interface": "file-image", "width": "half" } }
      ]
    }' > /dev/null 2>&1 && ok "pages collection created" || warn "pages collection may already exist"

  # Public read access
  curl -sf -X POST "http://localhost:${PORT_DIRECTUS}/permissions" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{ "role": null, "collection": "pages", "action": "read", "fields": ["*"] }' > /dev/null 2>&1 || true

  # Create test page
  curl -sf -X POST "http://localhost:${PORT_DIRECTUS}/items/pages" \
    -H "Authorization: Bearer ${DIRECTUS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"title\":\"Getting Started\",\"slug\":\"getting-started\",\"status\":\"published\",\"order\":1,\"date_published\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"excerpt\":\"Welcome\",\"content\":\"# Getting Started\n\nWelcome!\"}" > /dev/null 2>&1 && ok "Test page created" || true
}

# ── Phase 5: Start Astro ────────────────────────────────────────────────────
start_astro() {
  info "Starting Astro Starlight..."
  cp "$ENV_FILE" "$REPO_ROOT/astro-docs/.env"
  docker network create "${DOCKER_NETWORK}" 2>/dev/null || true
  docker compose -f "$REPO_ROOT/astro-docs/docker-compose.yml" build --no-cache
  docker compose -f "$REPO_ROOT/astro-docs/docker-compose.yml" up -d

  for i in $(seq 1 20); do
    CODE=$(curl -sf -o /dev/null -w "%{http_code}" "http://localhost:${PORT_ASTRO:-3003}/" 2>/dev/null || echo "000")
    if [ "$CODE" = "200" ]; then
      ok "Astro healthy on port ${PORT_ASTRO} (HTTP 200)"
      return
    fi
    sleep 2
  done
  warn "Astro not responding yet (may still be starting)"
}

# ── Phase 6: Install Skills + Agent Config ──────────────────────────────────
install_skills() {
  info "Installing OpenCode skills and agent config..."

  mkdir -p ~/.config/opencode/skills

  # Skills from repo
  cp -r "$REPO_ROOT/skills/directus-server" ~/.config/opencode/skills/ 2>/dev/null || true
  cp -r "$REPO_ROOT/skills/astro-starlight" ~/.config/opencode/skills/ 2>/dev/null || true
  ok "Skills installed (directus-server, astro-starlight)"

  # PA skill (optional)
  if [ -d "$REPO_ROOT/optional/06-pa-skill" ]; then
    cp -r "$REPO_ROOT/optional/06-pa-skill" ~/.config/opencode/skills/pa 2>/dev/null || true
    ok "PA skill installed"
  fi

  # AGENTS.md
  if [ -f "$REPO_ROOT/optional/01-agents-md/AGENTS.template.md" ]; then
    cp "$REPO_ROOT/optional/01-agents-md/AGENTS.template.md" ~/.config/opencode/AGENTS.md
    ok "AGENTS.md installed"
  fi

  # Context files
  mkdir -p ~/.config/opencode/context/{standards,workflows}
  cp "$REPO_ROOT/optional/02-context-files/standards/coding.md" ~/.config/opencode/context/standards/ 2>/dev/null || true
  cp "$REPO_ROOT/optional/02-context-files/workflows/workflows.md" ~/.config/opencode/context/workflows/ 2>/dev/null || true
  ok "Context files installed"

  # MCP config
  if [ -f "$REPO_ROOT/optional/04-mcp-config/mcp-template.json" ] && [ -f ~/.config/opencode/opencode.json ]; then
    python3 -c "
import json
with open('$HOME/.config/opencode/opencode.json') as f: cfg = json.load(f)
with open('$REPO_ROOT/optional/04-mcp-config/mcp-template.json') as f: mcp = json.load(f)
cfg.setdefault('mcp', {}).update(mcp['mcp'])
with open('$HOME/.config/opencode/opencode.json', 'w') as f: json.dump(cfg, f, indent=2)
print('merged')
" 2>/dev/null && ok "MCP config merged" || warn "MCP merge skipped (no opencode.json)"
  fi
}

# ── Phase 7: Firewall ───────────────────────────────────────────────────────
setup_firewall() {
  if command -v ufw &>/dev/null; then
    info "Configuring UFW firewall..."
    ufw allow 22/tcp 2>/dev/null || true
    ufw allow "${PORT_DIRECTUS:-8056}/tcp" 2>/dev/null || true
    ufw allow "${PORT_ASTRO:-3003}/tcp" 2>/dev/null || true
    yes | ufw enable 2>/dev/null || true
    ok "Firewall configured"
  fi
}

# ── Health Check ────────────────────────────────────────────────────────────
health_check() {
  load_env
  echo ""
  echo "════════════════════════════════════════════"
  echo "  PAULY — HEALTH CHECK"
  echo "════════════════════════════════════════════"
  echo ""

  # Directus
  DH=$(curl -sf "http://localhost:${PORT_DIRECTUS:-8056}/server/health" 2>/dev/null || echo "FAIL")
  echo -e "  Directus  (port ${PORT_DIRECTUS:-8056}): $DH"

  # Astro
  CODE=$(curl -sf -o /dev/null -w "%{http_code}" "http://localhost:${PORT_ASTRO:-3003}/" 2>/dev/null || echo "000")
  echo -e "  Astro     (port ${PORT_ASTRO:-3003}): HTTP $CODE"

  # Containers
  echo ""
  echo "  Containers:"
  docker ps --format "    {{.Names}}: {{.Status}}" 2>/dev/null | grep -E 'directus|astro|postgres|redis' || echo "    (none found)"

  echo ""
  echo "════════════════════════════════════════════"

  if echo "$DH" | grep -q "ok" && [ "$CODE" = "200" ]; then
    ok "All services healthy!"
    echo ""
    echo "  URLs:"
    echo "    Directus:  http://${SERVER_IP:-localhost}:${PORT_DIRECTUS:-8056}"
    echo "    Astro:     http://${SERVER_IP:-localhost}:${PORT_ASTRO:-3003}"
  else
    warn "Some services not ready — check logs"
  fi
}

# ── Main ─────────────────────────────────────────────────────────────────────
main() {
  echo ""
  echo "════════════════════════════════════════════"
  echo "  PAULY — Server Bootstrap"
  echo "  Mode: $MODE"
  echo "════════════════════════════════════════════"
  echo ""

  load_env

  case "$MODE" in
    check)
      health_check
      ;;
    directus)
      install_deps
      detect_ports
      start_directus
      setup_collection
      health_check
      ;;
    astro)
      install_deps
      detect_ports
      start_astro
      health_check
      ;;
    skills)
      install_skills
      ;;
    full)
      install_deps
      detect_ports
      start_directus
      setup_collection
      start_astro
      setup_firewall
      install_skills
      health_check
      ;;
  esac
}

main "$@"
