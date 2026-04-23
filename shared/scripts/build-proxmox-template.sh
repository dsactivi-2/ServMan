#!/usr/bin/env bash
set -euo pipefail

VMID="${1:-9000}"
VMNAME="${2:-debian12-secure-template}"
STORAGE="${3:-local}"
BRIDGE="${4:-vmbr0}"
IMG_URL="https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
IMG_DIR="/var/lib/vz/template/iso"
IMG_PATH="$IMG_DIR/debian-12-generic-amd64.qcow2"

mkdir -p "$IMG_DIR"

if [ ! -f "$IMG_PATH" ]; then
  wget -qO "$IMG_PATH" "$IMG_URL"
fi

qm destroy "$VMID" --purge 1 >/dev/null 2>&1 || true

qm create "$VMID" \
  --name "$VMNAME" \
  --memory 4096 \
  --cores 2 \
  --cpu x86-64-v2-AES \
  --net0 "virtio,bridge=${BRIDGE}" \
  --agent enabled=1 \
  --ostype l26 \
  --serial0 socket \
  --vga serial0

qm importdisk "$VMID" "$IMG_PATH" "$STORAGE" >/tmp/qm-import-${VMID}.log

DISK_FILE="$(ls /var/lib/vz/images/${VMID}/vm-${VMID}-disk-* | head -n1)"
DISK_REF="${STORAGE}:${DISK_FILE#/var/lib/vz/images/}"

qm set "$VMID" --scsihw virtio-scsi-single --scsi0 "$DISK_REF"
qm set "$VMID" --boot c --bootdisk scsi0
qm set "$VMID" --ide2 "${STORAGE}:cloudinit"
qm set "$VMID" --ipconfig0 ip=dhcp
qm set "$VMID" --ciuser devops
qm set "$VMID" --sshkeys /root/.ssh/authorized_keys
qm set "$VMID" --nameserver 1.1.1.1
qm set "$VMID" --searchdomain local
qm set "$VMID" --tags "debian12,secure,cloudinit,base"

qm template "$VMID"
qm config "$VMID"
