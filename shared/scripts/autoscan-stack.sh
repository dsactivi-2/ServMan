#!/usr/bin/env bash
set -euo pipefail

REPORT_DIR="/opt/management/shared/artifacts"
TS="$(date +%Y%m%d-%H%M%S)"
OUT="$REPORT_DIR/autoscan-$TS.txt"
mkdir -p "$REPORT_DIR"

{
  echo "=== autoscan $(date -Is) ==="
  echo "-- mgmt --"
  systemctl is-active docker tailscaled netdata cron ssh
  ss -tulpen | grep -E ':22|:80|:443|:3000|:8000|:8080|:19999|:6001|:6002' || true
  iptables -S INPUT
  docker ps --format '{{.Names}} {{.Status}}'
  echo

  echo "-- pve-01 --"
  ssh -o BatchMode=yes -i /root/.ssh/mgmt-automation_ed25519 root@95.217.117.14 'systemctl is-active pveproxy pvedaemon pvestatd pve-cluster docker tailscaled ssh; iptables -S INPUT; qm list'
  echo

  echo "-- pve-02 --"
  ssh -o BatchMode=yes -i /root/.ssh/mgmt-automation_ed25519 root@37.27.71.134 'systemctl is-active pveproxy pvedaemon pvestatd pve-cluster docker tailscaled ssh; iptables -S INPUT; qm list'
} | tee "$OUT"

echo "autoscan_report=$OUT"
