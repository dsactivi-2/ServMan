#!/usr/bin/env bash
set -euo pipefail

# Create VM from secure template on a Proxmox host.
# Usage:
#   create-vm-from-template.sh <vmid> <name> [template_id]
# Example:
#   create-vm-from-template.sh 110 app-web-01 9000

if [ "$#" -lt 2 ]; then
  echo "usage: $0 <vmid> <name> [template_id]"
  exit 1
fi

VMID="$1"
VMNAME="$2"
TEMPLATE_ID="${3:-9000}"

qm clone "$TEMPLATE_ID" "$VMID" --name "$VMNAME" --full 1 --storage local
qm set "$VMID" --memory 4096 --cores 2 --onboot 1
qm set "$VMID" --ipconfig0 ip=dhcp
qm start "$VMID"

echo "created_and_started vmid=$VMID name=$VMNAME template=$TEMPLATE_ID"
qm status "$VMID"
