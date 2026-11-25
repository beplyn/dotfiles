dir=@dir@
install -d -m 0755 "$dir"
install -m 0644 @themeFile@ "$dir/theme.yml"

# the profile is already switched when activation scripts run
gen_of() { basename "$1" | sed -E 's/^system-([0-9]+)-link$/\1/'; }
fmt() { date -d "@$1" '+%Y-%m-%d %H:%M'; }

link=$(readlink /nix/var/nix/profiles/system)
gen=$(gen_of "$link")
last_rebuild=$(fmt "$(stat -c %Y "/nix/var/nix/profiles/$link")")

history=$(for l in /nix/var/nix/profiles/system-*-link; do
  printf '%s\t%s\n' "$(gen_of "$l")" "$(fmt "$(stat -c %Y "$l")")"
done | sort -rn | head -n 5 | jq -Rs \
  'split("\n") | map(select(length > 0) | split("\t") | {generation: (.[0] | tonumber), built: .[1]})')

# auto-rebuild never touches /etc/nixos, so prefer its recorded rev
repo=/etc/nixos
rev_file=/var/lib/auto-rebuild/rev
if [ -s "$rev_file" ]; then
  full_rev=$(tr -d '[:space:]' < "$rev_file")
  commit=$(printf '%s' "$full_rev" | cut -c1-7)
  message=$(git -c safe.directory='*' -C "$repo" log -1 --format=%s "$full_rev" 2>/dev/null || echo "auto-rebuild")
else
  commit=$(git -c safe.directory='*' -C "$repo" rev-parse --short HEAD 2>/dev/null || echo unknown)
  message=$(git -c safe.directory='*' -C "$repo" log -1 --format=%s 2>/dev/null || echo unknown)
fi

pull_file=/var/lib/auto-rebuild/last-pull
if [ -s "$pull_file" ]; then
  pull_ts=$(tr -d '[:space:]' < "$pull_file")
  last_pull=$(fmt "$pull_ts" 2>/dev/null || echo unknown)
elif [ -e "$repo/.git/FETCH_HEAD" ]; then
  last_pull=$(fmt "$(stat -c %Y "$repo/.git/FETCH_HEAD")")
else
  last_pull="never"
fi

jq -n \
  --argjson generation "${gen:-0}" \
  --arg built "$last_rebuild" \
  --arg last_rebuild "$last_rebuild" \
  --arg last_pull "$last_pull" \
  --arg commit "$commit" \
  --arg message "$message" \
  --arg release "@release@" \
  --arg kernel "$(uname -r)" \
  --arg theme "@theme@" \
  --argjson history "$history" \
  '{generation: $generation, built: $built, last_rebuild: $last_rebuild, last_pull: $last_pull,
    commit: $commit, message: $message, release: $release, kernel: $kernel,
    theme: $theme, history: $history}' \
  > "$dir/rebuild-stats.json.tmp"
chmod 0644 "$dir/rebuild-stats.json.tmp"
mv "$dir/rebuild-stats.json.tmp" "$dir/rebuild-stats.json"
