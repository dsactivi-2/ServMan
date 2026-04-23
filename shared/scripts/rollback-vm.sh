#!/usr/bin/env bash
set -euo pipefail

# Rollback helper for VM based deploys
# Usage:
#   rollback-vm.sh pve-01 120

if [ "$#" -lt 2 ]; then
  echo "usage: $0 <target_host> <vmid>"
  exit 1
fi

TARGET="$1"
VMID="$2"
INV="/opt/management/shared/inventory/hosts.yml"
SSH_KEY="/root/.ssh/mgmt-automation_ed25519"

ansible -i "$INV" "$TARGET" -m shell -a "qm stop $VMID || true; qm destroy $VMID --purge 1 || true" --private-key "$SSH_KEY"
echo "rollback_done target=$TARGET vmid=$VMID"
