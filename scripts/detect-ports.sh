#!/bin/bash
###############################################################################
# detect-ports.sh — Finds free ports and writes them to .env
#
# Usage:
#   bash scripts/detect-ports.sh          # Auto-detect, update .env
#   bash scripts/detect-ports.sh --check  # Just report, don't modify
#
# Reads from .env (or .env.example if .env doesn't exist).
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$REPO_ROOT/.env"

if [ ! -f "$ENV_FILE" ]; then
  if [ -f "$REPO_ROOT/.env.example" ]; then
    cp "$REPO_ROOT/.env.example" "$ENV_FILE"
    echo "[detect-ports] Created .env from .env.example"
  else
    echo "[detect-ports] ERROR: No .env or .env.example found"
    exit 1
  fi
fi

CHECK_ONLY=false
if [ "${1:-}" = "--check" ]; then
  CHECK_ONLY=true
fi

# Default ports to check
declare -A PORT_VARS=(
  ["PORT_DIRECTUS"]="8056"
  ["PORT_ASTRO"]="3003"
  ["PORT_POSTGRES"]="5433"
  ["PORT_REDIS"]="6380"
)

# Read current values from .env
for var in "${!PORT_VARS[@]}"; do
  current=$(grep -E "^${var}=" "$ENV_FILE" 2>/dev/null | cut -d= -f2 || echo "")
  if [ -n "$current" ]; then
    PORT_VARS["$var"]="$current"
  fi
done

echo "+------+-------------------+--------+---------+"
echo "| Var  | Service           | Port   | Status  |"
echo "+------+-------------------+--------+---------+"

declare -A UPDATED

for var in "${!PORT_VARS[@]}"; do
  port="${PORT_VARS[$var]}"
  label=$(printf "%-17s" "$var")

  # Check if port is in use
  if command -v ss &>/dev/null; then
    in_use=$(ss -tlnH | awk '{print $4}' | grep -o ":${port}$" | head -1)
  elif command -v netstat &>/dev/null; then
    in_use=$(netstat -tlnH 2>/dev/null | awk '{print $4}' | grep -o ":${port}$" | head -1)
  else
    in_use=""
  fi

  # Also check if a docker container is listening
  docker_port=$(docker ps --format '{{.Ports}}' 2>/dev/null | grep -o "${port}->" | head -1 || true)

  if [ -n "$in_use" ] || [ -n "$docker_port" ]; then
    if [ "$CHECK_ONLY" = true ]; then
      printf "| %-4s | %-17s | %-6s | %-7s |\n" "$var" "$label" "$port" "BUSY"
      continue
    fi

    # Find a free port starting from current + 1
    new_port=$((port + 1))
    while true; do
      busy=""
      if command -v ss &>/dev/null; then
        busy=$(ss -tlnH | awk '{print $4}' | grep -o ":${new_port}$" | head -1)
      elif command -v netstat &>/dev/null; then
        busy=$(netstat -tlnH 2>/dev/null | awk '{print $4}' | grep -o ":${new_port}$" | head -1)
      fi
      docker_busy=$(docker ps --format '{{.Ports}}' 2>/dev/null | grep -o "${new_port}->" | head -1 || true)
      if [ -z "$busy" ] && [ -z "$docker_busy" ]; then
        break
      fi
      new_port=$((new_port + 1))
    done

    UPDATED["$var"]="$new_port"
    printf "| %-4s | %-17s | %-6s | %-7s |\n" "$var" "$label" "$new_port" "FIXED"
  else
    printf "| %-4s | %-17s | %-6s | %-7s |\n" "$var" "$label" "$port" "OK"
  fi
done

echo "+------+-------------------+--------+---------+"

# Write changes to .env
if [ "$CHECK_ONLY" = false ] && [ ${#UPDATED[@]} -gt 0 ]; then
  echo ""
  for var in "${!UPDATED[@]}"; do
    new_port="${UPDATED[$var]}"
    echo "[detect-ports] Updating $var: -> $new_port"
    if grep -q "^${var}=" "$ENV_FILE"; then
      sed -i "s|^${var}=.*|${var}=${new_port}|" "$ENV_FILE"
    else
      echo "${var}=${new_port}" >> "$ENV_FILE"
    fi
  done
  echo "[detect-ports] .env updated with $(echo ${!UPDATED[@]} | wc -w) port change(s)"
elif [ "$CHECK_ONLY" = true ]; then
  echo ""
  echo "[detect-ports] Check complete (--check mode, no changes made)"
else
  echo ""
  echo "[detect-ports] All ports are free. No changes needed."
fi

# Auto-detect SERVER_IP if still localhost
if [ "$CHECK_ONLY" = false ]; then
  current_ip=$(grep -E "^SERVER_IP=" "$ENV_FILE" | cut -d= -f2 || echo "")
  if [ "$current_ip" = "localhost" ] || [ -z "$current_ip" ]; then
    detected_ip=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "")
    if [ -n "$detected_ip" ] && [ "$detected_ip" != "127.0.0.1" ]; then
      sed -i "s|^SERVER_IP=.*|SERVER_IP=${detected_ip}|" "$ENV_FILE"
      echo "[detect-ports] SERVER_IP auto-detected: $detected_ip"
    fi
  fi
fi
