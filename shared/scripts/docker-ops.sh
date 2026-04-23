#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-status}"
STACK_DIR="${2:-/opt/management/semaphore}"
ENV_FILE="$STACK_DIR/.env"
COMPOSE_FILE="$STACK_DIR/docker-compose.yml"

if [[ ! -f "$COMPOSE_FILE" ]]; then
  echo "Compose file not found: $COMPOSE_FILE" >&2
  exit 1
fi

CMD=(docker compose -f "$COMPOSE_FILE")
if [[ -f "$ENV_FILE" ]]; then
  CMD+=(--env-file "$ENV_FILE")
fi

case "$ACTION" in
  status)
    "${CMD[@]}" ps
    ;;
  pull)
    "${CMD[@]}" pull
    ;;
  restart)
    "${CMD[@]}" restart
    ;;
  deploy)
    "${CMD[@]}" pull
    "${CMD[@]}" up -d
    ;;
  logs)
    "${CMD[@]}" logs --tail=200
    ;;
  health)
    "${CMD[@]}" ps
    curl -s --max-time 5 http://10.10.0.2:3000/api/ping || true
    ;;
  *)
    echo "Usage: $0 {status|pull|restart|deploy|logs|health} [stack_dir]" >&2
    exit 1
    ;;
esac
