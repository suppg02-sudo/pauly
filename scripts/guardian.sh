#!/bin/bash
# Pauly Guardian — Generalised system + container watchdog
#
# A portable version of the host-level guardian-status.sh, adapted for
# the pauly project. Self-contained (no external libs).
#
# Usage:
#   bash scripts/guardian.sh [status|report|improvements]
#
# Config (loaded from .env if available):
#   CONTAINER_NAMES       Space-separated list of tracked containers
#   GUARDIAN_LOG_DIR      Directory for guardian/restart logs
#   GUARDIAN_RESTART_FILE  File tracking restart history
#   GUARDIAN_LOG_MAX_MB   Max log file size before warning (default 10)
#   GUARDIAN_DISPOSABLE   Names of disposable containers (default: directus, astro-docs, postgres, redis)
#
# Systemd services checked (when running on host):
#   earlyoom memory-watchdog psi-monitor opencode-guardian.timer wg-health-check.timer
#

set -euo pipefail

# ── Auto-detect repo root (same pattern as detect-ports.sh) ───────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ── Load config from .env if available ────────────────────────────────────────
if [ -f "$REPO_ROOT/.env" ]; then
  source "$REPO_ROOT/.env"
fi

GUARDIAN_LOG_DIR="${GUARDIAN_LOG_DIR:-/var/log/pauly-guardian}"
GUARDIAN_RESTART_FILE="${GUARDIAN_RESTART_FILE:-$GUARDIAN_LOG_DIR/restarts}"
GUARDIAN_LOG_MAX_MB="${GUARDIAN_LOG_MAX_MB:-10}"

# Default monitored containers — override via .env or env var
MONITORED_CONTAINERS="${CONTAINER_NAMES:-directus astro-docs postgres redis}"

# Astro container name — auto-detect if not set
ASTRO_CONTAINER="${ASTRO_CONTAINER:-}"
if [ -z "$ASTRO_CONTAINER" ]; then
  # Try common names in priority order
  for candidate in astro-blog astro-docs astro; do
    if docker inspect --format '{{.State.Status}}' "$candidate" &>/dev/null; then
      ASTRO_CONTAINER="$candidate"
      break
    fi
  done
  ASTRO_CONTAINER="${ASTRO_CONTAINER:-astro-docs}"
fi

MODE="${1:-status}"

# ── Helpers ───────────────────────────────────────────────────────────────────

has_command() { command -v "$1" &>/dev/null; }

get_container_status() {
  local name="$1"
  if docker inspect --format '{{.State.Status}}' "$name" 2>/dev/null; then
    return 0
  fi
  echo "absent"
}

get_available_mb() {
  awk '/MemAvailable/ {printf "%.0f", $2/1024}' /proc/meminfo 2>/dev/null || echo 0
}

get_swap_pct() {
  awk '/SwapTotal/{t=$2}/SwapFree/{f=$2}END{if(t>0)printf "%.0f",(1-f/t)*100;else print 0}' /proc/meminfo
}

get_psi_avg() {
  local res rcfile="$1" key="$2"
  res=$(grep "^$key" "$rcfile" 2>/dev/null | grep -oP 'avg10=\K[0-9.]+' || echo "0")
  echo "$res"
}

service_is_active() {
  systemctl is-active "$1" &>/dev/null && echo "active" || echo "inactive"
}

get_http_status() {
  local url="${1:-http://localhost:3002}"
  curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 "$url" 2>/dev/null || echo "000"
}

astro_blog_health() {
  local astro_name="${ASTRO_CONTAINER:-astro-docs}"
  local astro_port="${PORT_ASTRO:-3002}"
  local state restarts http_code
  state=$(docker inspect --format '{{.State.Status}}' "$astro_name" 2>/dev/null || echo "absent")
  restarts=$(docker inspect --format '{{.RestartCount}}' "$astro_name" 2>/dev/null || echo 0)
  http_code=$(get_http_status "http://localhost:${astro_port}")
  echo "$state|$restarts|$http_code"
}

# ── Status: System health snapshot ────────────────────────────────────────────
show_status() {
  echo "═══ PAULY GUARDIAN — STATUS ═══"
  echo "  Timestamp: $(date '+%Y-%m-%d %H:%M UTC')"
  echo ""

  # ── Host services (systemd) ──
  if has_command systemctl; then
    echo "── Host Services ──"
    local host_services=(
      earlyoom
      memory-watchdog
      psi-monitor
      opencode-guardian.timer
      wg-health-check.timer
    )
    for svc in "${host_services[@]}"; do
      printf "  %-30s %s\n" "$svc" "$(service_is_active "$svc")"
    done
    echo ""
  fi

  # ── Containers ──
  echo "── Containers ──"
  for c in $MONITORED_CONTAINERS; do
    printf "  %-30s %s\n" "$c" "$(get_container_status "$c")"
  done
  echo ""

  # ── Astro Blog Health ──
  echo "── Astro Blog ──"
  local astro_data astro_state astro_restarts astro_http
  astro_data=$(astro_blog_health)
  astro_state=$(echo "$astro_data" | cut -d'|' -f1)
  astro_restarts=$(echo "$astro_data" | cut -d'|' -f2)
  astro_http=$(echo "$astro_data" | cut -d'|' -f3)
  printf "  %-30s %s\n" "container" "$astro_state (restarts: $astro_restarts, HTTP: $astro_http)"
  if [ "$astro_state" = "running" ] && [ "$astro_http" = "200" ]; then
    echo "  health:                     ✓ healthy"
  elif [ "$astro_state" = "running" ]; then
    echo "  health:                     ⚠ container up but HTTP $astro_http"
  elif [ "$astro_state" = "absent" ]; then
    echo "  health:                     ✗ container not found"
  else
    echo "  health:                     ✗ $astro_state"
  fi
  echo ""

  # ── Resource usage ──
  echo "── Resource Usage ──"
  if docker stats --no-stream --format "  {{.Name}}: {{.CPUPerc}} / {{.MemUsage}}" 2>/dev/null | head -10; then
    :  # output captured
  else
    echo "  (no running containers)"
  fi
  echo ""

  # ── System memory ──
  echo "── System Memory ──"
  local avail_mb swap_pct
  avail_mb=$(get_available_mb)
  swap_pct=$(get_swap_pct)
  echo "  Available RAM:              ${avail_mb}MB"
  echo "  Swap used:                  ${swap_pct}%"
  echo ""

  # ── PSI pressure ──
  echo "── Pressure Stall (PSI) ──"
  local mem_some mem_full io_some io_full
  mem_some=$(get_psi_avg /proc/pressure/memory some)
  mem_full=$(get_psi_avg /proc/pressure/memory full)
  io_some=$(get_psi_avg /proc/pressure/io some)
  io_full=$(get_psi_avg /proc/pressure/io full)
  echo "  PSI mem: some=${mem_some}% full=${mem_full}%"
  echo "  PSI io:  some=${io_some}% full=${io_full}%"
  echo ""

  # ── Restart tracking ──
  echo "── Restarts ──"
  if [ -f "$GUARDIAN_RESTART_FILE" ]; then
    local now cutoff recent
    now=$(date +%s)
    cutoff=$((now - 900))
    recent=$(awk -v c="$cutoff" '$1>c{n++}END{print n+0}' "$GUARDIAN_RESTART_FILE" 2>/dev/null)
    local total
    total=$(wc -l < "$GUARDIAN_RESTART_FILE" 2>/dev/null || echo 0)
    echo "  Restarts (15min window):    ${recent:-0}"
    echo "  Restarts (total recorded):  $total"
  else
    echo "  (no restart data — run 'report' to initialise)"
  fi
  echo ""

  # ── Log sizes ──
  echo "── Log File Sizes ──"
  local log_files=(
    "$GUARDIAN_LOG_DIR/guardian.log"
  )
  for lf in "${log_files[@]}"; do
    if [ -f "$lf" ]; then
      local size_mb
      size_mb=$(( $(stat -c%s "$lf" 2>/dev/null || echo 0) / 1048576 ))
      if [ "$size_mb" -gt "$GUARDIAN_LOG_MAX_MB" ]; then
        echo "  $lf: ${size_mb}MB (⚠ exceeds ${GUARDIAN_LOG_MAX_MB}MB limit)"
      else
        echo "  $lf: ${size_mb}MB"
      fi
    fi
  done
}

# ── Report: Latest logs from all watchers ─────────────────────────────────────
show_report() {
  echo "═══ PAULY GUARDIAN — REPORT ═══"
  echo "  $(date '+%Y-%m-%d %H:%M UTC')"
  echo ""

  # Container logs
  for svc in $MONITORED_CONTAINERS; do
    echo "── $svc (last 20) ──"
    docker compose logs --tail 20 "$svc" 2>/dev/null || docker logs --tail 20 "$svc" 2>/dev/null || echo "  (no logs available)"
    echo ""
  done

  # Host logs (if available)
  if has_command journalctl; then
    echo "── earlyoom (last 5 journal) ──"
    journalctl -u earlyoom --no-pager -n 5 2>/dev/null || echo "  (no entries)"
    echo ""
  fi

  # Guardian log
  if [ -f "$GUARDIAN_LOG_DIR/guardian.log" ]; then
    echo "── guardian (last 10) ──"
    tail -10 "$GUARDIAN_LOG_DIR/guardian.log"
    echo ""
  fi

  # Record a heartbeat for restart tracking
  mkdir -p "$GUARDIAN_LOG_DIR"
  date +%s >> "$GUARDIAN_RESTART_FILE"
}

# ── Improvements: Diagnostic recommendations ─────────────────────────────────
show_improvements() {
  echo "═══ PAULY GUARDIAN — IMPROVEMENTS ═══"
  echo ""
  local issues=0

  # Memory
  local avail_mb
  avail_mb=$(get_available_mb)
  if [ "$avail_mb" -lt 500 ]; then
    echo "  [HIGH] Available RAM only ${avail_mb}MB — consider:"
    echo "         - Reduce container memory limits"
    echo "         - Add swap or increase RAM"
    echo "         - Review which containers actually need to run"
    issues=$((issues + 1))
  fi

  # Swap
  local swap_pct
  swap_pct=$(get_swap_pct)
  if [ "$swap_pct" -gt 50 ]; then
    echo "  [HIGH] Swap at ${swap_pct}% — system is swap-thrashing."
    echo "         This causes IO pressure and slow kills."
    issues=$((issues + 1))
  fi

  # PSI
  local mem_full
  mem_full=$(get_psi_avg /proc/pressure/memory full)
  if awk "BEGIN{exit !($mem_full > 10)}" 2>/dev/null; then
    echo "  [MED] Memory pressure (full) at ${mem_full}% — processes are stalling."
    echo "        Guardian should be actively killing containers."
    issues=$((issues + 1))
  fi

  # Restart loops
  if [ -f "$GUARDIAN_RESTART_FILE" ]; then
    local now cutoff recent
    now=$(date +%s)
    cutoff=$((now - 900))
    recent=$(awk -v c="$cutoff" '$1>c{n++}END{print n+0}' "$GUARDIAN_RESTART_FILE" 2>/dev/null)
    if [ "$recent" -ge 3 ]; then
      echo "  [HIGH] Restarts: ${recent}x in 15min — backoff active."
      echo "         Root cause likely memory exhaustion."
      issues=$((issues + 1))
    fi
  fi

  # Container crash loops
  for c in $MONITORED_CONTAINERS; do
    local rc
    rc=$(docker inspect --format '{{.RestartCount}}' "$c" 2>/dev/null || echo 0)
    if [ "$rc" -gt 50 ]; then
      echo "  [MED] Container $c has ${rc} restarts — crash loop."
      echo "        Check: docker logs $c --tail 30"
      issues=$((issues + 1))
    fi
  done

  # Astro blog health
  local astro_data astro_state astro_restarts astro_http
  astro_data=$(astro_blog_health)
  astro_state=$(echo "$astro_data" | cut -d'|' -f1)
  astro_restarts=$(echo "$astro_data" | cut -d'|' -f2)
  astro_http=$(echo "$astro_data" | cut -d'|' -f3)
  if [ "$astro_state" = "running" ] && [ "$astro_http" = "200" ] && [ "$astro_restarts" -eq 0 ]; then
    echo "  [OK] Astro blog is healthy (HTTP $astro_http, 0 restarts)"
  elif [ "$astro_state" = "running" ] && [ "$astro_http" != "200" ]; then
    echo "  [HIGH] Astro blog container up but HTTP $astro_http — likely config/dependency issue."
    echo "         Check: docker logs ${ASTRO_CONTAINER:-astro-docs} --tail 30"
    issues=$((issues + 1))
  elif [ "$astro_restarts" -gt 5 ]; then
    echo "  [HIGH] Astro blog crash-looping (${astro_restarts} restarts) — config or OOM."
    echo "         Check: docker logs ${ASTRO_CONTAINER:-astro-docs} --tail 50"
    issues=$((issues + 1))
  elif [ "$astro_state" = "absent" ]; then
    echo "  [HIGH] Astro blog container not found — needs recreation."
    issues=$((issues + 1))
  elif [ "$astro_state" != "running" ]; then
    echo "  [MED] Astro blog is $astro_state — needs restart."
    issues=$((issues + 1))
  fi

  # Log rotation
  for lf in "$GUARDIAN_LOG_DIR/guardian.log"; do
    if [ -f "$lf" ]; then
      local size_mb
      size_mb=$(( $(stat -c%s "$lf" 2>/dev/null || echo 0) / 1048576 ))
      if [ "$size_mb" -gt "$GUARDIAN_LOG_MAX_MB" ]; then
        echo "  [LOW] $lf is ${size_mb}MB — needs log rotation."
        issues=$((issues + 1))
      fi
    fi
  done

  # Disposables check
  local disposable_up=0
  for c in $MONITORED_CONTAINERS; do
    docker inspect --format '{{.State.Status}}' "$c" 2>/dev/null | grep -q "running" && disposable_up=$((disposable_up + 1))
  done
  if [ "$disposable_up" -eq 0 ]; then
    echo "  [WARN] No monitored containers running — guardian has nothing to kill."
    echo "         System will go straight to earlyoom/kernel OOM."
    issues=$((issues + 1))
  fi

  if [ "$issues" -eq 0 ]; then
    echo "  ✓ No issues detected. System looks healthy."
  else
    echo ""
    echo "  ${issues} issue(s) found. Run 'guardian.sh status' for full view."
  fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
case "$MODE" in
  status)       show_status ;;
  report)       show_report ;;
  improvements) show_improvements ;;
  -h|--help)
    echo "Usage: bash scripts/guardian.sh [status|report|improvements]"
    echo ""
    echo "  status         System health snapshot (default)"
    echo "  report         Latest logs from all watchers"
    echo "  improvements   Diagnostic recommendations"
    ;;
  *)
    echo "Unknown mode: $MODE"
    echo "Usage: bash scripts/guardian.sh [status|report|improvements]"
    exit 1
    ;;
esac
