#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="/opt/management/shared/artifacts"
TS="$(date +%Y%m%d-%H%M%S)"
LOG="$LOG_DIR/autoheal-$TS.txt"
mkdir -p "$LOG_DIR"

FIXES=0

fix_service() {
  local svc="$1"
  if ! systemctl is-active --quiet "$svc"; then
    systemctl restart "$svc" || true
    echo "healed_local_service=$svc"
    FIXES=$((FIXES+1))
  fi
}

fix_remote_service() {
  local host="$1"
  local svc="$2"
  if ! ssh -o BatchMode=yes -i /root/.ssh/mgmt-automation_ed25519 "root@$host" "systemctl is-active --quiet $svc"; then
    ssh -o BatchMode=yes -i /root/.ssh/mgmt-automation_ed25519 "root@$host" "systemctl restart $svc || true"
    echo "healed_remote_service=$host:$svc"
    FIXES=$((FIXES+1))
  fi
}

{
  echo "=== autoheal $(date -Is) ==="
  fix_service docker
  fix_service tailscaled
  fix_service ssh

  while IFS= read -r c; do
    [ -z "$c" ] && continue
    docker restart "$c" >/dev/null 2>&1 || true
    echo "healed_container=$c"
    FIXES=$((FIXES+1))
  done < <(docker ps --format '{{.Names}} {{.Status}}' | awk '$0 !~ /healthy/ && $0 ~ /\(health:/' | awk '{print $1}')

  for host in 95.217.117.14 37.27.71.134; do
    fix_remote_service "$host" pveproxy
    fix_remote_service "$host" pvedaemon
    fix_remote_service "$host" pvestatd
    fix_remote_service "$host" pve-cluster
    fix_remote_service "$host" docker
    fix_remote_service "$host" tailscaled
    fix_remote_service "$host" ssh
  done

  if [ "$FIXES" -gt 0 ]; then
    SEVERITY="WARNING"
  else
    SEVERITY="OK"
  fi

  echo "summary severity=$SEVERITY fixes=$FIXES"
} | tee "$LOG"

WEBHOOK_URL="${AUTOHEAL_WEBHOOK_URL:-}"
if [ -n "$WEBHOOK_URL" ]; then
  PAYLOAD="{\"severity\":\"$SEVERITY\",\"fixes\":$FIXES,\"report\":\"$LOG\",\"host\":\"$(hostnamectl --static)\"}"
  curl -sS -X POST -H 'Content-Type: application/json' -d "$PAYLOAD" "$WEBHOOK_URL" >/dev/null || true
fi

echo "autoheal_report=$LOG"
