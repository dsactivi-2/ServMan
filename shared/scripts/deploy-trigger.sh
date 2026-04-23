#!/usr/bin/env bash
set -euo pipefail

# Trigger: deploy profile -> VM create -> baseline -> optional app deploy command
# Usage:
#   deploy-trigger.sh openclaw pve-01 120 openclaw-01

if [ "$#" -lt 4 ]; then
  echo "usage: $0 <profile> <target_host> <vmid> <vm_name>"
  exit 1
fi

PROFILE="$1"
TARGET="$2"
VMID="$3"
VMNAME="$4"
SSH_KEY="/root/.ssh/mgmt-automation_ed25519"
INV="/opt/management/shared/inventory/hosts.yml"

if [ "$PROFILE" != "openclaw" ]; then
  echo "unsupported profile: $PROFILE"
  exit 1
fi

ansible -i "$INV" "$TARGET" -m shell -a "bash /root/build-proxmox-template.sh 9000 debian12-secure-template local vmbr0" --private-key "$SSH_KEY" >/dev/null 2>&1 || true
ansible -i "$INV" "$TARGET" -m shell -a "bash /root/create-vm-from-template.sh $VMID $VMNAME 9000" --private-key "$SSH_KEY"

echo "deploy_trigger_done profile=$PROFILE target=$TARGET vmid=$VMID name=$VMNAME"
