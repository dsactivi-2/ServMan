#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="/opt/management/agent/logs"
TS="$(date +%Y%m%d-%H%M%S)"
OUT_TXT="$OUT_DIR/system-health-$TS.txt"

mkdir -p "$OUT_DIR"

{
  echo "=== System Health Snapshot ==="
  echo "Timestamp: $(date -Iseconds)"
  echo "Host: $(hostname)"
  echo

  echo "[Uptime / Load]"
  uptime
  echo

  echo "[CPU]"
  nproc
  echo

  echo "[Memory]"
  free -h
  echo

  echo "[Disk]"
  df -h
  echo

  echo "[Top Processes by CPU]"
  ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 15
  echo

  echo "[Top Processes by Memory]"
  ps -eo pid,comm,%cpu,%mem --sort=-%mem | head -n 15
  echo

  echo "[Open Listening Ports]"
  ss -tulpen
  echo

  echo "[Docker Containers]"
  if command -v docker >/dev/null 2>&1; then
    docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
  else
    echo "docker not installed"
  fi
} | tee "$OUT_TXT"

echo "Saved: $OUT_TXT"
