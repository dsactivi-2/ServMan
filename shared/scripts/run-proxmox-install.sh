#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./run-proxmox-install.sh root@95.217.117.14
#   ./run-proxmox-install.sh root@37.27.71.134

if [ "$#" -lt 1 ]; then
  echo "usage: $0 <ssh_target>"
  exit 1
fi

SSH_TARGET="$1"
SSH_KEY="/root/.ssh/mgmt-automation_ed25519"
LOCAL_SCRIPT="/opt/management/shared/scripts/install-proxmox-host.sh"
REMOTE_SCRIPT="/root/install-proxmox-host.sh"

scp -i "$SSH_KEY" -o BatchMode=yes -o StrictHostKeyChecking=accept-new "$LOCAL_SCRIPT" "$SSH_TARGET:$REMOTE_SCRIPT"
ssh -i "$SSH_KEY" -o BatchMode=yes -o StrictHostKeyChecking=accept-new "$SSH_TARGET" "chmod 700 $REMOTE_SCRIPT && bash $REMOTE_SCRIPT"

echo "Install script executed on $SSH_TARGET."
echo "If successful, reboot host and verify: pveversion -v"
