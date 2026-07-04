#!/bin/bash
# check-setup.sh — Probe system and output JSON status of every setup phase
#
# Usage:
#   bash scripts/check-setup.sh                    # Full JSON report
#   bash scripts/check-setup.sh --phases remaining  # Comma-separated list of pending phase IDs
#   bash scripts/check-setup.sh --phases done       # Comma-separated list of completed phase IDs

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$REPO_ROOT/.env"
OC="${HOME}/.config/opencode"

# Load .env values if available
load_env() {
  if [ -f "$ENV_FILE" ]; then
    set -a; source "$ENV_FILE"; set +a
  fi
}
load_env

json_escape() { printf '%s' "$1" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read().strip()))' 2>/dev/null || printf '""'; }

PHASES=""

check_phase() {
  local id="$1" label="$2"; shift 2
  local status="pending" detail=""
  if "$@" >/dev/null 2>&1; then status="done"; fi
  PHASES="${PHASES}${PHASES:+,}{\"id\":$(json_escape "$id"),\"label\":$(json_escape "$label"),\"status\":$(json_escape "$status")}"
}

# ── Phase Checks ─────────────────────────────────────────────────────────────

# 1. Dependencies
check_phase "deps" "Install system dependencies (Docker, Node.js)" \
  sh -c 'command -v docker && command -v node && docker ps >/dev/null 2>&1'

# 2. .env
check_phase "env" "Configure .env from template" \
  sh -c 'test -f "'"$ENV_FILE"'" && grep -q "^ADMIN_EMAIL=" "'"$ENV_FILE"'" && grep -q "^DB_PASSWORD=" "'"$ENV_FILE"'"'

# 3. Ports
check_phase "ports" "Detect free ports" \
  sh -c 'test -f "'"$ENV_FILE"'" && grep -q "^PORT_DIRECTUS=" "'"$ENV_FILE"'"'

# 4. Directus
check_phase "directus" "Start Directus container" \
  sh -c 'docker ps --format "{{.Names}}" 2>/dev/null | grep -q "directus"'

# 5. Directus health
check_phase "collection" "Create Directus pages collection" \
  sh -c 'docker ps --format "{{.Names}}" 2>/dev/null | grep -q "directus" && curl -sf "http://localhost:'"${PORT_DIRECTUS:-8056}"'/server/health" | grep -q "ok"'

# 6. Astro
check_phase "astro" "Start Astro Starlight container" \
  sh -c 'docker ps --format "{{.Names}}" 2>/dev/null | grep -q "astro"'

# 7. AGENTS.md
check_phase "agents-md" "Install AGENTS.md" \
  sh -c 'test -f "'"$OC"'/AGENTS.md"'

# 8. Context files
check_phase "context" "Install context files (standards + workflows)" \
  sh -c 'test -d "'"$OC"'/context/standards" && test -d "'"$OC"'/context/workflows"'

# 9. Triggers
check_phase "triggers" "Install trigger context files" \
  sh -c 'test -f "'"$OC"'/agents/context/trigger-words.md"'

# 10. MCP
check_phase "mcp" "Merge MCP server config" \
  sh -c 'test -f "'"$OC"'/opencode.json" && grep -q "mcp" "'"$OC"'/opencode.json"'

# 11. Skills
check_phase "skills" "Install OpenCode skills" \
  sh -c 'test -d "'"$OC"'/skills/directus-server" && test -d "'"$OC"'/skills/astro-starlight"'

# 12. PA Dashboard
check_phase "pa-dashboard" "Start PA Dashboard" \
  sh -c 'systemctl is-active pa-dashboard 2>/dev/null | grep -q "active"'

# 13. React-Admin
check_phase "react-admin" "Start React-Admin demo panel" \
  sh -c 'docker ps --format "{{.Names}}" 2>/dev/null | grep -q "react-admin"'

# 14. Guardian
check_phase "guardian" "Install Guardian monitoring" \
  sh -c 'command -v pauly-guardian.sh 2>/dev/null || test -f /etc/systemd/system/guardian.service || test -f "'"$OC"'/skills/guardian/setup.md"'

# 15. Skill Factory
check_phase "skill-factory" "Install Skill Factory" \
  sh -c 'test -d "'"$OC"'/skills/skill-factory"'

# 16. Firewall
check_phase "firewall" "Configure UFW firewall" \
  sh -c 'command -v ufw 2>/dev/null && ufw status 2>/dev/null | grep -qi "active"'

# ── Output ───────────────────────────────────────────────────────────────────

COUNT_DONE=$(echo "$PHASES" | python3 -c "import sys,json; phases=json.loads('[$PHASES]'); print(sum(1 for p in phases if p['status']=='done'))" 2>/dev/null || echo "0")
COUNT_TOTAL=$(echo "$PHASES" | python3 -c "import sys,json; print(len(json.loads('[$PHASES]')))" 2>/dev/null || echo "0")

FILTER="${1:-}"
MODE="${2:-full}"

case "$FILTER" in
  --phases)
    if [ "$MODE" = "remaining" ]; then
      echo "$PHASES" | python3 -c "
import sys,json
phases=json.loads('[$PHASES]')
remaining=[p['id'] for p in phases if p['status']!='done']
print(','.join(remaining))" 2>/dev/null
    elif [ "$MODE" = "done" ]; then
      echo "$PHASES" | python3 -c "
import sys,json
phases=json.loads('[$PHASES]')
done=[p['id'] for p in phases if p['status']=='done']
print(','.join(done))" 2>/dev/null
    fi
    ;;
  *)
    echo '{"phases":['"$PHASES"'],"summary":{"total":'"$COUNT_TOTAL"',"done":'"$COUNT_DONE"',"pending":'$((COUNT_TOTAL - COUNT_DONE))'}}'
    ;;
esac