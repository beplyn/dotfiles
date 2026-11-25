#!/usr/bin/env bash
# Store a host's wg0 public key in the root-only vars file: peer.sh <host> <pubkey>
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: $0 <beacon|anvil|shulker> <pubkey>" >&2
  exit 2
fi
host=$1
key=$2

case "$host" in
  beacon | anvil | shulker) ;;
  *) echo "unknown host: $host" >&2; exit 2 ;;
esac
# a wireguard key is 32 bytes, base64: 43 characters and '='
if [[ ! "$key" =~ ^[A-Za-z0-9+/]{43}=$ ]]; then
  echo "not a wireguard public key" >&2
  exit 2
fi

file=/var/secrets/dotfiles/vars.toml
current=$(sudo cat "$file")
updated=$(V="$key" nix shell nixpkgs#yq-go -c yq -p toml -o toml ".wireguard.${host} = strenv(V)" <<< "$current")
printf '%s\n' "$updated" | sudo tee "$file" > /dev/null
echo "stored $host"
