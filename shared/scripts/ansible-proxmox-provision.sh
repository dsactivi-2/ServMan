#!/usr/bin/env bash
set -euo pipefail

# Wrapper for Proxmox VM provisioning playbook.
# Usage:
#   ansible-proxmox-provision.sh pve-01 130 app-openclaw-01

if [ "$#" -lt 3 ]; then
  echo "usage: $0 <target_host> <vmid> <vm_name>"
  exit 1
fi

TARGET="$1"
VMID="$2"
VMNAME="$3"

ANSIBLE_CONFIG="/opt/management/shared/ansible.cfg" \
BRIDGE="vmbr0"

ansible-playbook -i /opt/management/shared/inventory/hosts.yml \
  /opt/management/shared/playbook-proxmox-provision-vm.yml \
  --limit "$TARGET" \
  --extra-vars "target_vmid=$VMID target_vm_name=$VMNAME target_template_id=9000 target_vm_memory=4096 target_vm_cores=2 target_vm_storage=local target_vm_bridge=$BRIDGE"
