#!/usr/bin/env bash
# secrets.sh SPEC: for each "<namespace> <secret> <key>..." line, create that Secret with
# random hex values, once; existing ones are left alone so values never rotate under the apps
set -euo pipefail

kubectl() { k3s kubectl "$@"; }

# the API server takes a while after k3s starts
for _ in $(seq 60); do
  kubectl get --raw /readyz >/dev/null 2>&1 && break
  sleep 5
done
kubectl get --raw /readyz >/dev/null

# values go through files, never argv where ps can see them
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

while read -r ns name keys; do
  [ -n "$ns" ] || continue
  kubectl -n "$ns" get secret "$name" >/dev/null 2>&1 && continue
  # the app's manifest may not have made it yet
  kubectl get namespace "$ns" >/dev/null 2>&1 || kubectl create namespace "$ns"

  args=()
  for key in $keys; do
    openssl rand -hex 32 | tr -d '\n' > "$tmp/$key"
    args+=("--from-file=$key=$tmp/$key")
  done
  kubectl -n "$ns" create secret generic "$name" "${args[@]}"
  rm -f "$tmp"/*
done < "$1"
