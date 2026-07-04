#!/bin/bash
# Pauly Triggers Installer
# Installs trigger context files and updates AGENTS.md
#
# Usage:
#   bash scripts/install.sh              # Install all triggers
#   bash scripts/install.sh --verify     # Check installation
#   bash scripts/install.sh --uninstall  # Remove all

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PHASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES_DIR="$PHASE_DIR/templates"
OPENCODE_CONFIG="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
CONTEXT_DIR="$OPENCODE_CONFIG/agents/context"

ACTION="${1:-install}"

# Core triggers to install
TRIGGERS=(
  "continue-instructions.md:co"
  "what-next-instructions.md:?"
  "update-instructions.md:u"
  "improve-instructions.md:improve"
  "brainstorm-instructions.md:bs"
  "session-recovery.md:session"
  "deferred-options.md:d"
  "flow-instructions.md:flow"
  "smooth-instructions.md:smooth"
  "guardian-instructions.md:g"
  "next-explorer-instructions.md:nx"
  "central-menu.md:menu"
  "visual-companion-instructions.md:vc"
  "cron-instructions.md:cron"
  "space-instructions.md:space"
  "svg-instructions.md:svg"
)

install() {
  echo "[triggers] Installing trigger context files..."
  
  mkdir -p "$CONTEXT_DIR"

  local installed=0
  for entry in "${TRIGGERS[@]}"; do
    local filename="${entry%%:*}"
    local trigger="${entry##*:}"
    local template="$TEMPLATES_DIR/$filename"

    if [ ! -f "$template" ]; then
      echo "  [WARN] Template not found: $template — skipping $trigger"
      continue
    fi

    # Use envsubst-style replacement if template vars exist
    sed "s|\$OPENCODE_CONFIG_DIR|$OPENCODE_CONFIG|g; s|\$HOME|$HOME|g" "$template" > "$CONTEXT_DIR/$filename"
    local file_size
    file_size=$(stat -c%s "$CONTEXT_DIR/$filename" 2>/dev/null || echo "0")
    echo "  ✓ $trigger → $filename (${file_size}B)"
    installed=$((installed + 1))
  done

  # Install trigger-words.md (master registry)
  if [ -f "$TEMPLATES_DIR/trigger-words.md" ]; then
    sed "s|\$OPENCODE_CONFIG_DIR|$OPENCODE_CONFIG|g; s|\$HOME|$HOME|g" \
      "$TEMPLATES_DIR/trigger-words.md" > "$CONTEXT_DIR/trigger-words.md"
    echo "  ✓ trigger-words.md — master trigger registry"
    installed=$((installed + 1))
  fi

  echo ""
  echo "[triggers] Installed $installed files to $CONTEXT_DIR"
  echo "[triggers] Add '## Word Triggers' section to AGENTS.md manually, or use the generated trigger-words.md"
}

verify() {
  echo "═══ TRIGGERS — INSTALLATION STATUS ═══"
  echo ""

  local total=0 present=0
  for entry in "${TRIGGERS[@]}"; do
    local filename="${entry%%:*}"
    local trigger="${entry##*:}"
    total=$((total + 1))
    if [ -f "$CONTEXT_DIR/$filename" ]; then
      local size
      size=$(stat -c%s "$CONTEXT_DIR/$filename" 2>/dev/null || echo "0")
      echo "  ✓ [$trigger] $filename (${size}B)"
      present=$((present + 1))
    else
      echo "  ✗ [$trigger] $filename — MISSING"
    fi
  done

  if [ -f "$CONTEXT_DIR/trigger-words.md" ]; then
    echo "  ✓ trigger-words.md"
    present=$((present + 1))
  else
    echo "  ✗ trigger-words.md — MISSING"
  fi
  total=$((total + 1))

  echo ""
  echo "  ${present}/${total} files present"
}

uninstall() {
  echo "[triggers] Removing trigger context files..."

  local removed=0
  for entry in "${TRIGGERS[@]}"; do
    local filename="${entry%%:*}"
    if [ -f "$CONTEXT_DIR/$filename" ]; then
      rm -f "$CONTEXT_DIR/$filename"
      echo "  ✗ removed $filename"
      removed=$((removed + 1))
    fi
  done

  if [ -f "$CONTEXT_DIR/trigger-words.md" ]; then
    rm -f "$CONTEXT_DIR/trigger-words.md"
    echo "  ✗ removed trigger-words.md"
    removed=$((removed + 1))
  fi

  echo "  Removed $removed files"
}

case "$ACTION" in
  install)     install ;;
  --verify)    verify ;;
  --uninstall) uninstall ;;
  *)
    echo "Usage: bash scripts/install.sh [install|--verify|--uninstall]"
    echo ""
    echo "  install       Install all triggers (default)"
    echo "  --verify      Check installation status"
    echo "  --uninstall   Remove all trigger files"
    ;;
esac
