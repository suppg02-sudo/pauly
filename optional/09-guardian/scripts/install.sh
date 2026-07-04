#!/bin/bash
# Pauly Guardian Installer
# Installs the guardian script + optional systemd service
#
# Usage:
#   bash scripts/install.sh              # Install script only
#   bash scripts/install.sh --service    # Install script + systemd service + timer
#   bash scripts/install.sh --verify     # Check installation status
#   bash scripts/install.sh --uninstall  # Remove all

set -euo pipefail

INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="pauly-guardian.sh"
SERVICE_NAME="pauly-guardian.service"
TIMER_NAME="pauly-guardian.timer"
LOG_DIR="/var/log/pauly-guardian"

SRC_SCRIPT="$(dirname "$0")/../../scripts/guardian.sh"
SRC_SERVICE="$(dirname "$0")/guardian.service"
SRC_TIMER="$(dirname "$0")/guardian.timer"

ACTION="${1:-install}"

install_script() {
  echo "[guardian] Installing $SCRIPT_NAME → $INSTALL_DIR/"

  if [ ! -f "$SRC_SCRIPT" ]; then
    echo "[guardian] ERROR: $SRC_SCRIPT not found"
    exit 1
  fi

  mkdir -p "$INSTALL_DIR"
  cp "$SRC_SCRIPT" "$INSTALL_DIR/$SCRIPT_NAME"
  chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

  # Create log directory
  mkdir -p "$LOG_DIR"

  echo "[guardian] Script installed: $INSTALL_DIR/$SCRIPT_NAME"
  echo "[guardian] Log directory: $LOG_DIR"
}

install_service() {
  echo "[guardian] Installing systemd service..."
  install_script

  if [ ! -f "$SRC_SERVICE" ] || [ ! -f "$SRC_TIMER" ]; then
    echo "[guardian] ERROR: systemd unit files not found"
    exit 1
  fi

  cp "$SRC_SERVICE" "/etc/systemd/system/$SERVICE_NAME"
  cp "$SRC_TIMER" "/etc/systemd/system/$TIMER_NAME"

  systemctl daemon-reload
  systemctl enable "$TIMER_NAME"
  systemctl start "$TIMER_NAME"

  echo "[guardian] Systemd timer installed and started: $TIMER_NAME"
  echo "[guardian] Runs every 15 minutes"
}

verify() {
  echo "═══ PAULY GUARDIAN — INSTALLATION STATUS ═══"
  echo ""

  if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
    echo "  Script:       $INSTALL_DIR/$SCRIPT_NAME ✓"
  else
    echo "  Script:       NOT INSTALLED"
  fi

  if systemctl is-active "$TIMER_NAME" &>/dev/null; then
    echo "  Timer:        $TIMER_NAME ✓ (active)"
    local next_run
    next_run=$(systemctl status "$TIMER_NAME" 2>/dev/null | grep "Trigger:" | head -1 || echo "")
    echo "  Next run:     ${next_run:-$(systemctl show "$TIMER_NAME" -p NextElapseUSecRealtime --value 2>/dev/null || echo "unknown")}"
  else
    local timer_status
    timer_status=$(systemctl is-active "$TIMER_NAME" 2>/dev/null || echo "not installed")
    echo "  Timer:        $timer_status"
  fi

  if systemctl is-enabled "$SERVICE_NAME" &>/dev/null; then
    echo "  Service:      $SERVICE_NAME ✓"
  else
    echo "  Service:      not enabled"
  fi

  if [ -d "$LOG_DIR" ]; then
    echo "  Log dir:      $LOG_DIR ✓"
    local log_count log_size
    log_count=$(ls -1 "$LOG_DIR" 2>/dev/null | wc -l)
    log_size=$(du -sh "$LOG_DIR" 2>/dev/null | awk '{print $1}')
    echo "  Log entries:  $log_count ($log_size)"
  else
    echo "  Log dir:      NOT FOUND"
  fi

  # Quick test
  if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
    echo ""
    echo "  Health check:"
    bash "$INSTALL_DIR/$SCRIPT_NAME" status 2>&1 | head -10
  fi
}

uninstall() {
  echo "[guardian] Uninstalling..."

  systemctl stop "$TIMER_NAME" 2>/dev/null || true
  systemctl disable "$TIMER_NAME" 2>/dev/null || true
  rm -f "/etc/systemd/system/$TIMER_NAME"
  rm -f "/etc/systemd/system/$SERVICE_NAME"
  systemctl daemon-reload

  rm -f "$INSTALL_DIR/$SCRIPT_NAME"

  echo "[guardian] Uninstalled $SCRIPT_NAME, $SERVICE_NAME, $TIMER_NAME"
  echo "[guardian] Note: $LOG_DIR retained (remove manually if desired)"
}

case "$ACTION" in
  install)     install_script ;;
  --service)   install_service ;;
  --verify)    verify ;;
  --uninstall) uninstall ;;
  *)
    echo "Usage: bash scripts/install.sh [install|--service|--verify|--uninstall]"
    echo ""
    echo "  install       Install script only"
    echo "  --service     Install script + systemd service + timer"
    echo "  --verify      Check installation status"
    echo "  --uninstall   Remove all"
    ;;
esac
