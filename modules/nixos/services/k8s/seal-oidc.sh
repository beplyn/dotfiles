#!/usr/bin/env bash
# sudo seal-oidc APP > modules/nixos/services/k8s/oidc/APP.sealed.yaml
# asks for the client ID and secret Pocket ID shows for APP and seals them as the APP-oidc
# Secret against this cluster's controller; git add the file and the app picks it up
set -euo pipefail
app="${1:?usage: sudo seal-oidc <app> > modules/nixos/services/k8s/oidc/<app>.sealed.yaml}"

# sudo drops KUBECONFIG
export KUBECONFIG="${KUBECONFIG:-/etc/rancher/k3s/k3s.yaml}"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# prompts on the terminal, so stdout is only the manifest
read -rp "$app client ID: " id < /dev/tty
read -rsp "$app client secret: " secret < /dev/tty
echo >&2
printf '%s' "$id" > "$tmp/CLIENT_ID"
printf '%s' "$secret" > "$tmp/CLIENT_SECRET"

k3s kubectl -n "$app" create secret generic "$app-oidc" \
  --from-file="$tmp/CLIENT_ID" \
  --from-file="$tmp/CLIENT_SECRET" \
  --dry-run=client -o yaml \
  | kubeseal --format yaml
