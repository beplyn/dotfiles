#!/usr/bin/env bash
# secrets.sh SPEC: for each "<namespace> <secret> <key>..." line, fill in the keys that Secret
# lacks; ones already there are left alone so values never rotate under the apps.
# A key is KEY (random hex), KEY=ntfy-token, or KEY=bcrypt:OTHER (hash of an earlier key)
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

generate() {
  case "$1" in
    "")
      openssl rand -hex 32 | tr -d '\n'
      ;;
    # tk_ and 29 more, what ntfy accepts
    ntfy-token)
      local s
      s="$(head -c 1000 /dev/urandom | tr -dc 'a-z0-9')"
      printf 'tk_%s' "${s:0:29}"
      ;;
    # ntfy wants cost 10 or more
    bcrypt:*)
      mkpasswd -m bcrypt -R 10 -s < "$tmp/${1#bcrypt:}" | tr -d '\n'
      ;;
    *)
      echo "unknown secret kind: $1" >&2
      exit 1
      ;;
  esac
}

while read -r ns name specs; do
  [ -n "$ns" ] || continue
  rm -f "$tmp"/*
  # the app's manifest may not have made it yet
  kubectl get namespace "$ns" >/dev/null 2>&1 || kubectl create namespace "$ns"

  exists=0
  have=" "
  if kubectl -n "$ns" get secret "$name" >/dev/null 2>&1; then
    exists=1
    # shellcheck disable=SC2016 # a go template, not shell
    have=" $(kubectl -n "$ns" get secret "$name" -o go-template='{{range $k, $v := .data}}{{$k}} {{end}}')"
  fi

  data=""
  for spec in $specs; do
    key="${spec%%=*}"
    kind=""
    [ "$spec" = "$key" ] || kind="${spec#*=}"
    if [[ "$have" == *" $key "* ]]; then
      # a later bcrypt: may hash it
      kubectl -n "$ns" get secret "$name" -o "jsonpath={.data.$key}" | base64 -d > "$tmp/$key"
      continue
    fi
    generate "$kind" > "$tmp/$key"
    data+="${data:+,}\"$key\":\"$(base64 -w0 < "$tmp/$key")\""
  done
  [ -n "$data" ] || continue

  [ "$exists" = 1 ] || kubectl -n "$ns" create secret generic "$name"
  printf '{"data":{%s}}' "$data" > "$tmp/patch.json"
  kubectl -n "$ns" patch secret "$name" --type merge --patch-file "$tmp/patch.json"
done < "$1"
