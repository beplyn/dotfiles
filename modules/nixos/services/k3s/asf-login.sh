#!/usr/bin/env bash
# asf-login: one-off interactive Steam login (Steam Guard code or Y), on beacon.
# Stops asf, runs ASF in a terminal sharing its state, restores asf on exit.
set -euo pipefail

kubectl() { k3s kubectl "$@"; }

ns=asf
# must match the image and uid in manifests/asf.yaml
image=justarchi/archisteamfarm:6.3.11.7
uid=3000
state=/srv/apps/asf

# restore the deployment however this exits
restore() { kubectl -n "$ns" scale deploy/asf --replicas=1 >/dev/null; }
trap restore EXIT

kubectl -n "$ns" scale deploy/asf --replicas=0
kubectl -n "$ns" wait --for=delete pod -l app=asf --timeout=120s >/dev/null || true

# seed farm.json from the secret as the deployment does, then start ASF with a tty
overrides=$(cat <<EOF
{
  "spec": {
    "securityContext": { "runAsUser": $uid, "runAsGroup": $uid },
    "initContainers": [{
      "name": "seed",
      "image": "$image",
      "command": ["/bin/sh", "-ec", "if [ -f /bot/farm.json ]; then cp /bot/farm.json /app/config/farm.json; fi"],
      "volumeMounts": [
        { "name": "config", "mountPath": "/app/config" },
        { "name": "bot", "mountPath": "/bot", "readOnly": true }
      ]
    }],
    "containers": [{
      "name": "asf-login",
      "image": "$image",
      "stdin": true,
      "tty": true,
      "volumeMounts": [
        { "name": "config", "mountPath": "/app/config" },
        { "name": "logs", "mountPath": "/app/logs" },
        { "name": "tmp", "mountPath": "/tmp" }
      ]
    }],
    "volumes": [
      { "name": "config", "hostPath": { "path": "$state", "type": "Directory" } },
      { "name": "bot", "secret": { "secretName": "asf-bot", "optional": true } },
      { "name": "logs", "emptyDir": {} },
      { "name": "tmp", "emptyDir": {} }
    ]
  }
}
EOF
)

kubectl -n "$ns" run asf-login -it --rm --restart=Never --image="$image" --overrides="$overrides"
