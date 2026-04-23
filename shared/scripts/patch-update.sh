#!/usr/bin/env bash
set -euo pipefail

REBOOT_MODE="check"
if [[ "${1:-}" == "--reboot" ]]; then
  REBOOT_MODE="auto"
fi

OUT_DIR="/opt/management/agent/logs"
TS="$(date +%Y%m%d-%H%M%S)"
OUT_TXT="$OUT_DIR/patch-update-$TS.txt"

mkdir -p "$OUT_DIR"

{
  echo "=== Patch & Update ==="
  echo "Timestamp: $(date -Iseconds)"
  echo "Host: $(hostname)"
  echo

  echo "[apt update]"
  apt-get update
  echo

  echo "[apt upgrade]"
  DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
  echo

  echo "[autoclean]"
  apt-get autoremove -y
  apt-get autoclean -y
  echo

  echo "[Reboot Check]"
  if [[ -f /var/run/reboot-required ]]; then
    echo "reboot-required: yes"
    cat /var/run/reboot-required || true
    if [[ "$REBOOT_MODE" == "auto" ]]; then
      echo "Reboot mode enabled, rebooting now..."
      reboot
    fi
  else
    echo "reboot-required: no"
  fi
} | tee "$OUT_TXT"

echo "Saved: $OUT_TXT"
