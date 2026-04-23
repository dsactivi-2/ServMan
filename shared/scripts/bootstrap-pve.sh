#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./bootstrap-pve.sh root@95.217.117.14 pve-01 10.10.0.11
#   ./bootstrap-pve.sh root@37.27.71.134 pve-02 10.10.0.12

if [ "$#" -lt 3 ]; then
  echo "usage: $0 <ssh_target> <hostname> <private_ip>"
  exit 1
fi

SSH_TARGET="$1"
NEW_HOSTNAME="$2"
PRIVATE_IP="$3"
SSH_KEY="/root/.ssh/mgmt-automation_ed25519"

ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -i "$SSH_KEY" "$SSH_TARGET" NEW_HOSTNAME_PLACEHOLDER="$NEW_HOSTNAME" PRIVATE_IP_PLACEHOLDER="$PRIVATE_IP" 'bash -s' <<'REMOTE'
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

hostnamectl set-hostname "$NEW_HOSTNAME_PLACEHOLDER"

apt-get update
apt-get install -y curl ca-certificates gnupg lsb-release qemu-guest-agent htop net-tools jq fail2ban unattended-upgrades apt-transport-https software-properties-common
systemctl enable --now fail2ban unattended-upgrades
systemctl enable qemu-guest-agent || true
systemctl start qemu-guest-agent || true

if ! command -v tailscale >/dev/null 2>&1; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi
systemctl enable tailscaled

mkdir -p /opt/management/node
cat > /opt/management/node/node-meta.txt <<EOF
hostname=$NEW_HOSTNAME_PLACEHOLDER
private_ip=$PRIVATE_IP_PLACEHOLDER
bootstrap_time=$(date -Is)
os=$( . /etc/os-release; echo $PRETTY_NAME )
EOF

if grep -q '^PasswordAuthentication' /etc/ssh/sshd_config; then
  sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
else
  echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config
fi

if grep -q '^PermitRootLogin' /etc/ssh/sshd_config; then
  sed -i 's/^PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
else
  echo 'PermitRootLogin prohibit-password' >> /etc/ssh/sshd_config
fi

systemctl restart ssh || systemctl restart sshd

echo "bootstrap_done hostname=$NEW_HOSTNAME_PLACEHOLDER private_ip=$PRIVATE_IP_PLACEHOLDER"
REMOTE
