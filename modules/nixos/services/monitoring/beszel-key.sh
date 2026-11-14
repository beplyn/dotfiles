#!/usr/bin/env bash
# beszel-key.sh HUB_KEY OUT: the agent's KEY is the hub's public key; the hub makes its key
# pair on first start, so wait for it, then write the public half to OUT for the agent
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
