#!/usr/bin/env bash
# vars.sh TEMPLATE DIR HOST: ask for values missing from DIR/vars.toml, save root-only.
# lan.* only on beacon (static IP), the rest use DHCP
set -euo pipefail
template="$1"
dir="$2"
host="$3"
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
  # DHCP hosts have no use for it
  [[ "$name" != lan.* || "$host" == beacon ]] || continue
  # set already
  if yq -p toml -e ".${name} != null" <<< "$current" > /dev/null 2>&1; then
    continue
  fi
  while true; do
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
