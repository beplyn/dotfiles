# auto-rebuild URL BRANCH CONFIG VARS: switch to BRANCH's newest commit, once per commit.
# Remembers the last good and failed commit, so a broken one alerts only once
set -euo pipefail
url="$1"
branch="$2"
config="$3"
vars="$4"
done="$STATE_DIRECTORY/rev"
failed="$STATE_DIRECTORY/failed"
last_pull="$STATE_DIRECTORY/last-pull"

record_pull() {
  local tmp="$STATE_DIRECTORY/.last-pull.tmp"
  date +%s > "$tmp"
  mv -f "$tmp" "$last_pull"
}

rev="$(git ls-remote "$url" "refs/heads/$branch" | cut -f1)"
if [ -z "$rev" ]; then
  # nothing pushed there yet: not an error, or it would alert every few minutes
  echo "no $branch branch at $url, nothing to do"
  exit 0
fi

if [ "$(cat "$done" 2>/dev/null)" = "$rev" ]; then
  record_pull
  echo "$branch is at $rev, already switched to"
  exit 0
fi
if [ "$(cat "$failed" 2>/dev/null)" = "$rev" ]; then
  record_pull
  echo "$branch is at $rev, which failed; waiting for the next push"
  exit 0
fi

# without them it would build the placeholders (example.com and all)
if [ ! -f "$vars/vars.toml" ]; then
  echo "no $vars/vars.toml: run rebuild once to set the values" >&2
  exit 1
fi

echo "$branch moved to $rev, switching"
if nixos-rebuild switch --flake "git+$url?ref=$branch&rev=$rev#$config" --override-input vars "path:$vars"; then
  printf '%s\n' "$rev" > "$done"
  record_pull
  rm -f "$failed"
else
  printf '%s\n' "$rev" > "$failed"
  record_pull
  exit 1
fi
