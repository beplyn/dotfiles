#!/usr/bin/env bash
# backup.sh MOUNT TARGET STATE PGSPEC KEEP: a consistent copy of the app state and the cluster
# itself into TARGET/current, then a read-only dated snapshot of it, keeping the newest KEEP.
# Live sqlite files go through .backup and postgres through pg_dumpall, never a raw copy.
# PGSPEC lines: "<namespace> <deployment> <user>"
set -euo pipefail
mount="$1"
target="$2"
state="$3"
pgspec="$4"
keep="$5"
k3s_dir="${K3S_DIR:-/var/lib/rancher/k3s}"

# unmounted, this would land on the system SSD
mountpoint -q "$mount" || { echo "$mount is not mounted" >&2; exit 1; }

mkdir -p "$target"
cur="$target/current"
[ -d "$cur" ] || btrfs subvolume create "$cur"
mkdir -p "$cur/apps" "$cur/postgres" "$cur/k3s"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# sqlite by its header, whatever the file is called
find "$state" -name postgres -prune -o -type f -size +0 -print0 \
  | while IFS= read -r -d '' f; do
    if [ "$(head -c 15 "$f" | tr -d '\0')" = "SQLite format 3" ]; then
      printf '%s\0' "${f#"$state"/}"
    fi
  done > "$tmp/dbs"
tr '\0' '\n' < "$tmp/dbs" | sed 's|^|/|' > "$tmp/exclude"

# everything else as is; the dbs, their journals and postgres' raw files are skipped
rsync -a --delete \
  --exclude-from="$tmp/exclude" \
  --exclude='*-wal' --exclude='*-shm' --exclude='*-journal' \
  --exclude='postgres/' \
  "$state/" "$cur/apps/"

while IFS= read -r -d '' rel; do
  mkdir -p "$(dirname "$cur/apps/$rel")"
  sqlite3 -readonly -cmd '.timeout 30000' "$state/$rel" ".backup '$cur/apps/$rel'"
done < "$tmp/dbs"

while read -r ns deploy user; do
  [ -n "$ns" ] || continue
  k3s kubectl -n "$ns" exec "deploy/$deploy" -- pg_dumpall -U "$user" --clean --if-exists \
    | zstd -q -T0 > "$tmp/$ns.sql.zst"
  mv "$tmp/$ns.sql.zst" "$cur/postgres/$ns.sql.zst"
done < "$pgspec"

# the cluster: every object and Secret (the sealed-secrets key too), and its join token
sqlite3 -readonly -cmd '.timeout 30000' "$k3s_dir/server/db/state.db" ".backup '$cur/k3s/state.db'"
cp "$k3s_dir/server/token" "$cur/k3s/token"
k3s kubectl get secrets -A -o yaml > "$cur/k3s/secrets.yaml"
# local-path volumes, if anything ever asks for one
if [ -d "$k3s_dir/storage" ]; then
  rsync -a --delete "$k3s_dir/storage/" "$cur/k3s/storage/"
fi

snap="$target/$(date +%F)"
[ ! -d "$snap" ] || btrfs subvolume delete "$snap"
btrfs subvolume snapshot -r "$cur" "$snap"

# dated names sort by age
find "$target" -mindepth 1 -maxdepth 1 -name '????-??-??' | sort | head -n "-$keep" \
  | while read -r old; do
    btrfs subvolume delete "$old"
  done
