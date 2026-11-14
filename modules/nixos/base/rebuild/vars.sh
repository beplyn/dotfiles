#!/usr/bin/env bash
# vars.sh TEMPLATE DIR: asks for every value in TEMPLATE (the repo's vars/vars.toml) that
# DIR/vars.toml doesn't have yet, and writes it there, root-only. Runs as the user, sudo for
# the file. lan.* may be left empty: only hosts with a static LAN address use them
set -euo pipefail
template="$1"
dir="$2"
file="$dir/vars.toml"

current=""
if sudo test -f "$file"; then
  current="$(sudo cat "$file")"
fi
updated="$current"

# each leaf as its dotted name and the placeholder, shown as an example
while IFS=$'\t' read -r name example; do
  # the template's own marker, never a real value
  [ "$name" != placeholder ] || continue
  # set already; an empty one was skipped on purpose
  if yq -p toml -e ".${name} != null" <<< "$current" > /dev/null 2>&1; then
    continue
  fi
  optional=false
  [[ "$name" == lan.* ]] && optional=true
  while true; do
    if $optional; then
      read -rp "$name (e.g. $example, empty if this host has no static LAN address): " value < /dev/tty
      break
    fi
    read -rp "$name (e.g. $example): " value < /dev/tty
    [ -n "$value" ] && break
    echo "$name is needed" >&2
  done
  updated="$(V="$value" yq -p toml -o toml ".${name} = strenv(V)" <<< "$updated")"
done < <(yq -p toml -o tsv '[.. | select(tag != "!!map") | [(path | join(".")), .]] | .[]' "$template")

[ "$updated" != "$current" ] || exit 0
sudo install -d -m 0700 -o root -g root "$dir"
printf '%s\n' "$updated" | sudo install -m 0600 -o root -g root /dev/stdin "$file"
echo "saved to $file" >&2
