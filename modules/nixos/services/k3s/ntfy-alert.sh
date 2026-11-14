#!/usr/bin/env bash
# ntfy-alert.sh UNIT PORT TOPIC: push UNIT's last log lines to the cluster's ntfy, run from
# OnFailure=; the token is the publish-only one apps.nix provisions
set -euo pipefail
unit="$1"
port="$2"
topic="$3"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# the token goes through a header file, never argv
token="$(k3s kubectl -n ntfy get secret ntfy -o 'jsonpath={.data.ALERT_TOKEN}' | base64 -d)"
printf 'Authorization: Bearer %s\n' "$token" > "$tmp/headers"

journalctl -u "$unit" -n 20 --no-pager -o cat \
  | curl -fsS --retry 3 \
    -H @"$tmp/headers" \
    -H "Title: $(hostname): $unit failed" \
    -H "Priority: high" \
    -H "Tags: rotating_light" \
    --data-binary @- \
    "http://127.0.0.1:$port/$topic" >/dev/null
