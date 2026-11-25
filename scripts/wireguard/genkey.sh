#!/usr/bin/env bash
# Make this host's wg0 private key (root-only) if missing, then print its public key.
set -euo pipefail

key=/var/secrets/wireguard/wg0.key
wg() { nix shell nixpkgs#wireguard-tools -c wg "$@"; }

if ! sudo test -s "$key"; then
  sudo install -d -m 0700 /var/secrets/wireguard
  wg genkey | sudo tee "$key" > /dev/null
  sudo chmod 0600 "$key"
fi

sudo cat "$key" | wg pubkey
