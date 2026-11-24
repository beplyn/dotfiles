#!/usr/bin/env bash
# arRPC's Discord database lists CS2 only as its Windows binary; add the native one
set -euo pipefail
db="${1:?usage: patch-detectables.sh <arrpc-detectable-db.json>}"
[ -f "$db" ] || exit 0
cs2='1158877933042143272'
if jq -e --arg id "$cs2" 'any(.[]; .id == $id and any(.executables[]; .name == "cs2" and .os == "linux"))' "$db" >/dev/null; then
  exit 0
fi
tmp="$(mktemp "$db.XXXXXX")"
jq -c --arg id "$cs2" '(.[] | select(.id == $id) | .executables) += [{"is_launcher": false, "name": "cs2", "os": "linux"}]' "$db" > "$tmp"
chmod --reference="$db" "$tmp"
mv "$tmp" "$db"
