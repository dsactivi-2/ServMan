#!/usr/bin/env bash
set -euo pipefail

REPORT_DIR="/opt/management/shared/artifacts"
TS="$(date +%Y%m%d-%H%M%S)"
REPORT_FILE="$REPORT_DIR/healthcheck-mgmt-$TS.txt"
mkdir -p "$REPORT_DIR"

{
  echo "=== mgmt-01 healthcheck $(date -Is) ==="
  echo "hostname: $(hostnamectl --static)"
  . /etc/os-release
  echo "os: $PRETTY_NAME"
  echo

  echo "-- services --"
  systemctl is-active docker tailscaled cron || true
  systemctl is-active netdata || true
  echo

  echo "-- docker containers --"
  docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
  echo

  echo "-- listening ports (key set) --"
  ss -tulpen | grep -E ':22|:80|:443|:3000|:8000|:8080|:19999|:6001|:6002' || true
  echo

  echo "-- tailscale status (first 20 lines) --"
  tailscale status 2>/dev/null || true
  echo

  echo "-- context7 verify script --"
  if [ -x /usr/local/bin/context7-verify.sh ]; then
    /usr/local/bin/context7-verify.sh || true
    echo "context7_verify: executed"
  else
    echo "context7_verify: missing"
  fi
} | tee "$REPORT_FILE"

echo "healthcheck report: $REPORT_FILE"
