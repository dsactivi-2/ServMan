#!/usr/bin/env bash
set -euo pipefail

# Conservative auto-heal: restart unhealthy containers and critical services if inactive.

fix_service() {
  local svc="$1"
  if ! systemctl is-active --quiet "$svc"; then
    systemctl restart "$svc" || true
    echo "healed_service=$svc"
  fi
}

fix_service docker
fix_service tailscaled
fix_service ssh

# Restart unhealthy docker containers on mgmt
while IFS= read -r c; do
  [ -z "$c" ] && continue
  docker restart "$c" >/dev/null 2>&1 || true
  echo "healed_container=$c"
done < <(docker ps --format '{{.Names}} {{.Status}}' | awk '$0 !~ /healthy/ && $0 ~ /\(health:/' | awk '{print $1}')

# PVE nodes critical services
for host in 95.217.117.14 37.27.71.134; do
  ssh -o BatchMode=yes -i /root/.ssh/mgmt-automation_ed25519 "root@$host" 'for s in pveproxy pvedaemon pvestatd pve-cluster docker tailscaled ssh; do systemctl is-active --quiet "$s" || systemctl restart "$s" || true; done; echo healed_host=$(hostnamectl --static)'
done
