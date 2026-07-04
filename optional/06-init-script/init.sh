#!/bin/bash
###############################################################################
# init.sh — Full server bootstrap for Pauly (Directus + Astro Starlight)
#
# Usage:
#   bash optional/06-init-script/init.sh              # Full setup
#   bash optional/06-init-script/init.sh --directus   # Directus only
#   bash optional/06-init-script/init.sh --astro      # Astro only
#   bash optional/06-init-script/init.sh --skills     # Skills + agent config only
#   bash optional/06-init-script/init.sh --check      # Health check only
#
# This script:
#   1. Installs Docker, Node.js, dependencies
#   2. Detects free ports and fills .env
#   3. Starts Directus + Astro
#   4. Creates the Directus 'pages' collection
#   5. Installs OpenCode skills + agent config + triggers
#   6. Verifies everything is healthy
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="$REPO_ROOT/.env"
PROGRESS_FILE="$REPO_ROOT/progress.md"

# ── Progress Log ─────────────────────────────────────────────────────────────
init_progress() {
  if [ ! -f "$PROGRESS_FILE" ]; then
    cat > "$PROGRESS_FILE" << 'EOF'
# Setup Progress Log

Historical record of setup phases, bugs, fixes, diversions, improvements, and errors.

| Timestamp | Phase | Type | Message |
|-----------|-------|------|---------|
EOF
    info "Created $PROGRESS_FILE"
  fi
}

log_progress() {
  local phase="$1" type="$2"; shift 2
  local msg="$*"
  local ts; ts=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
  init_progress
  echo "| $ts | $phase | $type | $msg |" >> "$PROGRESS_FILE"
}

log_bug()      { log_progress "$1" "BUG"      "${@:2}"; }
log_fix()      { log_progress "$1" "FIX"      "${@:2}"; }
log_diversion() { log_progress "$1" "DIVERSION" "${@:2}"; }
log_improvement() { log_progress "$1" "IMPROVEMENT" "${@:2}"; }
log_error()    { log_progress "$1" "ERROR"    "${@:2}"; }
log_info()     { log_progress "$1" "INFO"     "${@:2}"; }

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
    --smart)     MODE="smart" ;;
  esac
done

# ── Smart Mode (auto-detect and run only pending phases) ─────────────────────
smart_phases() {
  local remaining
  remaining=$(bash "$REPO_ROOT/scripts/check-setup.sh" --phases remaining)
  info "Remaining phases: ${remaining:-none}"
  [ -z "$remaining" ] && { ok "All phases complete."; exit 0; }

  while IFS=',' read -ra PHASES; do
    for pid in "${PHASES[@]}"; do
      case "$pid" in
        env)         cp "$REPO_ROOT/.env.example" "$ENV_FILE" 2>/dev/null || true
                     local sec; sec=$(openssl rand -hex 24)
                     local tok; tok=$(openssl rand -hex 16)
                     sed -i "s|^DIRECTUS_SECRET=.*|DIRECTUS_SECRET=${sec}|;s|^DIRECTUS_TOKEN=.*|DIRECTUS_TOKEN=${tok}|" "$ENV_FILE"
                     load_env; ok ".env configured" ;;
        ports)       bash "$REPO_ROOT/scripts/detect-ports.sh" ;;
        directus)    start_directus ;;
        collection)  setup_collection ;;
        astro)       start_astro ;;
        context)     mkdir -p "$HOME/.config/opencode/context/standards" "$HOME/.config/opencode/context/workflows"
                     cp "$REPO_ROOT/optional/02-context-files/standards/coding.md" "$HOME/.config/opencode/context/standards/" 2>/dev/null || true
                     cp "$REPO_ROOT/optional/02-context-files/workflows/workflows.md" "$HOME/.config/opencode/context/workflows/" 2>/dev/null || true
                     ok "Context files installed" ;;
        skills)      install_skills ;;
        react-admin) start_react_admin ;;
        guardian)    bash "$REPO_ROOT/optional/10-guardian/scripts/install.sh" 2>/dev/null && ok "Guardian installed" || warn "Guardian skipped" ;;
        firewall)    setup_firewall ;;
        *)           warn "Unknown phase: $pid" ;;
      esac
    done
  done <<< "$remaining"
}

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
  log_info deps "Phase started"

  if ! command -v docker &>/dev/null; then
    info "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    usermod -aG docker "$USER" 2>/dev/null || true
    ok "Docker installed"
    log_info deps "Docker installed"
  else
    ok "Docker already installed"
    log_info deps "Docker already present"
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
  log_info deps "Phase complete"
}

# ── Phase 2: Detect Ports ───────────────────────────────────────────────────
detect_ports() {
  info "Detecting free ports..."
  log_info ports "Phase started"
  bash "$REPO_ROOT/scripts/detect-ports.sh"
  load_env

  # Auto-detect SERVER_IP if localhost
  if [ "${SERVER_IP:-}" = "localhost" ] || [ -z "${SERVER_IP:-}" ]; then
    DETECTED_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "")
    if [ -n "$DETECTED_IP" ] && [ "$DETECTED_IP" != "127.0.0.1" ]; then
      sed -i "s|^SERVER_IP=.*|SERVER_IP=${DETECTED_IP}|" "$ENV_FILE"
      load_env
      ok "SERVER_IP detected: $SERVER_IP"
      log_info ports "SERVER_IP detected: $SERVER_IP"
    fi
  fi
  log_info ports "Phase complete"
}

# ── Phase 3: Start Directus ─────────────────────────────────────────────────
start_directus() {
  info "Starting Directus..."
  log_info directus "Phase started"
  cp "$ENV_FILE" "$REPO_ROOT/directus/.env"
  docker compose -f "$REPO_ROOT/directus/docker-compose.yml" up -d

  info "Waiting for Directus to bootstrap..."
  for i in $(seq 1 30); do
    if curl -sf "http://localhost:${PORT_DIRECTUS:-8056}/server/health" | grep -q "ok"; then
      ok "Directus healthy on port ${PORT_DIRECTUS}"
      log_info directus "Healthy on port ${PORT_DIRECTUS}"
      break
    fi
    sleep 2
    [ $i -eq 30 ] && { log_error directus "Failed to start"; fail "Directus failed to start"; }
  done
}

# ── Phase 4: Create Directus Collection ─────────────────────────────────────
setup_collection() {
  info "Setting up Directus collections and token..."
  log_info collection "Phase started"

  # Login as admin
  ADMIN_TOKEN=$(curl -sf -X POST "http://localhost:${PORT_DIRECTUS}/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"${ADMIN_EMAIL}\",\"password\":\"${ADMIN_PASSWORD}\"}" \
    | jq -r '.data.access_token') || { log_error collection "Admin login failed"; fail "Admin login failed"; }

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
  log_info astro "Phase started"
  cp "$ENV_FILE" "$REPO_ROOT/astro-docs/.env"
  docker network create "${DOCKER_NETWORK}" 2>/dev/null || true
  docker compose -f "$REPO_ROOT/astro-docs/docker-compose.yml" build --no-cache
  docker compose -f "$REPO_ROOT/astro-docs/docker-compose.yml" up -d

  for i in $(seq 1 20); do
    CODE=$(curl -sf -o /dev/null -w "%{http_code}" "http://localhost:${PORT_ASTRO:-3003}/" 2>/dev/null || echo "000")
    if [ "$CODE" = "200" ]; then
      ok "Astro healthy on port ${PORT_ASTRO} (HTTP 200)"
      log_info astro "Healthy on port ${PORT_ASTRO} (HTTP 200)"
      return
    fi
    sleep 2
  done
  warn "Astro not responding yet (may still be starting)"
  log_diversion astro "Not responding after 40s — may still be starting"
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
  if [ -d "$REPO_ROOT/optional/07-pa-skill" ]; then
    cp -r "$REPO_ROOT/optional/07-pa-skill" ~/.config/opencode/skills/pa 2>/dev/null || true
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

  # Triggers (optional phase 03)
  if [ -d "$REPO_ROOT/optional/03-triggers" ]; then
    bash "$REPO_ROOT/optional/03-triggers/scripts/install.sh" 2>/dev/null || true
    ok "Trigger context files installed (${REPO_ROOT}/optional/03-triggers)"
  fi

  # MCP config
  if [ -f "$REPO_ROOT/optional/05-mcp-config/mcp-template.json" ] && [ -f ~/.config/opencode/opencode.json ]; then
    python3 -c "
import json
with open('$HOME/.config/opencode/opencode.json') as f: cfg = json.load(f)
with open('$REPO_ROOT/optional/05-mcp-config/mcp-template.json') as f: mcp = json.load(f)
cfg.setdefault('mcp', {}).update(mcp['mcp'])
with open('$HOME/.config/opencode/opencode.json', 'w') as f: json.dump(cfg, f, indent=2)
print('merged')
" 2>/dev/null && ok "MCP config merged" || warn "MCP merge skipped (no opencode.json)"
  fi
  log_info skills "Phase complete"
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
    log_info firewall "UFW configured for ports ${PORT_DIRECTUS}, ${PORT_ASTRO}"
  else
    log_diversion firewall "ufw not installed — skipped"
  fi
}

# ── Phase 7: Start PA Dashboard ──────────────────────────────────────────────
start_pa_dashboard() {
  if [ ! -d "$REPO_ROOT/optional/07-pa-skill" ]; then return; fi
  info "Starting PA Dashboard..."

  # Deploy HTML with env values
  bash "$REPO_ROOT/optional/07-pa-skill/scripts/deploy.sh" 2>/dev/null || true

  # Create systemd service
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
  systemctl enable --now pa-dashboard 2>/dev/null || true
  ok "PA Dashboard started on port ${PORT_PA:-8901}"
}

# ── Phase 8: Start React-Admin ───────────────────────────────────────────────
start_react_admin() {
  if [ ! -d "$REPO_ROOT/optional/08-react-admin" ]; then return; fi
  info "Starting React-Admin demo..."
  docker compose -f "$REPO_ROOT/optional/08-react-admin/docker-compose.yml" up -d --build 2>/dev/null || true
  ok "React-Admin started on port ${PORT_REACT_ADMIN:-5200}"
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

  init_progress
  log_info setup "Bootstrap started (mode: $MODE)"
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
      start_pa_dashboard
      start_react_admin
      setup_firewall
      install_skills
      health_check
      ;;
    smart)
      load_env
      smart_phases
      health_check
      ;;
  esac
}

main "$@"
