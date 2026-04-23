#!/usr/bin/env bash
set -euo pipefail

REPORT_DIR="/opt/management/shared/artifacts"
TS="$(date +%Y%m%d-%H%M%S)"
OUT="$REPORT_DIR/autoscan-$TS.txt"
SUMMARY="$REPORT_DIR/autoscan-latest-summary.txt"
mkdir -p "$REPORT_DIR"

FAIL=0
WARN=0
SEVERITY="OK"

check_local_service() {
  local svc="$1"
  if systemctl is-active --quiet "$svc"; then
    echo "OK service:$svc"
  else
    echo "FAIL service:$svc"
    FAIL=$((FAIL+1))
  fi
}

check_remote_service() {
  local host="$1"
  local svc="$2"
  if ssh -o BatchMode=yes -i /root/.ssh/mgmt-automation_ed25519 "root@$host" "systemctl is-active --quiet $svc"; then
    echo "OK $host service:$svc"
  else
    echo "FAIL $host service:$svc"
    FAIL=$((FAIL+1))
  fi
}

{
  echo "=== autoscan $(date -Is) ==="
  echo "-- mgmt services --"
  check_local_service docker
  check_local_service tailscaled
  check_local_service netdata
  check_local_service cron
  check_local_service ssh

  echo "-- mgmt ports/listeners --"
  ss -tulpen | grep -E ':22|:80|:443|:3000|:8000|:8080|:19999|:6001|:6002' || true

  echo "-- mgmt firewall --"
  iptables -S INPUT | sed -n '1,35p'

  echo "-- mgmt containers --"
  docker ps --format '{{.Names}} {{.Status}}'

  echo "-- pve-01 checks --"
  check_remote_service 95.217.117.14 pveproxy
  check_remote_service 95.217.117.14 pvedaemon
  check_remote_service 95.217.117.14 pvestatd
  check_remote_service 95.217.117.14 pve-cluster
  check_remote_service 95.217.117.14 docker
  check_remote_service 95.217.117.14 tailscaled
  ssh -o BatchMode=yes -i /root/.ssh/mgmt-automation_ed25519 root@95.217.117.14 'qm list; iptables -S INPUT | sed -n "1,20p"'

  echo "-- pve-02 checks --"
  check_remote_service 37.27.71.134 pveproxy
  check_remote_service 37.27.71.134 pvedaemon
  check_remote_service 37.27.71.134 pvestatd
  check_remote_service 37.27.71.134 pve-cluster
  check_remote_service 37.27.71.134 docker
  check_remote_service 37.27.71.134 tailscaled
  ssh -o BatchMode=yes -i /root/.ssh/mgmt-automation_ed25519 root@37.27.71.134 'qm list; iptables -S INPUT | sed -n "1,20p"'

  if [ "$FAIL" -gt 0 ]; then
    SEVERITY="CRITICAL"
  elif [ "$WARN" -gt 0 ]; then
    SEVERITY="WARNING"
  else
    SEVERITY="OK"
  fi

  echo "-- summary --"
  echo "severity=$SEVERITY fail=$FAIL warn=$WARN"
} | tee "$OUT"

echo "severity=$SEVERITY fail=$FAIL warn=$WARN report=$OUT" > "$SUMMARY"

WEBHOOK_URL="${AUTOSCAN_WEBHOOK_URL:-}"
if [ -n "$WEBHOOK_URL" ]; then
  PAYLOAD="{\"severity\":\"$SEVERITY\",\"fail\":$FAIL,\"warn\":$WARN,\"report\":\"$OUT\",\"host\":\"$(hostnamectl --static)\"}"
  curl -sS -X POST -H 'Content-Type: application/json' -d "$PAYLOAD" "$WEBHOOK_URL" >/dev/null || true
fi

echo "autoscan_report=$OUT"
