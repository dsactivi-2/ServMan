#!/usr/bin/env bash
set -euo pipefail

# Create a PostgreSQL container for app profile on target PVE Docker runtime.
# Usage: db-template-postgres.sh pve-01 openclawdb 5433 strongpass

if [ "$#" -lt 4 ]; then
  echo "usage: $0 <target_host> <db_name> <host_port> <db_password>"
  exit 1
fi

TARGET="$1"
DB_NAME="$2"
HOST_PORT="$3"
DB_PASS="$4"
INV="/opt/management/shared/inventory/hosts.yml"
SSH_KEY="/root/.ssh/mgmt-automation_ed25519"

CMD="docker rm -f ${DB_NAME} >/dev/null 2>&1 || true; docker run -d --name ${DB_NAME} --restart unless-stopped -e POSTGRES_DB=${DB_NAME} -e POSTGRES_USER=${DB_NAME} -e POSTGRES_PASSWORD=${DB_PASS} -p ${HOST_PORT}:5432 postgres:15-alpine"
ansible -i "$INV" "$TARGET" -m shell -a "$CMD" --private-key "$SSH_KEY"

echo "db_template_done target=$TARGET db=$DB_NAME port=$HOST_PORT"
