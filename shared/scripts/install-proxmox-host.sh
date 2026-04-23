#!/usr/bin/env bash
set -euo pipefail

# Install Proxmox VE 8 on Debian 12 host.
# WARNING: This changes kernel/bootloader and requires reboot.

if [ "${EUID}" -ne 0 ]; then
  echo "Run as root"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

. /etc/os-release
if [ "${ID}" != "debian" ] || [ "${VERSION_CODENAME}" != "bookworm" ]; then
  echo "Unsupported OS: ${PRETTY_NAME}. Expected Debian 12 (bookworm)."
  exit 1
fi

echo "[1/8] Preparing repositories"
cat > /etc/apt/sources.list.d/pve-install-repo.list <<'EOF'
deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription
EOF

curl -fsSL https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg \
  -o /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg

echo "[2/8] Updating apt metadata"
apt-get update

echo "[3/8] Installing Proxmox kernel and packages"
apt-get install -y proxmox-default-kernel
apt-get install -y proxmox-ve postfix open-iscsi chrony

echo "[4/8] Removing conflicting os-prober"
apt-get remove -y os-prober || true

echo "[5/8] Tuning ssh for long-running installs"
mkdir -p /etc/ssh/sshd_config.d
cat > /etc/ssh/sshd_config.d/98-proxmox-install.conf <<'EOF'
ClientAliveInterval 60
ClientAliveCountMax 120
EOF
systemctl reload ssh || true

echo "[6/8] Enabling required services"
systemctl enable --now pveproxy pvedaemon pvestatd pve-cluster

echo "[7/8] Version summary"
pveversion -v || true

echo "[8/8] Completed. Reboot required to run Proxmox kernel."
echo "Run: reboot"
