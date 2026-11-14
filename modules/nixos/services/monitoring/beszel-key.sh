#!/usr/bin/env bash
# beszel-key.sh HUB_KEY OUT: wait for the hub's key pair, write its public key to OUT
set -euo pipefail
key="$1"
out="$2"

for _ in $(seq 60); do
  [ -s "$key" ] && break
  sleep 2
done
[ -s "$key" ] || { echo "no hub key at $key" >&2; exit 1; }

ssh-keygen -y -f "$key" > "$out.tmp"
chmod 0644 "$out.tmp"
mv "$out.tmp" "$out"
