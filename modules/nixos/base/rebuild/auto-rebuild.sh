# auto-rebuild URL BRANCH CONFIG: switch to CONFIG from BRANCH's newest commit, once per commit.
# The last one switched to and the last one that failed are kept in $STATE_DIRECTORY, so a
# broken commit fails (and alerts) once, and the next push is tried again
set -euo pipefail
url="$1"
branch="$2"
config="$3"
done="$STATE_DIRECTORY/rev"
failed="$STATE_DIRECTORY/failed"

rev="$(git ls-remote "$url" "refs/heads/$branch" | cut -f1)"
if [ -z "$rev" ]; then
  # nothing pushed there yet: not an error, or it would alert every few minutes
  echo "no $branch branch at $url, nothing to do"
  exit 0
fi

if [ "$(cat "$done" 2>/dev/null)" = "$rev" ]; then
  echo "$branch is at $rev, already switched to"
  exit 0
fi
if [ "$(cat "$failed" 2>/dev/null)" = "$rev" ]; then
  echo "$branch is at $rev, which failed; waiting for the next push"
  exit 0
fi

echo "$branch moved to $rev, switching"
if nixos-rebuild switch --flake "git+$url?ref=$branch&rev=$rev#$config"; then
  printf '%s\n' "$rev" > "$done"
  rm -f "$failed"
else
  printf '%s\n' "$rev" > "$failed"
  exit 1
fi
