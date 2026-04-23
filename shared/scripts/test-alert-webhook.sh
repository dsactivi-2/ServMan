#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   test-alert-webhook.sh autoscan https://example/webhook
#   test-alert-webhook.sh autoheal https://example/webhook

if [ "$#" -lt 2 ]; then
  echo "usage: $0 <autoscan|autoheal> <webhook_url>"
  exit 1
fi

TYPE="$1"
URL="$2"
HOST="$(hostnamectl --static 2>/dev/null || hostname)"
NOW="$(date -Is)"

case "$TYPE" in
  autoscan)
    PAYLOAD="{\"severity\":\"WARNING\",\"fail\":1,\"warn\":1,\"report\":\"manual-test\",\"host\":\"$HOST\",\"time\":\"$NOW\"}"
    ;;
  autoheal)
    PAYLOAD="{\"severity\":\"WARNING\",\"fixes\":1,\"report\":\"manual-test\",\"host\":\"$HOST\",\"time\":\"$NOW\"}"
    ;;
  *)
    echo "invalid type: $TYPE"
    exit 1
    ;;
esac

curl -sS -X POST -H 'Content-Type: application/json' -d "$PAYLOAD" "$URL" >/dev/null
echo "webhook_test_sent type=$TYPE url=$URL"
